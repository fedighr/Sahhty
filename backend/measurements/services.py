from django.db.models.functions import TruncDate
from ml_engine.predictor import predict_risk
from .models import Measurement, RiskAssessment
from .serializers import MeasurementSerializer, RiskAssessmentSerializer
from patients.models import Patient
from Pregnancies.models import Pregnancy
from django.db import IntegrityError, DatabaseError, transaction
from datetime import date
from alerts.services import AlertService

class MeasurementService:
    @staticmethod
    def createMeasurement(measurements):
        try:
            patient = measurements['patient']
            Measurement.objects.create(**measurements)

            with transaction.atomic():

                weight_obj = Measurement.objects.filter(patient=patient, type='WEIGHT').latest('measurement_date')
                weight = weight_obj.value1 if weight_obj.value1 is not None else patient.weight

                glucose = Measurement.objects.filter(patient=patient, type='GLYCEMIA').latest('measurement_date').value1

                bp = Measurement.objects.filter(patient=patient, type='BLOOD_PRESSURE', value2__isnull=False).latest('measurement_date')
                bp_sys = bp.value1
                bp_dia = bp.value2

                heart_rate_obj = Measurement.objects.filter(patient=patient, type='HEART_RATE').order_by('-measurement_date').first()
                heart_rate = heart_rate_obj.value1 if heart_rate_obj else None
                body_temp_obj = Measurement.objects.filter(patient=patient, type='TEMPERATURE').order_by('-measurement_date').first()
                body_temp = body_temp_obj.value1 if body_temp_obj else None

                birth_date = patient.user.birth_date
                today = date.today()
                age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
                bmi = round(float(weight) / ((float(patient.height) / 100) ** 2), 2)

                pregnancy = Pregnancy.objects.filter(patient=patient, end_date__isnull=True).order_by('-start_date').first()
                pregnancy_week = (today - pregnancy.start_date).days // 7 if pregnancy else None

                risk_data = {
                    'Age': age,
                    'bmi': bmi,
                    'BS': glucose,
                    'SystolicBP': bp_sys,
                    'DiastolicBP': bp_dia,
                    'pregnancy_week': pregnancy_week,
                    'HeartRate': heart_rate,
                    'BodyTemp': body_temp,
                }

                risk_level, new_heart_rate = predict_risk(risk_data)
                note = MeasurementService.generate_risk_note(glucose, bp_sys, bp_dia, new_heart_rate, body_temp, risk_level)

                RiskAssessment.objects.create(
                    patient=patient,
                    global_risk_level=risk_level,
                    personal_risk_level=risk_level,
                    personal_risk_note=note,
                    glucose_used=glucose,
                    bp_sys_used=bp_sys,
                    bp_dia_used=bp_dia,
                    heart_rate_used=new_heart_rate,
                    weight_used=weight,
                    body_temp_used=body_temp,
                )

                if risk_level == 'HIGH':
                    AlertService.sendRiskAlert(patient.user.email,f"High risk detected for patient {patient.id}. Note: {note}",'CRITICAL')
                elif risk_level == 'MEDIUM':
                    AlertService.sendRiskAlert(patient.user.email,f"Medium risk detected for patient {patient.id}. Note: {note}",'WARNING')

                return {
                    'data': {
                        'success': True,
                        'risk_level': risk_level,
                        'note': note,
                        'value1' : measurements['value1'],   
                        'value2': measurements['value2'] if 'value2' in measurements else None,
                        'message': 'Measurement created and risk assessed',
                    },
                    'status': 200,
                }

        except Measurement.DoesNotExist:
            return {
                'data': {
                    'success': True,
                    'risk_level': None,
                    'risk_percentage': None,
                    'message': 'Measurement created',
                },
                'status': 200,
            }

        except IntegrityError:
            return {'data': {'success': False, 'message': 'Invalid data or constraint violated'}, 'status': 400}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def getLeastestMeasurements(patient_id):
        try:
            patient = Patient.objects.select_related('user').get(pk=patient_id)
        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}

        try:
            if not patient.height or not patient.weight:
                return {'data': {'success': False, 'message': 'Patient has incomplete information'}, 'status': 400}
            
            height = float(patient.height)
            weight_measurement = Measurement.objects.filter(patient=patient, type='WEIGHT').order_by('-measurement_date').values('value1', 'unit', 'context', 'measurement_date').first()
            weight = float(weight_measurement['value1']) if weight_measurement else float(patient.weight)
            bmi = round(weight / ((height / 100) ** 2), 2)


            glycemia = Measurement.objects.filter(patient=patient, type='GLYCEMIA').order_by('-measurement_date').values('value1', 'unit', 'context', 'measurement_date').first()

            blood_pressure = Measurement.objects.filter(patient=patient, type='BLOOD_PRESSURE', value2__isnull=False).order_by('-measurement_date').values('value1', 'value2', 'unit', 'context', 'measurement_date').first()

            heart_rate = Measurement.objects.filter(patient=patient, type='HEART_RATE').order_by('-measurement_date').values('value1', 'unit', 'context', 'measurement_date').first()

            body_temp = Measurement.objects.filter(patient=patient, type='TEMPERATURE').order_by('-measurement_date').values('value1', 'unit', 'context', 'measurement_date').first()

            pregnancy_week = None
            if patient.user.gender == 'F':
                pregnancy = Pregnancy.objects.filter(patient=patient, end_date__isnull=True).order_by('-start_date').first()
                if pregnancy and pregnancy.start_date:
                    pregnancy_week = (date.today() - pregnancy.start_date).days // 7

            data = {
                'success': True,
                'height': height,
                'weight': weight,
                'bmi': bmi,
                'glycemia_informations': glycemia,
                'blood_pressure': blood_pressure,
                'heart_rate': heart_rate,
                'body_temp': body_temp,
                'pregnancy_week': pregnancy_week,
            }

            return {'data': data, 'status': 200}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def getPatientMeasurements(pk):
        try:
            patient = Patient.objects.select_related('user').get(pk=pk)
        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}

        try:
            measurements = Measurement.objects.filter(patient=patient).order_by('-measurement_date')
            serializer = MeasurementSerializer(measurements, many=True)
            return {'data': {'success': True, 'measurements': serializer.data}, 'status': 200}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def getRiskAssessment(pk):
        try:
            patient = Patient.objects.select_related('user').get(pk=pk)
        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}

        try:
            risk_assessment = RiskAssessment.objects.filter(patient=patient).order_by('-assessed_at').first()
            if not risk_assessment:
                return {'data': {'success': False, 'message': 'No risk assessment found for this patient'}, 'status': 404}
            serializer = RiskAssessmentSerializer(risk_assessment)
            return {'data': {'success': True, 'risk_assessment': serializer.data}, 'status': 200}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}


    @staticmethod
    def generate_risk_note(glucose, bp_sys, bp_dia, heart_rate, body_temp, risk_level):
        notes = []

        if risk_level == 'HIGH':
            if glucose is not None and glucose > 180:
                notes.append(f"Glycémie critique ({glucose} mg/dL) — attention immédiate requise")
            if glucose is not None and glucose < 70:
                notes.append(f"Glycémie basse ({glucose} mg/dL) — risque d'hypoglycémie")
            if bp_sys is not None and bp_dia is not None and (bp_sys >= 140 or bp_dia >= 90):
                notes.append(f"Hypertension de stade 2 ({bp_sys}/{bp_dia} mmHg) — consultation médicale urgente requise")
            if bp_sys is not None and bp_dia is not None and (bp_sys < 90 or bp_dia < 60):
                notes.append(f"Tension artérielle basse ({bp_sys}/{bp_dia} mmHg) — risque d'hypotension")
            if heart_rate is not None and heart_rate > 130:
                notes.append(f"Fréquence cardiaque critique ({heart_rate} bpm) — attention immédiate requise")
            if heart_rate is not None and heart_rate < 60:
                notes.append(f"Fréquence cardiaque basse ({heart_rate} bpm) — bradycardie possible")
            if body_temp is not None and body_temp >= 39.5:
                notes.append(f"Température corporelle très élevée ({body_temp}°C) — risque d'hyperthermie")
            if body_temp is not None and body_temp < 35:
                notes.append(f"Température corporelle basse ({body_temp}°C) — risque d'hypothermie")

        elif risk_level == 'MEDIUM':
            if glucose is not None and 126 <= glucose <= 180:
                notes.append(f"Glycémie élevée ({glucose} mg/dL) — diabète possible")
            if glucose is not None and 100 <= glucose <= 125:
                notes.append(f"Glycémie pré-diabétique ({glucose} mg/dL) — surveiller de près")
            if bp_sys is not None and bp_dia is not None and (130 <= bp_sys <= 139 or 80 <= bp_dia <= 89):
                notes.append(f"Hypertension de stade 1 ({bp_sys}/{bp_dia} mmHg) — consultation médicale recommandée")
            if bp_sys is not None and bp_dia is not None and (bp_sys <= 129 and bp_dia < 80):
                notes.append(f"Tension artérielle élevée ({bp_sys}/{bp_dia} mmHg) — changements de mode de vie conseillés")
            if heart_rate is not None and 101 <= heart_rate <= 130:
                notes.append(f"Fréquence cardiaque élevée ({heart_rate} bpm) — tachycardie possible")
            if body_temp is not None and 38 <= body_temp < 39.5:
                notes.append(f"Fièvre détectée ({body_temp}°C) — consultation médicale recommandée")
            if body_temp is not None and 35 <= body_temp < 36:
                notes.append(f"Température corporelle légèrement basse ({body_temp}°C) — surveiller de près")

        elif risk_level == 'INFO':
            if glucose is not None and 70 <= glucose <= 99:
                notes.append(f"Glycémie à jeun normale ({glucose} mg/dL)")
            if bp_sys is not None and bp_dia is not None and bp_sys <= 120 and bp_dia <= 80:
                notes.append(f"Tension artérielle normale ({bp_sys}/{bp_dia} mmHg)")
            if heart_rate is not None and 60 <= heart_rate <= 100:
                notes.append(f"Fréquence cardiaque normale ({heart_rate} bpm)")
            if body_temp is not None and 36 <= body_temp < 38:
                notes.append(f"Température corporelle normale ({body_temp}°C)")

        if not notes:
            return "Aucun résultat significatif détecté"

        return " | ".join(notes)


