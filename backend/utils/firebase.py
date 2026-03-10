import os
import firebase_admin
from firebase_admin import credentials, messaging
from users.models import FCMDevice

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

if not firebase_admin._apps:
    cred = credentials.Certificate(os.path.join(BASE_DIR, 'firebase_credentials.json'))
    firebase_admin.initialize_app(cred)


def send_push_notification(token, title, body, data=None):
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=token,
        )
        messaging.send(message)
        return True
    except messaging.UnregisteredError:
        FCMDevice.objects.filter(fcm_token=token).delete()
        return False
    except Exception as e:
        return False


def send_push_notification_to_user(user, title, body, data=None):

    devices = FCMDevice.objects.filter(user=user)
    for device in devices:
        send_push_notification(device.fcm_token, title, body, data)