from rest_framework import serializers
from patients.models import Patient
from patients.serializers import PatientSerializer
from .models import Medication, Treatment, TreatmentSchedule

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
    patient = PatientSerializer(read_only=True)
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset = Patient.objects.all(),
        source = 'patient',
        write_only = True
    )      

    class Meta:
        model = Treatment
        fields = ['id', 'start_date', 'end_date', 'dosage', 'frequency', 'patient_id', 'patient', 'medication_id', 'medication']

class TreatmentScheduleSerializer(serializers.ModelSerializer):
    treatment = TreatmentSerializer(read_only=True)
    treatment_id = serializers.PrimaryKeyRelatedField(
        queryset = Treatment.objects.all(),
        source = 'treatment',
        write_only = True
    )
    class Meta:
        model = TreatmentSchedule
        fields = ['id', 'dose_time', 'last_sent_at', 'treatment_id', 'treatment']      