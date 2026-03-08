from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Alert
from .serializers import AlertSerializer
from .services import AlertService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser

class AlertView(ViewSet):
    @action(detail=False, methods=['post'], url_path='send_risk_alert', permission_classes=[AllowAny])
    def send_risk_alert(self, request):
        email = request.data.get('email')
        alert_message = request.data.get('alert_message')
        alert_level = request.data.get('alert_level' )
        result = AlertService.createAlert(email, alert_message, alert_level)
        return Response(result['data'], status=result['status'])

    @action(detail=False, methods=['post'], url_path='send_medication_reminders', permission_classes=[AllowAny])    
    def send_medication_reminders(self, request):
        result = AlertService.createMedicationReminder()

        return Response(result['data'], status=result['status'])