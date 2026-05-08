from django.db import models
from patients.models import Patient
from doctors.models import Doctor
from patients.models import Patient
import time

def attachment_upload_path(instance, filename):
    new_filename = f'{int(time.time())}_{filename}'
    return f'attachments/patients/{instance.patient.id}/{new_filename}'

class Attachment(models.Model):
    ATTACHMENT_CHOICES = [
        ('REPORT', 'Report'),
        ('ULTRASOUND', 'Ultrasound'),
        ('BLOOD_TEST', 'Blood Test'),
        ('URINE_TEST', 'Urine Test'),
        ('PRESCRIPTION', 'Prescription'),
        ('VACCINATION', 'Vaccination'),
        ('ECHO', 'Echocardiography'),
        ('OTHER', 'Other'),
    ]
    
    type = models.CharField(max_length=30, choices=ATTACHMENT_CHOICES)
    file = models.FileField(upload_to=attachment_upload_path, max_length=255)
    upload_date = models.DateTimeField(auto_now=True)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='attachments')

class PatientDoctorAccess(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('ACCEPTED', 'Accepted'),
    ]

    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='doctor_accesses')
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name='patient_accesses')
    granted_at = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    can_write = models.BooleanField(default=False)

    class Meta:
        unique_together = ('patient', 'doctor')