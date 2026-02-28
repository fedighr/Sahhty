
import secrets
from django.utils import timezone   
from datetime import timedelta
class OTPService:
    EXPIRATION_SECONDS = 300

    @staticmethod
    def generate_code():

        return str(secrets.randbelow(1000000)).zfill(6)

    @staticmethod
    def create_otp():

        return {
            "code": OTPService.generate_code(),
            "expires_at": timezone.now() + timedelta(seconds=OTPService.EXPIRATION_SECONDS)
        }

    @staticmethod
    def is_expired(expires_at):

        return timezone.now() > expires_at
