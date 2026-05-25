from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from utils.email_service import send_appointment_notification_email, send_access_request_email
from utils.firebase import send_push_notification_to_user
import threading

def send_websocket_notification(user_id, event_type, data):
    channel_layer = get_channel_layer()
    group_name = f'notifications_{user_id}'

    async_to_sync(channel_layer.group_send)(
        group_name,
        {
            'type': 'send_notification',
            'data': {
                'type': event_type,
                'data': data,
            }
        }
    )


def send_email_async(email_func, **kwargs):
    thread = threading.Thread(target=email_func, kwargs=kwargs)
    thread.daemon = True
    thread.start()

def notify_user(user_id, event_type, data, fcm_token=None, email=None):
    send_websocket_notification(user_id, event_type, data)

    if fcm_token:
        if event_type == 'appointment_request':
            title = 'Nouvelle Demande de Rendez-vous'
            body = f"Le patient {data['patient_name']} a demandé un rendez-vous"
        elif event_type == 'access_request':
            title = 'Demande d\'Accès Médecin'
            body = f"Dr. {data['doctor_name']} ({data['specialty']}) a demandé l'accès à vos données de santé"
        else:
            title = 'Notification'
            body = 'Vous avez une nouvelle notification'

        send_push_notification_to_user(
            user=user_id,
            title=title,
            body=body,
        )
"""
    if email:
        if event_type == 'appointment_request':
            threading.Thread(
                target=send_appointment_notification_email,
                kwargs={
                    'doctor_email': email,
                    'patient_name': data['patient_name'],
                    'appointment_datetime': data['appointment_datetime'],
                }
            ).start()
        elif event_type == 'access_request':
            threading.Thread(
                target=send_access_request_email,
                kwargs={
                    'patient_email': email,
                    'doctor_name': data['doctor_name'],
                    'specialty': data['specialty'],
                    'request_date': data['request_date'],
                }
            ).start()"""