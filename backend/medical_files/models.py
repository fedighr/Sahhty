from django.db import models
from patients.models import Patient
from doctors.models import Doctor
from patients.models import Patient

class Attachment(models.Model):
    ATTACHMENT_CHOICES=[
        ('REPORT', 'Report'),
        ('ULTRASOUND', 'Ultrasound')
    ]
    
    type = models.CharField(max_length=30, choices=ATTACHMENT_CHOICES)
    file = models.FileField(upload_to='attachments/', max_length=255)
    upload_date = models.DateTimeField(auto_now=True)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='attachments')

class PatientDoctorAccess(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE)
    granted_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    can_write = models.BooleanField(default=False)

    class Meta:
        unique_together = ('patient', 'doctor')