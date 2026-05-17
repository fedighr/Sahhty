from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Appointment
from .serializers import AppointmentSerializer
from users.serializers import EmailSerializer
from .services import AppointmentService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema
from rest_framework.pagination import PageNumberPagination

class AppointmentView(ViewSet):
    @extend_schema(request=AppointmentSerializer, responses=AppointmentSerializer)
    @action(detail=False, methods=['post'], url_path="create_appointment", permission_classes=[AllowAny])
    def create_appointment(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        serializer = AppointmentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AppointmentService.CreateAppointment(serializer.validated_data)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=AppointmentSerializer, responses=AppointmentSerializer)
    @action(detail=True, methods=['put'], url_path="confirm_appointment", permission_classes=[AllowAny])
    def confirm_appointment(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Appointment ID is required'}, status=400)
        
        result = AppointmentService.ConfirmAppointment(pk)
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=AppointmentSerializer, responses=AppointmentSerializer)
    @action(detail=True, methods=['put'], url_path="cancel_appointment", permission_classes=[AllowAny])
    def cancel_appointment(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Appointment ID is required'}, status=400)
        
        if not request.data.get('cancelled_by'):
            return Response({'success': False, 'message': 'Cancelled by field is required'}, status=400)
        
        result = AppointmentService.CancelAppointment(pk, cancelled_by=request.data.get('cancelled_by'))
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=AppointmentSerializer, responses=AppointmentSerializer)
    @action(detail=True, methods=['get'], url_path="get_patient_today_appointments", permission_classes=[AllowAny])
    def get_patient_today_appointments(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Patient ID is required'}, status=400)
        
        result = AppointmentService.GetPatientTodayAppointments(pk)
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=AppointmentSerializer, responses=AppointmentSerializer)
    @action(detail=True, methods=['get'], url_path="get_doctor_today_appointments", permission_classes=[AllowAny])
    def get_doctor_today_appointments(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Doctor ID is required'}, status=400)
        
        result = AppointmentService.GetDoctorTodayAppointments(pk)
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=AppointmentSerializer, responses=AppointmentSerializer)
    @action(detail=True, methods=['get'], url_path="get_patient_appointments", permission_classes=[AllowAny])
    def get_patient_appointments(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Patient ID is required'}, status=400)
        
        status_filter = request.query_params.get('status', None)
        order = request.query_params.get('order', 'desc')
        result = AppointmentService.GetPatientAppointments(pk, request, status_filter, order)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=AppointmentSerializer, responses=AppointmentSerializer)
    @action(detail=True, methods=['get'], url_path="get_doctor_appointments", permission_classes=[AllowAny])
    def get_doctor_appointments(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Doctor ID is required'}, status=400)
        status_filter = request.query_params.get('status', None)
        order = request.query_params.get('order', 'desc')
        result = AppointmentService.GetDoctorAppointments(pk, request, status_filter, order)
        return Response(result['data'], status=result['status'])