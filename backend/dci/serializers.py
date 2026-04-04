from rest_framework import serializers
from .models import DCI

class DCISerializer(serializers.ModelSerializer):
    class Meta:
        model = DCI
        fields = '__all__'