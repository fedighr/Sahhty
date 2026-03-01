from rest_framework import serializers
from .models import Patient, MenstrualCycle

class MenstrualCycleSerializer(serializers.ModelSerializer):
    class Meta:
        model = MenstrualCycle
        exclude = ['patient']

class PatientSerializer(serializers.ModelSerializer):
    menstrual_cycle = MenstrualCycleSerializer(required=False)
    email = serializers.EmailField(write_only=True)

    class Meta: 
        model = Patient
        fields = '__all__'
        extra_kwargs = {
            'user': {'read_only': True}
        }