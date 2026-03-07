from .models import Alert
from django.db import IntegrityError, DatabaseError
from datetime import date
from users.models import User
from utils.email_service import send_alert_email

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
        