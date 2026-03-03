from django.db import models
from patients.models import Patient

class Pregnancy(models.Model):
    test_date = models.DateField()
    test_result = models.BooleanField()
    start_date = models.DateField(null=True, blank=True)
    due_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name="pregnancy")
