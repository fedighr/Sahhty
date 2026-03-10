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
        result = AlertService.sendRiskAlert(email, alert_message, alert_level)
        return Response(result['data'], status=result['status'])

    @action(detail=False, methods=['post'], url_path='send_medication_reminders', permission_classes=[AllowAny])    
    def send_medication_reminders(self, request):
        result = AlertService.createMedicationReminder()
        return Response(result['data'], status=result['status'])
    
    @action(detail=False, methods=['post'], url_path='send_appointment_reminders', permission_classes=[AllowAny])
    def send_appointment_reminders(self, request):
        result = AlertService.createAppointmentReminder(request)
        return Response("ok", status=200)
    
    @action(detail=False, methods=['post'], url_path='send_missing_measurements_alerts', permission_classes=[AllowAny])
    def send_missing_measurements_alerts(self, request):
        result = AlertService.sendMissingMeasurementsAlert()
        return Response("ok", status=200)
    
    @action(detail=False, methods=['post'], url_path='send_unconfirmed_appointment_alerts', permission_classes=[AllowAny])
    def send_unconfirmed_appointment_alerts(self, request):
        result = AlertService.sendUnconfirmedAppointmentAlert()
        return Response("ok", status=200)

    @action(detail=False, methods=['post'], url_path='send_pregnancy_no_appointment_alerts', permission_classes=[AllowAny])
    def send_pregnancy_no_appointment_alerts(self, request):
        result = AlertService.sendPregnancyNoAppointmentAlert()
        return Response("ok", status=200)
        