from .models import Doctor, DoctorSchedule, Speciality
from appointments.models import Appointment
from appointments.serializers import AppointmentSerializer
from .serializers import DoctorSerializer, DoctorScheduleSerializer
from users.serializers import UserSerializer
from django.db import IntegrityError, DatabaseError
from datetime import datetime, timedelta, date
from django.db import transaction
from rest_framework.pagination import PageNumberPagination
from django.utils import timezone
from math import radians, sin, cos, asin, sqrt

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
    def getAllDoctors(request, speciality_filter=None, ville_filter=None, gender_filter=None, latitude=None, longitude=None):
        try:
            doctors = Doctor.objects.select_related('user', 'speciality').all()

            if speciality_filter:
                doctors = doctors.filter(speciality__name__icontains=speciality_filter)

            if ville_filter:
                doctors = doctors.filter(ville__iexact=ville_filter)

            if gender_filter:
                doctors = doctors.filter(user__gender__iexact=gender_filter)

            if latitude and longitude:
                doctors = doctors.filter(
                    latitude__isnull=False,
                    longitude__isnull=False
                )

            today = date.today()
            data = []
            for doctor in doctors:
                birth_date = doctor.user.birth_date
                if birth_date:
                    age = today.year - birth_date.year
                    if (today.month, today.day) < (birth_date.month, birth_date.day):
                        age -= 1
                else:
                    age = None

                doctor_data = {
                    'id': doctor.id,
                    'first_name': doctor.user.first_name,
                    'last_name': doctor.user.last_name,
                    'email': doctor.user.email,
                    'birth_date': doctor.user.birth_date,
                    'age': age,
                    'phone': doctor.user.phone,
                    'gender': doctor.user.gender,
                    'speciality': doctor.speciality.name if doctor.speciality else None,
                    'ville': doctor.ville,
                    'address': doctor.address,
                    'experience': doctor.experience,
                    'consultation_price': doctor.consultation_price,
                    'bio': doctor.bio,
                    'latitude': doctor.latitude,
                    'longitude': doctor.longitude,
                    'distance_km': None,
                }

                if latitude and longitude and doctor.latitude and doctor.longitude:
                    try:
                        lat1, lon1 = float(latitude), float(longitude)
                        lat2, lon2 = float(doctor.latitude), float(doctor.longitude)

                        dlat = radians(lat2 - lat1)
                        dlon = radians(lon2 - lon1)
                        a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2)**2
                        distance = 6371 * 2 * asin(sqrt(a))

                        doctor_data['distance_km'] = round(distance, 2)
                    except (ValueError, TypeError):
                        pass

                data.append(doctor_data)

            if latitude and longitude:
                data.sort(key=lambda x: x['distance_km'] if x['distance_km'] is not None else float('inf'))

            paginator = PageNumberPagination()
            result = paginator.paginate_queryset(data, request)
            return {'data': paginator.get_paginated_response(result).data, 'status': 200}

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
        
    @staticmethod
    def getDoctorAvailableSlots(doctor_id, day, date):
        try:
            doctor = Doctor.objects.get(pk=doctor_id)
        except Doctor.DoesNotExist:
            return {'data': {'success': False, 'message': 'Doctor not found'}, 'status': 404}

        try:
            schedules = DoctorSchedule.objects.get(doctor=doctor, day_of_week=day.upper(), is_available=True)
            print(schedules)
            consultation_duration = doctor.consultation_duration
            if not consultation_duration:
                consultation_duration = 30

            data = get_available_slots(schedules.start_time, schedules.end_time, schedules.pause_start_time, schedules.pause_end_time, consultation_duration, date, doctor_id)
            return {'data': {'success': True, 'available_slots': data}, 'status': 200}
        
        except DoctorSchedule.DoesNotExist:
            return {'data': {'success': False, 'message': 'No schedule found for the specified day'}, 'status': 404}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def getAllSpecialities():
        try:
            specialities = Speciality.objects.all()
            data = [{'id': speciality.id, 'name': speciality.name} for speciality in specialities]
            return {'data': {'success': True, 'specialities': data}, 'status': 200}
        
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

def get_available_slots(start_time, end_time, pause_start_time, pause_end_time, consultation_duration, today_date, doctor_id):
    slots = []
    today = datetime.strptime(today_date, '%Y-%m-%d').date()
    current_time = timezone.make_aware(datetime.combine(today, start_time))
    end_datetime = timezone.make_aware(datetime.combine(today, end_time))
    
    while current_time + timedelta(minutes=consultation_duration) <= end_datetime:
        if not (pause_start_time and pause_end_time and (pause_start_time <= current_time.time() < pause_end_time or pause_start_time < (current_time + timedelta(minutes=consultation_duration)).time() <= pause_end_time)):
            slots.append(current_time.strftime('%H:%M'))
        else:
            current_time = timezone.make_aware(datetime.combine(today, pause_end_time))
            continue
        current_time += timedelta(minutes=consultation_duration)

    doctor_today_appointments = Appointment.objects.filter(doctor_id=doctor_id, appointment_date__date=today, status__in=['PENDING', 'CONFIRMED'])
    booked_slots = set(appointment.appointment_date.astimezone().strftime('%H:%M') for appointment in doctor_today_appointments)
    slots = [slot for slot in slots if slot not in booked_slots]

    return slots
