from utils.email_service import send_verification_email
from utils.otp_service import OTPService
from utils.constraints import CheckConstraint
from .models import Patient, MenstrualCycle
from users.models import User

class PatientService:

    @staticmethod
    def createPatient(data):
        try:
            data = dict(data)
            
            email = data.pop('email', None)
            menstrual_cycle_data = data.pop('menstrual_cycle', None)

            user = User.objects.filter(email=email).first()
            if not user:
                return {'data': {'success': False, 'message': 'User not found'}, 'status': 404}
            
            if hasattr(user, 'patient'):
                return {'data': {'success': False, 'message': 'Patient already exists'}, 'status': 400}

            patient = Patient.objects.create(user=user, **data)

            if menstrual_cycle_data and user.gender == 'F':
                MenstrualCycle.objects.create(patient=patient, **menstrual_cycle_data)

            return {'data': {'success': True, 'message': 'Patient created successfully'}, 'status': 201}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        

        