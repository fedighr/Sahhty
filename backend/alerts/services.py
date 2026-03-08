from .models import Alert
from django.db import IntegrityError, DatabaseError
from django.utils import timezone
from users.models import User
from datetime import timedelta, datetime
from medications.models import Treatment, TreatmentSchedule, Medication
from utils.email_service import send_alert_email, send_medication_reminder_email

class AlertService:
    @staticmethod
    def createAlert(email, alert_message, alert_level):    
        try:
            #Alert.objects.create(**alert_data)
            result = send_alert_email(email, alert_message, alert_level)
            if result:
                return {'data': {'success': True, 'message': 'Alert created successfully'},'status': 200 }
            
            return {'data': {'success': False, 'message': 'Alert not created'}, 'status': 500} 
        
        except IntegrityError:
            return {'data': {'success': False, 'message': 'Invalid data or constraint violated'},'status': 400 }

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'},'status': 500 }

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def createMedicationReminder():
        try:
            #Alert.objects.create(**alert_data)
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
                                schedule.last_sent_at = now
                                schedule.save(update_fields=['last_sent_at'])
                    break

            return {'data': {'success': True, 'message': 'Medication reminders processed successfully'},'status': 200 }
        
        except IntegrityError:
            return {'data': {'success': False, 'message': 'Invalid data or constraint violated'},'status': 400 }

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'},'status': 500 }

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}    