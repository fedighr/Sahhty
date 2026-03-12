from .serializers import AlertSerializer
from .models import Alert
from django.db import IntegrityError, DatabaseError
from django.utils import timezone
from users.models import User
from measurements.models import Measurement
from appointments.models import Appointment
from patients.models import Patient
from datetime import timedelta, datetime
from Pregnancies.models import Pregnancy
from medications.models import Treatment, TreatmentSchedule, Medication
from utils.email_service import send_alert_email, send_medication_reminder_email, send_appointment_reminder_email, send_missing_measurement_email, send_unconfirmed_appointment_email, send_pregnancy_no_appointment_email
from utils.firebase import send_push_notification_to_user


"""add this to every service after abdelhedi complete frontend alerts
    send_push_notification_to_user(
        user=patient.user,
        title="Appointment Reminder",
        body=f"You have an appointment tomorrow at {appointment_date}",
    )
"""

class AlertService:
    @staticmethod
    def sendRiskAlert(email, alert_message, alert_level):    
        try:
            
            user = User.objects.get(email=email)
            result = send_alert_email(email, alert_message, alert_level)
            if result:
                Alert.objects.create(type='HEALTH', message=alert_message, level=alert_level, status='NEW', user=user)
            return {'data': {'success': True, 'message': 'Alert sent successfully'}, 'status': 200}

        except User.DoesNotExist:
            return {'data': {'success': False, 'message': 'User not found'}, 'status': 404}

        except IntegrityError:
            return {'data': {'success': False, 'message': 'Invalid data or constraint violated'},'status': 400 }

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'},'status': 500 }

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def createMedicationReminder():
        try:
            now = timezone.localtime(timezone.now())
            treatments = Treatment.objects.filter(start_date__lte=now.date(), end_date__gte=now.date()).select_related('medication', 'patient').prefetch_related('schedules')
            
            for treatment in treatments:
                for schedule in treatment.schedules.all():
                    dose_datetime = datetime.combine(now.date(), schedule.dose_time, tzinfo=now.tzinfo)
                    if dose_datetime - timedelta(hours=1) <= now <= dose_datetime:
                        if schedule.last_sent_at is None or schedule.last_sent_at.date() < now.date():
                            medication_name = treatment.medication.name
                            patient_email = treatment.patient.user.email
                            patient_name = treatment.patient.user.first_name + " " + treatment.patient.user.last_name
                            time = schedule.dose_time.strftime("%H:%M")
                            result = send_medication_reminder_email(patient_email, medication_name, patient_name, time)
                            if result:
                                Alert.objects.create(type='REMINDER', message=f"Medication reminder: Take {medication_name} at {time}", level='INFO', status='NEW', user=User.objects.get(email=patient_email))
                                schedule.last_sent_at = now
                                schedule.save(update_fields=['last_sent_at'])

                    break  # Only check the next upcoming dose for each treatment
            return {'data': {'success': True, 'message': 'Medication reminders processed successfully'}, 'status': 200}
        
        except IntegrityError:
            return {'data': {'success': False, 'message': 'Invalid data or constraint violated'},'status': 400 }

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'},'status': 500 }

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}    

    @staticmethod
    def createAppointmentReminder():
        try:
            now = timezone.localtime(timezone.now())
            tomorrow = now + timedelta(days=1)
            appointments = Appointment.objects.filter(status='CONFIRMED', appointment_date__date=tomorrow.date(), is_reminder_sent=False).select_related('patient__user', 'doctor__user')

            for appointment in appointments:
                patient_email = appointment.patient.user.email
                patient_name = appointment.patient.user.first_name + " " + appointment.patient.user.last_name
                doctor_name = appointment.doctor.user.first_name + " " + appointment.doctor.user.last_name
                appointment_time = appointment.appointment_date.strftime("%Y-%m-%d %H:%M")
                result = send_appointment_reminder_email(patient_email, patient_name, doctor_name, appointment_time)
                if result:
                    print('aaaa')
                    Alert.objects.create(type='REMINDER', message=f"Appointment reminder: You have an appointment with Dr. {doctor_name} on {appointment_time}", level='INFO', status='NEW', user=appointment.patient.user)
                    appointment.is_reminder_sent = True
                    appointment.save(update_fields=['is_reminder_sent'])
                    send_push_notification_to_user(
                        user=appointment.patient.user,
                        title="Appointment Reminder",
                        body=f"You have an appointment tomorrow at {appointment_time}",
                    )

            return {'data': {'success': True, 'message': 'Appointment reminders processed successfully'}, 'status': 200}

        except IntegrityError:
            return {'data': {'success': False, 'message': 'Invalid data or constraint violated'}, 'status': 400}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def sendMissingMeasurementsAlert():
        measurement_types = ['BLOOD_PRESSURE', 'WEIGHT', 'GLYCEMIA']
        now = timezone.localtime(timezone.now())
        patients = Patient.objects.filter(user__gender="F").select_related('user')
        try:
            for patient in patients:
                missing_measurements = []
                for measurement_type in measurement_types:
                    last_measurement = Measurement.objects.filter(patient=patient, type=measurement_type).order_by('-measurement_date').first()
                    if last_measurement is None or (now - last_measurement.measurement_date).days > 7:
                        missing_measurements.append(measurement_type)

                if missing_measurements !=[]:
                    patient_email = patient.user.email
                    patient_name = patient.user.first_name + " " + patient.user.last_name
                    missing_measurements_str = ", ".join(missing_measurements)
                    result = send_missing_measurement_email(patient_email, patient_name, missing_measurements_str)
                    if result:
                        Alert.objects.create(type='SYSTEM', message=f"Missing measurements alert: You have not recorded {missing_measurements_str} measurements in the last 7 days. Please update your measurements.", level='WARNING', status='NEW', user=User.objects.get(email=patient_email))

            return {'data': {'success': True, 'message': 'Missing measurements alerts processed successfully'}, 'status': 200}

        except IntegrityError:
            return {'data': {'success': False, 'message': 'Invalid data or constraint violated'}, 'status': 400}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
    @staticmethod
    def sendUnconfirmedAppointmentAlert():
        try:
            now = timezone.localtime(timezone.now())
            tomorrow = now + timedelta(days=1)
            unconfirmed_appointments = Appointment.objects.filter(status='PENDING', appointment_date__date=tomorrow.date()).select_related('patient__user', 'doctor__user')
            for appointment in unconfirmed_appointments:
                patient_email = appointment.patient.user.email
                patient_name = appointment.patient.user.first_name + " " + appointment.patient.user.last_name
                doctor_name = appointment.doctor.user.first_name + " " + appointment.doctor.user.last_name
                doctor_email = appointment.doctor.user.email
                appointment_time = appointment.appointment_date.strftime("%Y-%m-%d %H:%M")
                result = send_unconfirmed_appointment_email(patient_email, patient_name, doctor_name, doctor_email, appointment_time)
                if result:
                    Alert.objects.create(type='SYSTEM', message=f"Unconfirmed appointment alert: You have a pending appointment with Dr. {doctor_name} on {appointment_time}. Please confirm or reschedule.", level='WARNING', status='NEW', user=User.objects.get(email=patient_email))

            return {'data': {'success': True, 'message': 'Unconfirmed appointment alerts processed successfully'}, 'status': 200}

        except IntegrityError:
            return {'data': {'success': False, 'message': 'Invalid data or constraint violated'}, 'status': 400}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def sendPregnancyNoAppointmentAlert():
        try:
            now = timezone.localtime(timezone.now())
            pregnancies = Pregnancy.objects.filter(end_date__isnull=True, test_result=True).select_related('patient__user')
            for pregnancy in pregnancies:
                last_appointment = Appointment.objects.filter(patient=pregnancy.patient).exclude(status='CANCELLED').order_by('-appointment_date').first()
                if last_appointment is None or (now - last_appointment.appointment_date).days > 14:
                    patient_email = pregnancy.patient.user.email
                    patient_name = pregnancy.patient.user.first_name + " " + pregnancy.patient.user.last_name
                    result = send_pregnancy_no_appointment_email(patient_email, patient_name)
                    if result:
                        Alert.objects.create(type='SYSTEM', message=f"No appointment alert: You have not had an appointment in the last 14 days for pregnancy {pregnancy.id}. Please schedule an appointment.", level='WARNING', status='NEW', user=User.objects.get(email=patient_email))

            return {'data': {'success': True, 'message': 'Pregnancy no-appointment alerts processed successfully'}, 'status': 200}

        except IntegrityError:
            return {'data': {'success': False, 'message': 'Invalid data or constraint violated'}, 'status': 400}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def getAlertsByUser(user_id):
        try:
            user = User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return {'data': {'success': False, 'message': 'User not found'}, 'status': 404}
        
        try:
            alerts = Alert.objects.filter(user=user).order_by('-created_at')
            serializer = AlertSerializer(alerts, many=True)
            return {'data': {'success': True, 'alerts': serializer.data}, 'status': 200}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def markAlertAsRead(alert_id):
        try:
            alert = Alert.objects.get(pk=alert_id)
        except Alert.DoesNotExist:
            return {'data': {'success': False, 'message': 'Alert not found'}, 'status': 404}
        
        try:
            alert.status = 'READ'
            alert.save(update_fields=['status'])
            return {'data': {'success': True, 'message': 'Alert marked as read successfully'}, 'status': 200}
        
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}