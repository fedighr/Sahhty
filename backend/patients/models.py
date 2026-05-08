from django.db import models
from users.models import User
from django.core.validators import MinValueValidator, RegexValidator

class Patient(models.Model):
    BLOOD_TYPE_CHOICES = [
        ('A+', 'A Positive'),
        ('A-', 'A Negative'),
        ('B+', 'B Positive'),
        ('B-', 'B Negative'),
        ('AB+', 'AB Positive'),
        ('AB-', 'AB Negative'),
        ('O+', 'O Positive'),
        ('O-', 'O Negative'),
    ]

    height = models.IntegerField(validators=[MinValueValidator(1)])
    weight = models.DecimalField(max_digits=5, decimal_places=2, validators=[MinValueValidator(1)])
    blood_type = models.CharField(max_length=3, choices=BLOOD_TYPE_CHOICES, null=True, blank=True)
    chronic_diseases = models.TextField(null=True, blank=True)
    allergies = models.TextField(null=True, blank=True)       
    current_medications = models.TextField(null=True, blank=True)
    family_doctor_name = models.CharField(max_length=30, validators=[RegexValidator(r'^[a-zA-Z\s]+$')], null=True, blank=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="patient")

class MenstrualCycle(models.Model):
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('MENOPAUSE', 'Menopause'),
        ('PREPUBESCENT', 'Prepubescent')
    ]

    menstrual_status = models.CharField(max_length=12, choices=STATUS_CHOICES, default='ACTIVE')
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)  
    patient = models.OneToOneField(Patient, on_delete=models.CASCADE, related_name="menstrual_cycle")  

class PeriodEntry(models.Model):
    menstrual_cycle = models.ForeignKey(MenstrualCycle, on_delete=models.CASCADE, related_name='periods')
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    notes = models.TextField(null=True, blank=True)        