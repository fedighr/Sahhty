from rest_framework import serializers
from Pregnancies.models import Pregnancy
from Pregnancies.serializers import PregnancySerializer
from .models import Attachment

class AttachmentSerializer(serializers.ModelSerializer):
    pregnancy = PregnancySerializer(read_only=True)
    pregnancy_id = serializers.PrimaryKeyRelatedField(
        queryset = Pregnancy.objects.all(),
        source = 'pregnancy',
        write_only = True
    )

    class Meta :
        model = Attachment
        fields = ['id', 'type', 'file', 'upload_date', 'pregnancy_id', 'pregnancy']
        