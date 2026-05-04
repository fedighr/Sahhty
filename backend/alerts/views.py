from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Alert
from .serializers import AlertSerializer
from .services import AlertService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from rest_framework.pagination import PageNumberPagination

class AlertView(ViewSet):
    paginator_class = PageNumberPagination

    #automatic calls no need to call these endpoints manually, they are called by the services when needed
    @action(detail=False, methods=['post'], url_path='send_risk_alert', permission_classes=[AllowAny])
    def send_risk_alert(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        email = request.data.get('email')
        alert_message = request.data.get('alert_message')
        alert_level = request.data.get('alert_level')
        if not email or not alert_message or not alert_level:
            return Response({'success': False, 'message': 'email, alert_message and alert_level are required'}, status=400)
        result = AlertService.sendRiskAlert(email, alert_message, alert_level)
        return Response(result['data'], status=result['status'])

    @action(detail=False, methods=['post'], url_path='send_medication_reminders', permission_classes=[AllowAny])    
    def send_medication_reminders(self, request):
        result = AlertService.createMedicationReminder()
        return Response(result['data'], status=result['status'])
    
    @action(detail=False, methods=['post'], url_path='send_appointment_reminders', permission_classes=[AllowAny])
    def send_appointment_reminders(self, request):
        result = AlertService.createAppointmentReminder()
        return Response(result['data'], status=result['status'])

    @action(detail=False, methods=['post'], url_path='send_missing_measurements_alerts', permission_classes=[AllowAny])
    def send_missing_measurements_alerts(self, request):
        result = AlertService.sendMissingMeasurementsAlert()
        return Response(result['data'], status=result['status'])

    @action(detail=False, methods=['post'], url_path='send_unconfirmed_appointment_alerts', permission_classes=[AllowAny])
    def send_unconfirmed_appointment_alerts(self, request):
        result = AlertService.sendUnconfirmedAppointmentAlert()
        return Response(result['data'], status=result['status'])

    @action(detail=False, methods=['post'], url_path='send_pregnancy_no_appointment_alerts', permission_classes=[AllowAny])
    def send_pregnancy_no_appointment_alerts(self, request):
        result = AlertService.sendPregnancyNoAppointmentAlert()
        return Response(result['data'], status=result['status'])

    # This endpoints made for frontend to get the alerts for a specific user and mark them as read when the user opens them, they are not called by the services
    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def get_alerts_by_user(self, request, pk=None):
        result = AlertService.getAlertsByUser(pk, request)
        return Response(result['data'], status=result['status'])

    @action(detail=True, methods=['patch'], url_path='mark_as_read', permission_classes=[AllowAny])
    def mark_as_read(self, request, pk=None):
        result = AlertService.markAlertAsRead(pk)
        return Response(result['data'], status=result['status'])   


        