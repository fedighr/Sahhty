import logging
import os
import firebase_admin
from firebase_admin import credentials, messaging
from users.models import FCMDevice

logger = logging.getLogger(__name__)

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
        response = messaging.send(message)
        logger.info(f"Push notification sent successfully: {response}")
        return True
    except messaging.UnregisteredError:
        logger.warning(f"FCM token unregistered, deleting: {token}")
        FCMDevice.objects.filter(fcm_token=token).delete()
        return False
    except Exception as e:
        logger.error(f"Failed to send push notification to token {token}: {e}", exc_info=True)
        return False


def send_push_notification_to_user(user, title, body, data=None):
    devices = FCMDevice.objects.filter(user=user)
    if not devices.exists():
        logger.warning(f"No FCM devices found for user {user}")
        return
    for device in devices:
        send_push_notification(device.fcm_token, title, body, data)