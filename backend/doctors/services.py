from .models import Doctor, DoctorSchedule
from .serializers import DoctorSerializer, DoctorScheduleSerializer
from users.serializers import UserSerializer
from django.db import IntegrityError, DatabaseError
from datetime import date
from django.db import transaction

class DoctorService:
    @staticmethod
    def createDoctor(validated_data):
        try:
            doctor = Doctor.objects.create(**validated_data)
            return {'data': {'success': True, 'message': 'Doctor created', 'id': doctor.id}, 'status': 201}

        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def getDoctorById(doctor_id):
        try:
            doctor = Doctor.objects.select_related('user', 'speciality').get(id=doctor_id)
        except Doctor.DoesNotExist:
            return {'data': {'success': False, 'message': 'Doctor not found'}, 'status': 404}    
        
        if(doctor.is_doctor_verified == False):
            return {'data': {'success': False, 'message': 'Doctor not found'}, 'status': 404}

        try:
            today = date.today()
            birth_date = doctor.user.birth_date
            if birth_date:
                age = today.year - birth_date.year
                if (today.month, today.day) < (birth_date.month, birth_date.day):
                    age -= 1
            else:
                age = None

            data = {
                'first_name': doctor.user.first_name,
                'last_name': doctor.user.last_name,
                'email': doctor.user.email,
                'birth_date': doctor.user.birth_date,
                'age' : age,
                'phone': doctor.user.phone,
                'gender': doctor.user.gender,
                'speciality': doctor.speciality.name if doctor.speciality else None,
                'ville': doctor.ville,
                'address': doctor.address,
                'experience': doctor.experience,
                'consultation_price': doctor.consultation_price,
                'bio': doctor.bio,
                'is_available': doctor.is_available,
            }
            return {'data': {'success': True, 'doctor': data}, 'status': 200}
        
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def updateDoctor(doctor_id, data):
        try:
            doctor = Doctor.objects.select_related('user').get(pk=doctor_id)
        except Doctor.DoesNotExist:
            return {'data': {'success': False, 'message': 'Doctor not found'}, 'status': 404}

        try:
            doctor_serializer = DoctorSerializer(doctor, data=data, partial=True)
            if not doctor_serializer.is_valid():
                return {'data': {'success': False, 'message': doctor_serializer.errors}, 'status': 400}
            doctor_serializer.save()

            user_serializer = UserSerializer(doctor.user, data=data, partial=True)
            if not user_serializer.is_valid():
                return {'data': {'success': False, 'message': user_serializer.errors}, 'status': 400}
            user_serializer.save()

            return {'data': {'success': True, 'message': 'Doctor updated successfully'}, 'status': 200}

        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def getAllDoctors():
        try:
            doctors = Doctor.objects.select_related('user', 'speciality').all()
            data = []
            today = date.today()
            for doctor in doctors:
                birth_date = doctor.user.birth_date
                if birth_date:
                    age = today.year - birth_date.year
                    if (today.month, today.day) < (birth_date.month, birth_date.day):
                        age -= 1
                else:
                    age = None

                data.append({
                    'id': doctor.id,
                    'first_name': doctor.user.first_name,
                    'last_name': doctor.user.last_name,
                    'email': doctor.user.email,
                    'birth_date': doctor.user.birth_date,
                    'age' : age,
                    'phone': doctor.user.phone,
                    'gender': doctor.user.gender,
                    'speciality': doctor.speciality.name if doctor.speciality else None,
                    'ville': doctor.ville,
                    'address': doctor.address,
                    'experience': doctor.experience,
                    'consultation_price': doctor.consultation_price,
                    'bio': doctor.bio,
                })
            return {'data': {'success': True, 'doctors': data}, 'status': 200}
        
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def addDoctorSchedule(data):
        try:   
            with transaction.atomic():         
                DoctorSchedule.objects.filter(doctor=data[0]['doctor']).delete()
                schedules = [DoctorSchedule(**item) for item in data]
                DoctorSchedule.objects.bulk_create(schedules)

                return {'data': {'success': True, 'message': 'Doctor schedule added successfully'}, 'status': 201}

        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def getDoctorSchedule(doctor_id):
        try:
            doctor = Doctor.objects.get(pk=doctor_id)
        except Doctor.DoesNotExist:
            return {'data': {'success': False, 'message': 'Doctor not found'}, 'status': 404}

        try:
            schedules = DoctorSchedule.objects.filter(doctor=doctor)
            data = []
            for schedule in schedules:
                data.append({
                    'id': schedule.id,
                    'day_of_week': schedule.day_of_week,
                    'start_time': schedule.start_time,
                    'end_time': schedule.end_time,
                    'pause_start_time': schedule.pause_start_time,
                    'pause_end_time': schedule.pause_end_time,
                    'is_available': schedule.is_available,
                })
            return {'data': {'success': True, 'schedules': data}, 'status': 200}
        
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}



        