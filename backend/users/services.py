from rest_framework_simplejwt.tokens import RefreshToken
from utils.email_service import send_verification_email, send_lockout_email
from utils.otp_service import OTPService
from utils.constraints import CheckConstraint
from .models import User
from patients.models import Patient
from doctors.models import Doctor
from django.utils import timezone
from datetime import timedelta

class AuthService:
    @staticmethod
    def register(data):
        email = data.get('email')
        phone = data.get('phone')

        if CheckConstraint.is_phone_used(phone):
            return {'data': {'success': False, 'message': 'Phone number already used'}, 'status': 400}

        if CheckConstraint.is_email_used(email):
            if CheckConstraint.is_verified(email):
                return {'data': {'success': False, 'message': 'Email already used'}, 'status': 400}
        else:
            User.objects.create_user(**data)

        return AuthService._send_otp(email)

    @staticmethod
    def login(data):
        email = data.get('email')
        password = data.get('password')

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return {'data': {'success': False, 'message': 'Invalid email or password'}, 'status': 400}

        if user.lockout_until and user.lockout_until > timezone.now():
            return {'data': {'success': False, 'message': 'Account locked due to suspicious activity, try again in 15 minutes'}, 'status': 403}

        if not user.check_password(password):
            user.failed_login_attempts += 1
            if user.failed_login_attempts >= 5:
                user.lockout_until = timezone.now() + timedelta(minutes=15)
                user.failed_login_attempts = 0
                user.save()
                send_lockout_email(user.email)
                return {'data': {'success': False, 'message': 'Account locked due to suspicious activity, try again in 15 minutes'}, 'status': 403}
            user.save()
            return {'data': {'success': False, 'message': 'Invalid email or password'}, 'status': 400}

        if not user.is_verified:
            return {'data': {'success': False, 'message': 'Email not verified'}, 'status': 403}

        user.failed_login_attempts = 0
        user.lockout_until = None
        user.save()

        if user.two_factor_enabled == False:
            role_model_map = {
                'P': Patient,
                'D': Doctor,
            }

            model = role_model_map.get(user.role)
            if model and not model.objects.filter(user=user).exists():
                return {
                    'data': {'success': False, 'message': 'User does not complete his signup'},
                    'status': 403
                }

            token = RefreshToken.for_user(user)
            token['email'] = user.email
            token['name'] = user.first_name + " " + user.last_name
            token['gender'] = user.gender
            token['role'] = user.role
            if user.role == 'P':
                patient_id = Patient.objects.get(user=user).id
                token['patient_id'] = patient_id
            elif user.role == 'D':
                doctor_id = Doctor.objects.get(user=user).id
                token['doctor_id'] = doctor_id

            return {
                'data': {
                    'success': True,
                    'access': str(token.access_token),
                    'refresh': str(token),
                    'requires_2fa': user.two_factor_enabled
                },
                'status': 200
            }

        elif user.two_factor_enabled == True:
            otp = OTPService.create_otp()
            user.two_factor_code = otp['code']
            user.two_factor_expiration = otp['expires_at']
            user.save()
            send_verification_email(user.email, otp['code'], otp['expires_at'])
            return {
                'data': {
                    'success': True,
                    'message': '2FA code sent to email',
                    'requires_2fa': user.two_factor_enabled
                },
                'status': 200
            }
        
    @staticmethod
    def verify_2fa(data):
        email = data.get('email')
        code = data.get('code')

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return {'data': {'success': False, 'message': 'Invalid email or code'}, 'status': 400}

        if user.lockout_until and user.lockout_until > timezone.now():
            return {'data': {'success': False, 'message': 'Account locked due to suspicious activity, try again in 15 minutes'}, 'status': 403}

        if OTPService.is_expired(user.two_factor_expiration):
            return {'data': {'success': False, 'message': '2FA code expired'}, 'status': 400}

        if code != user.two_factor_code:
            user.failed_login_attempts += 1
            if user.failed_login_attempts >= 5:
                user.lockout_until = timezone.now() + timedelta(minutes=15)
                user.failed_login_attempts = 0
                user.two_factor_code = None
                user.two_factor_expiration = None
                user.save()
                send_lockout_email(user.email)
                return {'data': {'success': False, 'message': 'Account locked due to suspicious activity, try again in 15 minutes'}, 'status': 403}
            user.save()
            return {'data': {'success': False, 'message': 'Invalid 2FA code'}, 'status': 400}

        token = RefreshToken.for_user(user)
        token['email'] = user.email
        token['name'] = user.first_name + " " + user.last_name
        token['gender'] = user.gender
        token['role'] = user.role
        if user.role == 'P':
            patient_id = Patient.objects.get(user=user).id
            token['patient_id'] = patient_id
        elif user.role == 'D':
            doctor_id = Doctor.objects.get(user=user).id
            token['doctor_id'] = doctor_id

        user.two_factor_code = None
        user.two_factor_expiration = None
        user.failed_login_attempts = 0
        user.lockout_until = None
        user.save()

        return {
            'data': {
                'success': True,
                'access': str(token.access_token),
                'refresh': str(token),
            },
            'status': 200
        }
        
    @staticmethod
    def resendCode(email):
        if CheckConstraint.is_email_used(email):
            return AuthService._send_otp(email)     
        else:
            return {'data' : {'success' : False, 'message' : 'User not found'}, 'status' : 404}
        
    @staticmethod
    def verifyCode(email, code):
        try:
            user = User.objects.get(email=email)
            
            if OTPService.is_expired(user.expiration_date):
                AuthService._send_otp(email)
                return {'data': {'success': False, 'message': 'Code expired, new code sent'}, 'status': 400}
            
            if code != user.verification_code:
                return {'data': {'success': False, 'message': 'Incorrect verification code'}, 'status': 400}
            
            user.is_verified = True
            user.verification_code = None
            user.expiration_date = None
            user.save()
            return {'data': {'success': True, 'message': 'User verified successfully'}, 'status': 200}

        except User.DoesNotExist:
            return {'data': {'success': False, 'message': 'User not found'}, 'status': 404}

    @staticmethod
    def verifyResetCode(email, code):
        try:
            user = User.objects.get(email=email)
            
            if OTPService.is_expired(user.expiration_date):
                return {'data': {'success': False, 'message': 'Code expired, new code sent'}, 'status': 400}
            
            if code != user.verification_code:
                return {'data': {'success': False, 'message': 'Incorrect verification code'}, 'status': 400}
            
            user.can_reset_password = True
            user.verification_code = None
            user.expiration_date = None
            user.save()
            return {'data': {'success': True, 'message': 'User verified successfully'}, 'status': 200}

        except User.DoesNotExist:
            return {'data': {'success': False, 'message': 'User not found'}, 'status': 404}    

    @staticmethod
    def verifyEmailAvailable(email):
        if CheckConstraint.is_email_used(email):
            return {'data' : {'success' : False, 'message' : 'Error, this email is already used!'}, 'status' : 400}
        return {'data' : {'success' : True, 'message' : 'Email is available'}, 'status' : 200}
    
    @staticmethod
    def verifyResetEmail(email):
        if not CheckConstraint.is_email_used(email):
            return {'data' : {'success' : False, 'message' : 'Error, this email does not exist!'}, 'status' : 400}
        AuthService._send_otp(email)
        return {'data' : {'success' : True, 'message' : 'Email exists, verification code sent'}, 'status' : 200}
    
    @staticmethod
    def verifyPhone(phone):
        if CheckConstraint.is_phone_used(phone):
            return {'data' : {'success' : False, 'message' : 'Error, this phone number is already used!'}, 'status' : 400}
        return {'data' : {'success' : True, 'message' : 'Phone number is available'}, 'status' : 200}

    @staticmethod
    def forgetPassword(data):
        email = data.get('email')
        try:
            user = User.objects.get(email=email)
            if not user.can_reset_password:
                return {'data': {'success': False, 'message': 'Error, you did not verify your email.'}, 'status': 400}   
                    
            user.set_password(data.get('password'))
            user.can_reset_password =False
            user.save()

        except User.DoesNotExist:
            return {'data': {'success': False, 'message': 'Invalid email or password'}, 'status': 400}
        
        return {'data' : {'success' : True, 'message' : 'Password updated'}, 'status' : 200}

    @staticmethod
    def delete_user_account(user):
        if user.is_deleted:
            return  {'data':{"success": False,"message": "Account already deleted"}, 'status' : 400}

        user.is_deleted = True
        user.email = user.email + ".deleted"
        user.phone = user.phone + ".deleted"
        user.save()

        return {'data':{"success": True,"message": "Account deleted successfully"}, 'status' : 200   }

    @staticmethod
    def _send_otp(email):
        otp = OTPService.create_otp()
        result = send_verification_email(email, otp['code'], otp['expires_at'])
        if result:
            user = User.objects.get(email=email)
            user.verification_code = otp['code']
            user.expiration_date = otp['expires_at']
            user.save()
            return {'data': {'success': True, 'message': 'Code sent successfully', 'user_id': user.id}, 'status': 200}
        return {'data': {'success': False, 'message': 'Email not sent'}, 'status': 500}    

    
      