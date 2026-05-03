from rest_framework import serializers
from .models import Doctor, Speciality, DoctorSchedule
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
        fields = ['id', 'ville', 'address', 'experience', 'consultation_price', 'bio', 'is_doctor_verified', 'user', 'user_id', 'speciality', 'speciality_id']

class DoctorScheduleSerializer(serializers.ModelSerializer):
    def validate(self, data):
        start_time = data.get('start_time')
        end_time = data.get('end_time')
        pause_start_time = data.get('pause_start_time')
        pause_end_time = data.get('pause_end_time')

        if start_time and end_time and start_time >= end_time:
            raise serializers.ValidationError("Start time must be before end time.")
        
        if pause_start_time and pause_end_time:
            if pause_start_time >= pause_end_time:
                raise serializers.ValidationError("Pause start time must be before pause end time.")
            if not (start_time < pause_start_time < pause_end_time < end_time):
                raise serializers.ValidationError("Pause times must be within the working hours.")
        
        return data
    
    doctor = DoctorSerializer(read_only=True)
    doctor_id = serializers.PrimaryKeyRelatedField(
        queryset=Doctor.objects.all(),
        source='doctor',
        write_only=True
    )

    def run_validators(self, value):
        pass

    class Meta:
        model = DoctorSchedule
        fields = ['id', 'day_of_week', 'start_time', 'end_time', 'pause_start_time', 'pause_end_time', 'is_available', 'doctor', 'doctor_id']
        validators = []