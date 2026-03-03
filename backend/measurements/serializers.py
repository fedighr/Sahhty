from rest_framework import serializers
from .models import Measurement
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