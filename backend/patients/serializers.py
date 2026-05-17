from rest_framework import serializers
from patients.models import Patient, MenstrualCycle, PeriodEntry
from Pregnancies.serializers import PregnancySerializer
from users.serializers import UserSerializer


class MenstrualCycleSerializer(serializers.ModelSerializer):
    class Meta:
        model = MenstrualCycle
        exclude = ['patient']

class PeriodEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = PeriodEntry
        exclude = ['menstrual_cycle']

class PatientSerializer(serializers.ModelSerializer):
    menstrual_cycle = MenstrualCycleSerializer(read_only=False, required=False)
    pregnancies = PregnancySerializer(many=True, read_only=True, required=False)
    user = UserSerializer(read_only=True, required=False)
    email = serializers.EmailField(write_only=True)

    class Meta:
        model = Patient
        fields = '__all__'
        extra_kwargs = {
            'user': {'read_only': True}
        }