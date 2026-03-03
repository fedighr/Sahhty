from rest_framework import serializers
from patients.models import Patient
from doctors.models import Doctor
from doctors.serializers import DoctorSerializer
from patients.serializers import PatientSerializer
from .models import Appointment

class AppointmentSerializer(serializers.ModelSerializer):
    patient = PatientSerializer(read_only=True)
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset = Patient.objects.all(),
        source = 'patient',
        write_only=True
    )
    doctor = DoctorSerializer(read_only=True)
    doctor_id = serializers.PrimaryKeyRelatedField(
        queryset= Doctor.objects.all(),
        source = 'doctor',
        write_only = True
    )

    class Meta:
        model = Appointment
        fields = ['id', 'appointment_date', 'status', 'reason', 'created_at', 'updated_at', 'patient_id', 'patient', 'doctor_id', 'doctor']
