from .models import Doctor
from django.db import IntegrityError

class DoctorService:
    @staticmethod
    def createDoctor(validated_data):
        try:
            doctor = Doctor.objects.create(**validated_data)
            return {'data': {'success': True, 'message': 'Doctor created', 'id': doctor.id}, 'status': 201}
        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}