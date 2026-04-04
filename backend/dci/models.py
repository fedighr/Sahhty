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

