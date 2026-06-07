from django.db import models

class DCI(models.Model):
    status=[
        ('SAFE', 'Safe'),
        ('UNSAFE', 'Unsafe'),
        ('UNKNOWN', 'Unknown'),
        ('CAUTION', 'Caution'),
        ('NOT_APPLICABLE', 'Not Applicable'),
    ]

    name = models.CharField(max_length=255)
    overall_status = models.CharField(max_length=20, choices=status)
    first_trimester_status = models.CharField(max_length=20, choices=status)
    second_trimester_status = models.CharField(max_length=20, choices=status)
    third_trimester_status = models.CharField(max_length=20, choices=status)
    delivery_status = models.CharField(max_length=20, choices=status)
    summary = models.TextField(null=True, blank=True)
    source_url = models.URLField(null=True, blank=True)

    def __str__(self):
        return self.name

class DciInteraction(models.Model):
    SEVERITY_CHOICES = [
        ("CONTRE_INDICATION", "Contre-indication"),
        ("PRECAUTION_EMPLOI", "Précaution d'emploi"),
        ("DECONSEILLEE", "Déconseillée"),
        ("A_PRENDRE_EN_COMPTE", "À prendre en compte"),
        ("NON_SIGNIFICATIVE", "Non significative"),
    ]

    dci1 = models.ForeignKey(DCI, on_delete=models.CASCADE, related_name='dci1_interactions')
    dci2 = models.ForeignKey(DCI, on_delete=models.CASCADE, related_name='dci2_interactions')
    severity = models.CharField(max_length=50, choices=SEVERITY_CHOICES)
    description = models.TextField(null=True, blank=True)

    def __str__(self):
        return f"{self.dci1.name} ↔ {self.dci2.name} ({self.get_severity_display()})"
