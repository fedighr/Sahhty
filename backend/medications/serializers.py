from rest_framework import serializers
from Pregnancies.models import Pregnancy
from Pregnancies.serializers import PregnancySerializer
from .models import Medication, Treatment

class MedicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medication 
        fields = '__all__'

class TreatmentSerializer(serializers.ModelSerializer):
    medication = MedicationSerializer(read_only=True)
    medication_id = serializers.PrimaryKeyRelatedField(
        queryset = Medication.objects.all(),
        source = 'medication',
        write_only = True
    )
    pregnancy = PregnancySerializer(read_only=True)
    pregnancy_id = serializers.PrimaryKeyRelatedField(
        queryset = Pregnancy.objects.all(),
        source = 'pregnancy',
        write_only = True
    )      

    class Meta:
        model = Treatment
        fields = '__all__'  