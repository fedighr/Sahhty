from django.db import models
from Pregnancies.models import Pregnancy

class Medication(models.Model):
    nom = models.CharField(max_length = 100)
    description = models.TextField(null = True, blank = True)

class Treatment(models.Model):
    start_date = models.DateField()
    end_date = models.DateField(null = True, blank = True)
    dosage = models.CharField(max_length=255)
    frequency = models.CharField(max_length=255)
    pregnancy = models.ForeignKey(Pregnancy, on_delete=models.CASCADE, related_name='treatments')
    medication = models.ForeignKey(Medication, on_delete=models.PROTECT, related_name='treatments')
    