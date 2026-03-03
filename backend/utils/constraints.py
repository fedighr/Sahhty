from users.models import User
from rest_framework.permissions import BasePermission

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

class IsOwnerOrAdmin(BasePermission):
    def has_object_permission(self, request, view, obj):
        return request.user == obj or request.user.is_staff
