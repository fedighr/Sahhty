from rest_framework import serializers
from patients.models import Patient
from patients.serializers import PatientSerializer
from .models import Attachment

class AttachmentSerializer(serializers.ModelSerializer):
    patient = PatientSerializer(read_only=True)
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset = Patient.objects.all(),
        source = 'patient',
        write_only = True
    )

    class Meta :
        model = Attachment
        fields = ['id', 'type', 'file', 'upload_date', 'patient_id', 'patient']
        