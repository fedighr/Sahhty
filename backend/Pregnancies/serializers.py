from rest_framework import serializers
from .models import Pregnancy

class PregnancySerializer(serializers.ModelSerializer):
    class Meta:
        model = Pregnancy
        fields = "__all__"