from rest_framework import serializers
from .models import Doctor, Speciality
from users.serializers import UserSerializer
from users.models import User

class SpecialitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Speciality
        fields = '__all__'

class DoctorSerializer(serializers.ModelSerializer):
    speciality = SpecialitySerializer(read_only=True)
    speciality_id = serializers.PrimaryKeyRelatedField(
        queryset=Speciality.objects.all(),
        source='speciality',
        write_only=True
    )
    user = UserSerializer(read_only=True)
    user_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(),
        source='user',
        write_only=True
    )

    class Meta:
        model = Doctor
        fields = ['id', 'ville', 'address', 'experience', 'consultation_price', 'bio', 'is_available', 'user', 'user_id', 'speciality', 'speciality_id']