from rest_framework import serializers
from .models import Measurement, RiskAssessment
from patients.models import Patient
from patients.serializers import PatientSerializer

class MeasurementSerializer(serializers.ModelSerializer):
    #patient = PatientSerializer(read_only=True)
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset = Patient.objects.all(),
        source = 'patient',
        write_only = True
    )
    class Meta:
        model = Measurement
        fields = ['id', 'type', 'measurement_date', 'value1', 'value2', 'unit', 'context', 'patient_id']

class RiskAssessmentSerializer(serializers.ModelSerializer):
    patient = PatientSerializer(read_only=True)
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset = Patient.objects.all(),
        source = 'patient',
        write_only = True
    )

    class Meta : 
        model = RiskAssessment
        fields = ['assessed_at', 'global_risk_level', 'personal_risk_level', 'personal_risk_note', 'glucose_used', 'bp_sys_used', 'bp_dia_used', 'heart_rate_used', 'weight_used', 'patient_id', 'patient']