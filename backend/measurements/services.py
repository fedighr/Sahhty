from django.db.models.functions import TruncDate
from ml_engine.predictor import predict_risk
from .models import Measurement, RiskAssessment
from .serializers import MeasurementSerializer, RiskAssessmentSerializer
from patients.models import Patient
from Pregnancies.models import Pregnancy
from django.db import IntegrityError, DatabaseError, transaction
from datetime import date
from alerts.services import AlertService
from rest_framework.pagination import PageNumberPagination
#from ml_engine.isolation_forest import predict_personal_risk, get_final_risk
from datetime import datetime, timezone

class MeasurementService:
    @staticmethod
    def createMeasurement(measurements):
        try:
            patient = measurements['patient']

            with transaction.atomic():
                Measurement.objects.create(**measurements)

                weight_obj = Measurement.objects.filter(patient=patient, type='WEIGHT').order_by('-measurement_date').first()
                weight = weight_obj.value1 if weight_obj and weight_obj.value1 is not None else patient.weight

                glucose_obj = Measurement.objects.filter(patient=patient, type='GLYCEMIA').order_by('-measurement_date').first()
                glucose = glucose_obj.value1 if glucose_obj else None

                bp = Measurement.objects.filter(patient=patient, type='BLOOD_PRESSURE', value2__isnull=False).order_by('-measurement_date').first()
                bp_sys = bp.value1 if bp else None
                bp_dia = bp.value2 if bp else None

                if glucose is None or bp_sys is None or bp_dia is None:
                    return {
                        'data': {
                            'success': True,
                            'risk_level': None,
                            'risk_percentage': None,
                            'message': 'Measurement created, insufficient data for risk assessment',
                        },
                        'status': 200,
                    }

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

                total_assessments = RiskAssessment.objects.filter(patient=patient).count()
                """
                personal_risk_level = predict_personal_risk(
                    patient_id=patient.id,
                    measurements={
                        'SystolicBP': bp_sys,
                        'DiastolicBP': bp_dia,
                        'BS': glucose,
                        'BodyTemp': body_temp,
                        'HeartRate': heart_rate,
                    },
                    birth_date=birth_date,
                    assessed_at=datetime.now(timezone.utc),
                    pregnancy_week=pregnancy_week,
                    total_assessments=total_assessments,
                )
                """
                #final_risk_level = get_final_risk(risk_level, personal_risk_level)
                final_risk_level = risk_level

                note = MeasurementService.generate_risk_note(glucose, bp_sys, bp_dia, new_heart_rate, body_temp, final_risk_level)

                RiskAssessment.objects.create(
                    patient=patient,
                    global_risk_level=risk_level,
                    #personal_risk_level=personal_risk_level,
                    personal_risk_level=None,
                    personal_risk_note=note,
                    final_risk_level=final_risk_level,
                    glucose_used=glucose,
                    bp_sys_used=bp_sys,
                    bp_dia_used=bp_dia,
                    heart_rate_used=new_heart_rate,
                    weight_used=weight,
                    body_temp_used=body_temp,
                )

                if final_risk_level == 'HIGH':
                    AlertService.sendRiskAlert(patient.user.email, f"High risk detected for patient {patient.id}. Note: {note}", 'CRITICAL')
                elif final_risk_level == 'MEDIUM':
                    AlertService.sendRiskAlert(patient.user.email, f"Medium risk detected for patient {patient.id}. Note: {note}", 'WARNING')

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
    def getPatientMeasurements(pk, request, type_filter=None, order='desc'):
        try:
            patient = Patient.objects.select_related('user').get(pk=pk)
        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}

        try:
            measurements = Measurement.objects.filter(patient=patient)

            if type_filter:
                measurements = measurements.filter(type=type_filter)

            if order == 'asc':
                measurements = measurements.order_by('measurement_date')
            else:
                measurements = measurements.order_by('-measurement_date')

            paginator = PageNumberPagination()
            result = paginator.paginate_queryset(measurements, request)
            serializer = MeasurementSerializer(result, many=True)
            return {'data': paginator.get_paginated_response(serializer.data).data, 'status': 200}

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
        combinations = []

        def add(note, priority=0):
            notes.append((priority, note))

        if heart_rate is not None and bp_sys is not None and bp_dia is not None:
            if heart_rate > 100 and (bp_sys >= 140 or bp_dia >= 90):
                combinations.append("Tachycardie et hypertension détectées simultanément")

        if body_temp is not None and heart_rate is not None:
            if body_temp >= 38.0 and heart_rate > 100:
                combinations.append("Fièvre et tachycardie détectées simultanément")

        if glucose is not None and bp_sys is not None and bp_dia is not None:
            if glucose > 1.40 and (bp_sys >= 140 or bp_dia >= 90):
                combinations.append("Glycémie élevée et hypertension détectées simultanément")

        if glucose is not None and body_temp is not None:
            if glucose > 1.40 and body_temp >= 38.0:
                combinations.append("Glycémie élevée et fièvre détectées simultanément")

        if risk_level == 'HIGH':

            if glucose is not None:
                if glucose >= 3.42:
                    add(f"Glycémie dangereusement élevée ({glucose} g/L)", 3)
                elif glucose > 1.40:
                    add(f"Glycémie très élevée ({glucose} g/L)", 2)
                elif glucose < 0.59:
                    add(f"Glycémie dangereusement basse ({glucose} g/L)", 3)
                elif glucose < 0.70:
                    add(f"Glycémie basse ({glucose} g/L)", 2)

            if bp_sys is not None and bp_dia is not None:
                if bp_sys >= 160 or bp_dia >= 110:
                    add(f"Tension artérielle dangereusement élevée ({bp_sys}/{bp_dia} mmHg)", 3)
                elif bp_sys >= 140 or bp_dia >= 90:
                    add(f"Tension artérielle très élevée ({bp_sys}/{bp_dia} mmHg)", 2)
                elif bp_sys < 70 or bp_dia < 49:
                    add(f"Tension artérielle dangereusement basse ({bp_sys}/{bp_dia} mmHg)", 3)
                elif bp_sys < 80 or bp_dia < 50:
                    add(f"Tension artérielle basse ({bp_sys}/{bp_dia} mmHg)", 2)

            if heart_rate is not None:
                if heart_rate >= 120:
                    add(f"Fréquence cardiaque dangereusement élevée ({heart_rate} bpm)", 3)
                elif heart_rate > 100:
                    add(f"Fréquence cardiaque élevée ({heart_rate} bpm)", 2)
                elif heart_rate < 40:
                    add(f"Fréquence cardiaque dangereusement basse ({heart_rate} bpm)", 3)
                elif heart_rate < 60:
                    add(f"Fréquence cardiaque basse ({heart_rate} bpm)", 2)

            if body_temp is not None:
                if body_temp >= 40.0:
                    add(f"Température corporelle dangereusement élevée ({body_temp}°C)", 3)
                elif body_temp >= 38.0:
                    add(f"Température corporelle élevée ({body_temp}°C)", 2)
                elif body_temp < 36.0:
                    add(f"Température corporelle dangereusement basse ({body_temp}°C)", 3)
                elif body_temp < 36.5:
                    add(f"Température corporelle basse ({body_temp}°C)", 2)

        elif risk_level == 'MEDIUM':

            if glucose is not None:
                if 0.92 <= glucose <= 1.40:
                    add(f"Glycémie légèrement élevée ({glucose} g/L) — seuil diabète gestationnel", 2)
                elif 0.59 <= glucose < 0.70:
                    add(f"Glycémie légèrement basse ({glucose} g/L)", 1)

            if bp_sys is not None and bp_dia is not None:
                if bp_sys >= 140 or bp_dia >= 90:
                    add(f"Tension artérielle élevée ({bp_sys}/{bp_dia} mmHg)", 2)
                elif 130 <= bp_sys <= 139 or 80 <= bp_dia <= 89:
                    add(f"Tension artérielle légèrement élevée ({bp_sys}/{bp_dia} mmHg)", 2)
                elif bp_sys < 80 or bp_dia < 50:
                    add(f"Tension artérielle légèrement basse ({bp_sys}/{bp_dia} mmHg)", 1)

            if heart_rate is not None:
                if 100 < heart_rate < 120:
                    add(f"Fréquence cardiaque légèrement élevée ({heart_rate} bpm)", 1)
                elif 40 <= heart_rate < 60:
                    add(f"Fréquence cardiaque légèrement basse ({heart_rate} bpm)", 1)

            if body_temp is not None:
                if 37.5 <= body_temp < 38.0:
                    add(f"Température corporelle légèrement élevée ({body_temp}°C)", 1)
                elif 38.0 <= body_temp < 40.0:
                    add(f"Température corporelle élevée ({body_temp}°C)", 2)
                elif 36.0 <= body_temp < 36.5:
                    add(f"Température corporelle légèrement basse ({body_temp}°C)", 1)

        elif risk_level in ('LOW', 'INFO'):

            if glucose is not None:
                if glucose > 1.40:
                    add(f"Glycémie légèrement élevée ({glucose} g/L)", 1)
                elif glucose < 0.70:
                    add(f"Glycémie légèrement basse ({glucose} g/L)", 1)

            if bp_sys is not None and bp_dia is not None:
                if bp_sys < 90 or bp_dia < 60:
                    add(f"Tension artérielle légèrement basse ({bp_sys}/{bp_dia} mmHg)", 1)
                elif bp_sys >= 130 or bp_dia >= 80:
                    add(f"Tension artérielle légèrement élevée ({bp_sys}/{bp_dia} mmHg)", 1)

            if heart_rate is not None:
                if heart_rate > 100:
                    add(f"Fréquence cardiaque légèrement élevée ({heart_rate} bpm)", 1)
                elif heart_rate < 60:
                    add(f"Fréquence cardiaque légèrement basse ({heart_rate} bpm)", 1)

            if body_temp is not None:
                if body_temp >= 37.5:
                    add(f"Température corporelle légèrement élevée ({body_temp}°C)", 1)
                elif body_temp < 36.5:
                    add(f"Température corporelle légèrement basse ({body_temp}°C)", 1)

        notes.sort(key=lambda x: x[0], reverse=True)
        final_notes = [n for _, n in notes]
        all_notes = combinations + final_notes

        if not all_notes:
            if risk_level == 'HIGH':
                return "Vos indicateurs de santé nécessitent une prise en charge médicale urgente"
            elif risk_level == 'MEDIUM':
                return "Certains indicateurs de santé nécessitent une surveillance. Consultez votre médecin prochainement"
            else:
                return "Tous vos indicateurs de santé sont dans les limites normales"

        return " | ".join(all_notes)

