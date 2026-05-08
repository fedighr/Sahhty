from rest_framework import serializers
from patients.models import Patient
from patients.serializers import PatientSerializer
from .models import Attachment, PatientDoctorAccess
from doctors.models import Doctor

class AttachmentSerializer(serializers.ModelSerializer):
    def validate_file(self, value):
        max_size = 10 * 1024 * 1024
        if value.size > max_size:
            raise serializers.ValidationError("File size must be under 10MB.")
        return value

    patient = PatientSerializer(read_only=True)
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset = Patient.objects.all(),
        source = 'patient',
        write_only = True
    )

    class Meta :
        model = Attachment
        fields = ['id', 'type', 'file', 'upload_date', 'patient_id', 'patient']
        
class PatientDoctorAccessSerializer(serializers.ModelSerializer):
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset = Patient.objects.all(),
        source = 'patient',
    )
    doctor_id = serializers.PrimaryKeyRelatedField(
        queryset = Doctor.objects.all(),
        source = 'doctor',
    )

    class Meta:
        model = PatientDoctorAccess
        fields = ['id', 'granted_at', 'expires_at', 'can_write', 'status', 'patient_id', 'doctor_id']