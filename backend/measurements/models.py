from django.db import models
from Pregnancies.models import Pregnancy

class Measurement(models.Model):
    TYPE_CHOICES = [
        ('POIDS', 'Poids'),
        ('TENSION', 'Tension'),
        ('GLYCEMIE', 'Glycémie'),
        ('TEMPERATURE', 'Température')
    ]
    UNIT_CHOICES = [
        ('KG', 'kg'),
        ('MMHG', 'mmHg'),
        ('G_L', 'g/L'),
        ('C', '°C'),
    ]

    type = models.CharField(max_length=50, choices=TYPE_CHOICES, default='POIDS')
    measurement_date = models.DateTimeField()
    value1 = models.DecimalField(max_digits=5, decimal_places=2)
    value2 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    unit = models.CharField(max_length=10, choices=UNIT_CHOICES)
    context = models.CharField(max_length=100, blank=True, default="")
    pregnancy = models.ForeignKey(Pregnancy, on_delete=models.CASCADE, related_name="measurements")
