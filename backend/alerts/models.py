from django.db import models
from users.models import User

class Alert(models.Model):
    TYPE_CHOICES = [
        ('DELAYED_PERIOD', 'Delayed Period'),
        ('HIGH_GLYCEMIA', 'High Glycemia'),
        ('LOW_GLYCEMIA', 'Low Glycemia'),
        ('HIGH_BLOOD_PRESSURE', 'High Blood Pressure'),
        ('LOW_BLOOD_PRESSURE', 'Low Blood Pressure'),
        ('APPOINTMENT_REMINDER', 'Appointment Reminder'),
        ('TREATMENT_REMINDER', 'Treatment Reminder'),
        ('ULTRASOUND_REMINDER', 'Ultrasound Reminder'),
        ('MEDICATION_REMINDER', 'Medication Reminder'),
        ('RISK_HIGH', 'High Risk Detected'),
        ('RISK_MEDIUM', 'Medium Risk Detected'),
        ('PERSONAL_SPIKE', 'Unusual Personal Reading'),
    ]

    STATE_CHOICES = [
    ('NEW', 'New'),
    ('READ', 'Read'),
    ('RESOLVED', 'Resolved'),
]
    
    LEVEL_CHOICES = [
    ('INFO', 'Info'),
    ('WARNING', 'Warning'),
    ('CRITICAL', 'Critical'),
    ]

    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    message = models.TextField()
    level = models.CharField(max_length=30, choices=LEVEL_CHOICES, default='INFO')
    Status = models.CharField(max_length=30, choices=STATE_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='alerts')