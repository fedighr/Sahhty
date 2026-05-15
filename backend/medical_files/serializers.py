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
        allowed_types = [
            'image/jpeg',
            'image/png', 
            'image/jpg',
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'text/plain',
        ]
        if value.content_type not in allowed_types:
            raise serializers.ValidationError("Only JPEG, PNG, PDF, Word, Excel and text files are allowed.")
        
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