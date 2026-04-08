from rest_framework import serializers
from .models import DCI, DciInteraction

class DCISerializer(serializers.ModelSerializer):
    class Meta:
        model = DCI
        fields = '__all__'

class DCIInteractionSerializer(serializers.ModelSerializer):
    dci1 = serializers.PrimaryKeyRelatedField(queryset=DCI.objects.all())
    dci2 = serializers.PrimaryKeyRelatedField(queryset=DCI.objects.all())

    class Meta:
        model = DciInteraction
        fields = '__all__'