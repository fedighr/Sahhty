from django.db import models
from patients.models import Patient

class Medication(models.Model):
    category = [
        ('V', 'vital'),
        ('E', 'essential'),
        ('I', 'Intermediate importance'),
        ('N', 'non-essential'),
    ]

    prior_approval_Category = [
        ('O', 'need doctor or pharmacist approval'),
        ('N', 'no doctor approval needed'),
    ]

    code = models.CharField(max_length = 20, unique=True)
    name = models.CharField(max_length = 100)
    commercial_name = models.CharField(max_length = 100, null = True, blank = True)
    form = models.CharField(max_length = 50, null = True, blank = True)
    dosage = models.CharField(max_length = 50, null = True, blank = True)
    package = models.CharField(max_length = 50, null = True, blank = True)
    public_price = models.DecimalField(max_digits=10, decimal_places=3, null = True, blank = True)
    tarif_reference = models.DecimalField(max_digits=10, decimal_places=3, null = True, blank = True)
    category = models.CharField(max_length = 1, choices=category)
    dci = models.TextField()
    prior_approval = models.CharField(max_length = 1, choices=prior_approval_Category)
    
class MedicationDci(models.Model):
    medication = models.ForeignKey(Medication, on_delete=models.CASCADE, related_name='medication_dcis')
    dci = models.ForeignKey('dci.DCI', on_delete=models.CASCADE, related_name='dci_medications')

    class Meta:
        unique_together = ('medication', 'dci')

class Treatment(models.Model):
    start_date = models.DateField()
    end_date = models.DateField(null = True, blank = True)
    dose = models.CharField(max_length=255)
    frequency = models.CharField(max_length=255)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='treatments')
    medication = models.ForeignKey(Medication, on_delete=models.CASCADE, related_name='treatments')

class TreatmentSchedule (models.Model):
    dose_time = models.TimeField()
    last_sent_at = models.DateTimeField(null=True, blank=True)
    treatment = models.ForeignKey(Treatment, on_delete=models.CASCADE, related_name='schedules')      