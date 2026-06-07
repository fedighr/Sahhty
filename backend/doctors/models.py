from django.core.exceptions import ValidationError
from django.db import models
from django.core.validators import MinValueValidator, RegexValidator
from users.models import User

class Speciality(models.Model):
    name = models.CharField(max_length=50, validators=[RegexValidator(r'^[a-zA-Z\s]+$')])
    description = models.TextField(null=True, blank=True)

    def __str__(self):
        return self.name

class Doctor(models.Model):
    VILLE_CHOICES = [
        ('TUNIS', 'Tunis'),
        ('ARIANA', 'Ariana'),
        ('BEN_AROUS', 'Ben Arous'),
        ('MANOUBA', 'Manouba'),
        ('NABEUL', 'Nabeul'),
        ('ZAGHOUAN', 'Zaghouan'),
        ('BIZERTE', 'Bizerte'),
        ('BEJA', 'Béja'),
        ('JENDOUBA', 'Jendouba'),
        ('KEF', 'Le Kef'),
        ('SILIANA', 'Siliana'),
        ('SOUSSE', 'Sousse'),
        ('MONASTIR', 'Monastir'),
        ('MAHDIA', 'Mahdia'),
        ('SFAX', 'Sfax'),
        ('KAIROUAN', 'Kairouan'),
        ('KASSERINE', 'Kasserine'),
        ('SIDI_BOUZID', 'Sidi Bouzid'),
        ('GABES', 'Gabès'),
        ('MEDENINE', 'Médenine'),
        ('TATAOUINE', 'Tataouine'),
        ('GAFSA', 'Gafsa'),
        ('TOZEUR', 'Tozeur'),
        ('KEBILI', 'Kébili'),
    ]

    ville = models.CharField(max_length=20, choices=VILLE_CHOICES, default='TUNIS')
    address = models.TextField()
    latitude = models.DecimalField(max_digits=11, decimal_places=8, null=True, blank=True)
    longitude = models.DecimalField(max_digits=11, decimal_places=8, null=True, blank=True)
    experience = models.IntegerField(validators=[MinValueValidator(0)])
    consultation_price = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True, validators=[MinValueValidator(0)])
    bio = models.TextField(blank=True, null=True)
    is_doctor_verified = models.BooleanField(default=False)
    consultation_duration = models.IntegerField(default=30, validators=[MinValueValidator(1)])
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="doctor")
    speciality = models.ForeignKey(Speciality, on_delete=models.CASCADE, related_name="doctors")

class DoctorSchedule(models.Model):
    DAY_CHOICES = [
        ('MONDAY', 'Monday'),
        ('TUESDAY', 'Tuesday'),
        ('WEDNESDAY', 'Wednesday'),
        ('THURSDAY', 'Thursday'),
        ('FRIDAY', 'Friday'),
        ('SATURDAY', 'Saturday'),
        ('SUNDAY', 'Sunday'),
    ]

    day_of_week = models.CharField(max_length=20, choices=DAY_CHOICES)
    start_time = models.TimeField()
    end_time = models.TimeField()
    pause_start_time = models.TimeField(null=True, blank=True)
    pause_end_time = models.TimeField(null=True, blank=True)
    is_available = models.BooleanField(default=True)
    
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name="schedules")

    class Meta:
        unique_together = [('doctor', 'day_of_week')]

    def clean_time(self):
        if self.start_time >= self.end_time:
            raise ValidationError("Start time must be before end time.")
        if self.pause_start_time and self.pause_end_time:
             if self.pause_start_time >= self.pause_end_time:
                raise ValidationError("Pause start time must be before pause end time.")
             if not (self.start_time < self.pause_start_time < self.pause_end_time < self.end_time):
                raise ValidationError("Pause times must be within the working hours.")
        