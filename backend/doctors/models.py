from django.db import models
from django.core.validators import MinValueValidator, RegexValidator
from users.models import User

class Speciality(models.Model):
    name = models.CharField(max_length=50, validators=[RegexValidator(r'^[a-zA-Z\s]+$')])
    description = models.TextField(null=True, blank=True)

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
    experience = models.IntegerField(validators=[MinValueValidator(0)])
    consultation_price = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True, validators=[MinValueValidator(0)])
    bio = models.TextField(blank=True, null=True)
    is_available = models.BooleanField(default=True)
    is_doctor_verified = models.BooleanField(default=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="doctor")
    speciality = models.ForeignKey(Speciality, on_delete=models.CASCADE, related_name="doctors")