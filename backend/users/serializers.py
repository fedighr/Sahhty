from rest_framework import serializers
from .models import FCMDevice, User
import re

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()

class EmailSerializer(serializers.Serializer):
    email = serializers.EmailField()

class PhoneSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)

    def validate_phone(self, value):
        if not re.match(r'^\+?\d{8,15}$', value):
            raise serializers.ValidationError("Invalid phone number format.")
        return value

class FCMDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = FCMDevice
        fields = ['fcm_token']        