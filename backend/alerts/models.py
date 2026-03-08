from django.db import models
from users.models import User

class Alert(models.Model):
    TYPE_CHOICES = [
    ('HEALTH', 'Health alert triggered by measurements or ML risk assessment'),
    ('REMINDER', 'Reminder for appointments, medication, or treatment'),
    ('DOCTOR_MESSAGE', 'Manual message or instruction sent by a doctor'),
    ('SYSTEM', 'System alert such as inactivity or pregnancy milestones'),
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
    status = models.CharField(max_length=30, choices=STATE_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='alerts')