from rest_framework import serializers
from patients.models import Patient, MenstrualCycle
from Pregnancies.serializers import PregnancySerializer


class MenstrualCycleSerializer(serializers.ModelSerializer):
    class Meta:
        model = MenstrualCycle
        exclude = ['patient']

class PatientSerializer(serializers.ModelSerializer):
    menstrual_cycle = MenstrualCycleSerializer(read_only=False, required=False)
    pregnancies = PregnancySerializer(many=True, read_only=True, required=False)
    email = serializers.EmailField(write_only=True)

    class Meta:
        model = Patient
        fields = '__all__'
        extra_kwargs = {
            'user': {'read_only': True}
        }