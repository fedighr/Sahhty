from django.db import models
from patients.models import Patient

class Attachment(models.Model):
    ATTACHMENT_CHOICES=[
        ('REPORT', 'Report'),
        ('ULTRASOUND', 'Ultrasound')
    ]
    
    type = models.CharField(max_length=30, choices=ATTACHMENT_CHOICES)
    file = models.FileField(upload_to='attachments/')
    upload_date = models.DateTimeField(auto_now=True)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='attachments')