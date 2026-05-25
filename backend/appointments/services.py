from django.db import DatabaseError, IntegrityError

from drf_spectacular.types import date
from django.utils import timezone
from rest_framework.utils.timezone import datetime
from .models import Appointment
from .serializers import AppointmentSerializer
from alerts.models import Alert
from alerts.serializers import AlertSerializer
from patients.models import Patient
from doctors.models import Doctor
from django.db import transaction
from alerts.services import AlertService
from notifications.services import send_websocket_notification
from rest_framework.pagination import PageNumberPagination

class AppointmentService:
    @staticmethod
    def CreateAppointment(data):
        try:
            with transaction.atomic():
                doctor = data['doctor']
                patient = data['patient']

                if Appointment.objects.filter(doctor=doctor, appointment_date=data['appointment_date'], status__in=['PENDING', 'CONFIRMED']).exists():
                    return {'data': {'success': False, 'message': 'Doctor is not available at this time'}, 'status': 400}
                if Appointment.objects.filter(patient=patient, appointment_date=data['appointment_date'], status__in=['PENDING', 'CONFIRMED']).exists():
                    return {'data': {'success': False, 'message': 'Patient already has an appointment at this time'}, 'status': 400}

                appointment = Appointment.objects.create(**data)
                serializer = AppointmentSerializer(appointment)

                doctor_user = doctor.user
                patient_user = patient.user

                doctor_alert = Alert(
                    type='SYSTEM',
                    user=doctor_user,
                    message=f'Nouveau rendez-vous planifié avec le patient {patient_user.first_name} {patient_user.last_name} le {appointment.appointment_date.strftime("%d/%m/%Y à %H:%M")}. Veuillez confirmer le rendez-vous.',
                )
                patient_alert = Alert(
                    type='SYSTEM',
                    user=patient_user,
                    message=f'Nouveau rendez-vous planifié avec le docteur {doctor_user.first_name} {doctor_user.last_name} le {appointment.appointment_date.strftime("%d/%m/%Y à %H:%M")}. Veuillez attendre que le docteur confirme le rendez-vous.',
                )
                Alert.objects.bulk_create([doctor_alert, patient_alert])

                send_websocket_notification(
                    user_id=doctor_user.id,
                    event_type='appointment_request',
                    data={
                        'appointment_id': appointment.id,
                        'patient_name': f'{patient_user.first_name} {patient_user.last_name}',
                        'appointment_datetime': str(appointment.appointment_date),
                    },
                )


                return {'data': {'success': True, 'appointment': serializer.data}, 'status': 201}

        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
    
    @staticmethod
    def ConfirmAppointment(appointment_id):
        try:
            appointment = Appointment.objects.get(id=appointment_id)
            if appointment.status != 'PENDING':
                return {'data': {'success': False, 'message': 'Only pending appointments can be confirmed'}, 'status': 400}
            
            appointment.status = 'CONFIRMED'
            appointment.save()

            patient_user_id = appointment.patient.user
            patient_alert = Alert(
                type='SYSTEM',
                user=patient_user_id,
                message=f'Le rendez-vous avec le docteur {appointment.doctor.user.first_name} {appointment.doctor.user.last_name} le {appointment.appointment_date.strftime("%d/%m/%Y à %H:%M")} a été confirmé.',
            )
            patient_alert.save()

            serializer = AppointmentSerializer(appointment)
            return {'data': {'success': True, 'appointment': serializer.data}, 'status': 200}
        
        except Appointment.DoesNotExist:
            return {'data': {'success': False, 'message': 'Appointment not found'}, 'status': 404}
        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def CancelAppointment(appointment_id, cancelled_by):
        try:
            appointment = Appointment.objects.get(id=appointment_id)
            if appointment.status not in ['PENDING', 'CONFIRMED']:
                return {'data': {'success': False, 'message': 'Only pending or confirmed appointments can be cancelled'}, 'status': 400}
            
            appointment.status = 'CANCELLED'
            appointment.save()

            doctor_user_id = appointment.doctor.user
            patient_user_id = appointment.patient.user

            if cancelled_by.upper() == 'DOCTOR':
                patient_alert = Alert(
                    type='SYSTEM',
                    user=patient_user_id,
                    message=f'Rendez-vous avec le docteur {appointment.doctor.user.first_name} {appointment.doctor.user.last_name} le {appointment.appointment_date.strftime("%d/%m/%Y à %H:%M")} a été annulé par le docteur.',
                )
                patient_alert.save()
            elif cancelled_by.upper() == 'PATIENT':
                doctor_alert = Alert(
                    type='SYSTEM',
                    user=doctor_user_id,
                    message=f'Rendez-vous avec le patient {appointment.patient.user.first_name} {appointment.patient.user.last_name} le {appointment.appointment_date.strftime("%d/%m/%Y à %H:%M")} a été annulé par le patient.',
                )
                doctor_alert.save()
            else:
                return {'data': {'success': False, 'message': 'Cancelled by field must be either DOCTOR or PATIENT'}, 'status': 400}

            serializer = AppointmentSerializer(appointment)
            return {'data': {'success': True, 'appointment': serializer.data}, 'status': 200}
        
        except Appointment.DoesNotExist:
            return {'data': {'success': False, 'message': 'Appointment not found'}, 'status': 404}
        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def GetPatientTodayAppointments(patient_id):
        try:
            if not Patient.objects.filter(id=patient_id).exists():
                return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}
            
            now = timezone.now()
            appointments = Appointment.objects.filter(patient_id=patient_id, appointment_date__gte=now, status__in=['PENDING', 'CONFIRMED']).order_by('appointment_date')
            serializer = AppointmentSerializer(appointments, many=True)
            return {'data': {'success': True, 'appointments': serializer.data}, 'status': 200}
        
        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def GetDoctorTodayAppointments(doctor_id):
        try:
            if not Doctor.objects.filter(id=doctor_id).exists():
                return {'data': {'success': False, 'message': 'Doctor not found'}, 'status': 404}
            
            now = timezone.now()
            appointments = Appointment.objects.filter(doctor_id=doctor_id, appointment_date__gte=now, status__in=['PENDING', 'CONFIRMED']).order_by('appointment_date')
            serializer = AppointmentSerializer(appointments, many=True)
            return {'data': {'success': True, 'appointments': serializer.data}, 'status': 200}
        
        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def GetPatientAppointments(patient_id, request, status_filter=None, order='desc'):
        try:
            if not Patient.objects.filter(id=patient_id).exists():
                return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}

            appointments = Appointment.objects.filter(patient_id=patient_id)

            if status_filter:
                appointments = appointments.filter(status=status_filter)

            if order == 'asc':
                appointments = appointments.order_by('appointment_date')
            else:
                appointments = appointments.order_by('-appointment_date')

            paginator = PageNumberPagination()
            result = paginator.paginate_queryset(appointments, request)
            serializer = AppointmentSerializer(result, many=True)
            return {'data': paginator.get_paginated_response(serializer.data).data, 'status': 200}

        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}


    @staticmethod
    def GetDoctorAppointments(doctor_id, request, status_filter=None, order='desc'):
        try:
            if not Doctor.objects.filter(id=doctor_id).exists():
                return {'data': {'success': False, 'message': 'Doctor not found'}, 'status': 404}

            appointments = Appointment.objects.filter(doctor_id=doctor_id)

            if status_filter:
                appointments = appointments.filter(status=status_filter)

            if order == 'asc':
                appointments = appointments.order_by('appointment_date')
            else:
                appointments = appointments.order_by('-appointment_date')

            paginator = PageNumberPagination()
            result = paginator.paginate_queryset(appointments, request)
            serializer = AppointmentSerializer(result, many=True)
            return {'data': paginator.get_paginated_response(serializer.data).data, 'status': 200}

        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}