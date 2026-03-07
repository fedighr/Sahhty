from django.db import models
from Pregnancies.models import Pregnancy

class Measurement(models.Model):
    TYPE_CHOICES = [
    ('WEIGHT', 'Weight'),
    ('BLOOD_PRESSURE', 'Blood Pressure'),
    ('GLYCEMIA', 'Glycemia'),
    ('TEMPERATURE', 'Temperature'),
    ('HEART_RATE', 'Heart Rate'),
    ('OXYGEN', 'Oxygen'),
]

    UNIT_CHOICES = [
        ('KG', 'kg'),
        ('MMHG', 'mmHg'),
        ('G_L', 'g/L'),
        ('C', '°C'),
        ('BPM', 'bpm'),
    ]

    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    measurement_date = models.DateTimeField(auto_now_add=True)
    value1 = models.DecimalField(max_digits=5, decimal_places=2)
    value2 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    unit = models.CharField(max_length=10, choices=UNIT_CHOICES)
    context = models.CharField(max_length=100, blank=True, default="")
    pregnancy = models.ForeignKey(Pregnancy, on_delete=models.CASCADE, related_name="measurements")

class RiskAssessment(models.Model):
    RISK_CHOICES = [
        ('LOW', 'Low'),
        ('MEDIUM', 'Medium'),
        ('HIGH', 'High'),
    ]

    assessed_at = models.DateTimeField(auto_now_add=True)
    global_risk_level = models.CharField(max_length=10, choices=RISK_CHOICES)
    global_risk_percentage = models.DecimalField(max_digits=5, decimal_places=2)
    personal_risk_level = models.CharField(max_length=10, choices=RISK_CHOICES, null=True, blank=True)
    personal_risk_note = models.TextField(null=True, blank=True)
    glucose_used = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    bp_sys_used = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    bp_dia_used = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    heart_rate_used = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    weight_used = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    pregnancy = models.ForeignKey(Pregnancy, on_delete=models.CASCADE, related_name="risk_assessments")