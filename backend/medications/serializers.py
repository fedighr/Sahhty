from rest_framework import serializers
from patients.models import Patient
from patients.serializers import PatientSerializer
from .models import Medication, Treatment, TreatmentSchedule


class MedicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medication
        fields = ['id', 'code', 'name', 'commercial_name', 'form',
                  'dosage', 'package', 'public_price', 'tarif_reference', 'category',
                  'dci', 'prior_approval']


class TreatmentScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = TreatmentSchedule
        fields = ['id', 'dose_time', 'last_sent_at']


class TreatmentSerializer(serializers.ModelSerializer):
    medication = MedicationSerializer(read_only=True)
    medication_id = serializers.PrimaryKeyRelatedField(
        queryset=Medication.objects.all(),
        source='medication',
        write_only=True
    )
    patient = PatientSerializer(read_only=True)
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset=Patient.objects.all(),
        source='patient',
        write_only=True
    )
    schedules = TreatmentScheduleSerializer(many=True, read_only=True)

    class Meta:
        model = Treatment
        fields = ['id', 'start_date', 'end_date', 'dose', 'frequency',
                  'patient_id', 'patient', 'medication_id', 'medication',
                  'schedules']

    def validate(self, data):
        start_date = data.get('start_date')
        end_date = data.get('end_date')

        if end_date and start_date and end_date < start_date:
            raise serializers.ValidationError({
                'end_date': 'End date cannot be before start date.'
            })

        return data


class TreatmentWithSchedulesSerializer(serializers.Serializer):
    treatment = TreatmentSerializer()
    schedules = TreatmentScheduleSerializer(many=True)

    def validate_schedules(self, schedules):
        if not schedules:
            raise serializers.ValidationError('At least one schedule is required.')
        return schedules