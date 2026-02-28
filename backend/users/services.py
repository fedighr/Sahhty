from rest_framework_simplejwt.tokens import RefreshToken
from utils.email_service import send_verification_email
from utils.otp_service import OTPService
from utils.constraints import CheckConstraint
from users.models import User

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
        
        if not user.check_password(password):
            return {'data': {'success': False, 'message': 'Invalid email or password'}, 'status': 400}
        
        if not user.is_verified:
            return {'data': {'success': False, 'message': 'Email not verified'}, 'status': 403}

        token = RefreshToken.for_user(user)    
        token['email'] = user.email
        token['name'] =user.first_name + " " + user.last_name
        return {
            'data': {
                'success': True,
                'access': str(token.access_token),
                'refresh': str(token)
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
            
            if not OTPService.is_expired(user.expiration_date):
                AuthService._send_otp(email)
                return {'data': {'success': False, 'message': 'Code expired, new code sent'}, 'status': 400}
            
            if code != user.verification_code:
                return {'data': {'success': False, 'message': 'Incorrect verification code'}, 'status': 400}
            
            user.is_verified = True
            user.save()
            return {'data': {'success': True, 'message': 'User verified successfully'}, 'status': 200}

        except User.DoesNotExist:
            return {'data': {'success': False, 'message': 'User not found'}, 'status': 404}


    @staticmethod
    def _send_otp(email):
        otp = OTPService.create_otp()
        result = send_verification_email(email, otp['code'], otp['expires_at'])
        if result:
            user = User.objects.get(email=email)
            user.verification_code = otp['code']
            user.expiration_date = otp['expires_at']
            user.save()
            return {'data': {'success': True, 'message': 'Code sent successfully'}, 'status': 200}
        return {'data': {'success': False, 'message': 'Email not sent'}, 'status': 500}      