from users.models import User

class CheckConstraint:
    @staticmethod
    def is_email_used(email):
        return User.objects.filter(email=email).exists()
    
    @staticmethod
    def is_phone_used(phone):
        return User.objects.filter(phone=phone).exists()
    
    @staticmethod
    def is_verified(email):
        return User.objects.filter(email=email, is_verified=True).exists()

