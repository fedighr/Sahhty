from rest_framework import serializers
from .models import Alert
from users.models import User
from users.serializers import UserSerializer

class AlertSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    user_id = serializers.PrimaryKeyRelatedField(
        queryset = User.objects.all(),
        source = 'user',
        write_only = True
    )

    class Meta:
        model = Alert
        fields = ['id', 'type', 'message', 'status', 'created_at', 'user_id', 'user']