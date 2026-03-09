from django.db import models
from patients.models import Patient

class Medication(models.Model):
    name = models.CharField(max_length = 100)
    description = models.TextField(null = True, blank = True)

class Treatment(models.Model):
    start_date = models.DateField()
    end_date = models.DateField(null = True, blank = True)
    dose = models.CharField(max_length=255)
    frequency = models.CharField(max_length=255)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='treatments')
    medication = models.ForeignKey(Medication, on_delete=models.PROTECT, related_name='treatments')

class TreatmentSchedule (models.Model):
    dose_time = models.TimeField()
    last_sent_at = models.DateTimeField(null=True, blank=True)
    treatment = models.ForeignKey(Treatment, on_delete=models.CASCADE, related_name='schedules')      