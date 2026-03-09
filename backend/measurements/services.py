from ml_engine.predictor import predict_risk
from .models import Measurement, RiskAssessment
from django.db import IntegrityError, DatabaseError
from datetime import date
from alerts.services import AlertService

class MeasurementService:
    @staticmethod
    def createMesurement(measurements):    
        try:
            Measurement.objects.create(**measurements)

            weight = Measurement.objects.filter(type='WEIGHT', pregnancy=measurements['pregnancy']).latest('measurement_date').value1
            if(weight is None):
                weight = measurements['pregnancy'].patient.weight
            glucose = Measurement.objects.filter(type='GLYCEMIA', pregnancy=measurements['pregnancy']).latest('measurement_date').value1
            bp = Measurement.objects.filter(type='BLOOD_PRESSURE',pregnancy=measurements['pregnancy'],value2__isnull=False).latest('measurement_date')
            bp_sys = bp.value1
            bp_dia = bp.value2
            heart_rate = Measurement.objects.filter(type='HEART_RATE', pregnancy=measurements['pregnancy']).order_by('-measurement_date').first()
            if heart_rate:
                heart_rate = heart_rate.value1    
            birth_date = measurements['pregnancy'].patient.user.birth_date
            today = date.today()
            age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
            bmi = round(float(weight) / ((measurements['pregnancy'].patient.height / 100) ** 2), 2)
            pregnancy_week = (date.today() - measurements['pregnancy'].start_date).days // 7

            risk_data = {
                'age': age,
                'bmi': bmi,
                'glucose': glucose,
                'blood_pressure_sys': bp_sys,
                'blood_pressure_dia': bp_dia,
                'pregnancy_week': pregnancy_week,
                'heart_rate': heart_rate
            }

            #print("Risk data for prediction:", risk_data)
            risk_level, risk_percentage, new_heart_rate = predict_risk(risk_data)
            print(f"Predicted risk level: {risk_level}, risk percentage: {risk_percentage}")
            note = MeasurementService.generate_risk_note(glucose, bp_sys, bp_dia, new_heart_rate, bmi)
            RiskAssessment.objects.create(pregnancy=measurements['pregnancy'],global_risk_level=risk_level,global_risk_percentage=risk_percentage,personal_risk_level=risk_level,personal_risk_note=note, glucose_used=glucose, bp_sys_used=bp_sys, bp_dia_used=bp_dia, heart_rate_used=new_heart_rate, weight_used=weight)
            print(measurements['pregnancy'].patient.user.email)
            if(risk_level == "HIGH"):
                AlertService.sendRiskAlert(measurements['pregnancy'].patient.user.email, f"High risk detected for pregnancy {measurements['pregnancy'].id} with risk percentage {risk_percentage}%. Note: {note}", "CRITICAL")
            elif(risk_level == "MEDIUM"):
                AlertService.sendRiskAlert(measurements['pregnancy'].patient.user.email, f"Medium risk detected for pregnancy {measurements['pregnancy'].id} with risk percentage {risk_percentage}%. Note: {note}", "WARNING")    
            return {'data': {'success': True, 'risk_level': risk_level, 'risk_percentage': risk_percentage, 'message': 'Measurement created and risk assessed'},'status': 200 }
        
        except Measurement.DoesNotExist:
            return {'data': {'success': True, 'risk_level': None, 'risk_percentage': None, 'message': 'Measurement created'},'status': 200 }

        except IntegrityError:
            return {'data': {'success': False, 'message': 'Invalid data or constraint violated'},'status': 400 }

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'},'status': 500 }

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def generate_risk_note(glucose, bp_sys, bp_dia, heart_rate, bmi):
        notes = []
        if glucose > 140:
            notes.append("high glucose")
        if bp_sys > 140 or bp_dia > 90:
            notes.append("high blood pressure")
        if heart_rate > 100:
            notes.append("high heart rate")
        if bmi > 30:
            notes.append("high BMI")

        if not notes:
            return "All values within normal range"
        
        return f"Detected: {', '.join(notes)}"        



