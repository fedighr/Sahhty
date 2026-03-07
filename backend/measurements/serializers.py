from rest_framework import serializers
from .models import Measurement, RiskAssessment
from Pregnancies.serializers import PregnancySerializer
from Pregnancies.models import Pregnancy

class MeasurementSerializer(serializers.ModelSerializer):
    pregnancy = PregnancySerializer(read_only=True)
    pregnancy_id = serializers.PrimaryKeyRelatedField(
        queryset = Pregnancy.objects.all(),
        source = 'pregnancy',
        write_only = True
    )

    class Meta:
        model = Measurement
        fields = ['id', 'type', 'measurement_date', 'value1', 'value2', 'unit', 'context', 'pregnancy_id', 'pregnancy']

class RiskAssessmentSerializer(serializers.ModelSerializer):
    pregnancy = PregnancySerializer(read_only=True)
    pregnancy_id = serializers.PrimaryKeyRelatedField(
        queryset = Pregnancy.objects.all(),
        source = 'pregnancy',
        write_only = True
    )

    class Meta : 
        model = RiskAssessment
        fields = ['assessed_at', 'global_risk_level', 'global_risk_percentage', 'personal_risk_level', 'personal_risk_note', 'glucose_used', 'bp_sys_used', 'bp_dia_used', 'heart_rate_used', 'weight_used', 'pregnancy_id', 'pregnancy']