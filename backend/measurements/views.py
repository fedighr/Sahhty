from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Measurement
from patients.models import Patient
from .serializers import MeasurementSerializer, RiskAssessmentSerializer
from .services import MeasurementService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema

class MeasurementView(ViewSet):
    @extend_schema(request=MeasurementSerializer, responses=MeasurementSerializer)
    @action(detail=False, methods=['post'], url_path='create_measurement', permission_classes=[AllowAny])
    def create_measurement(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        serializer = MeasurementSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = MeasurementService.createMeasurement(serializer.validated_data)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=MeasurementSerializer, responses=MeasurementSerializer)
    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def get_latest_measurements(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Patient ID is required'}, status=400)
        
        result = MeasurementService.getLeastestMeasurements(pk)
        return Response(result['data'], status=result['status'])

    @action(detail=True, methods=['get'], url_path='get_patient_measurements', permission_classes=[AllowAny])
    def get_patient_measurements(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Patient ID is required'}, status=400)
        
        type_filter = request.query_params.get('type', None)
        order = request.query_params.get('order', 'desc')
        result = MeasurementService.getPatientMeasurements(pk, request, type_filter, order)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=RiskAssessmentSerializer, responses=RiskAssessmentSerializer)
    @action(detail=True, methods=['get'], url_path='get_risk_assessment', permission_classes=[AllowAny])
    def get_risk_assessment(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Patient ID is required'}, status=400)

        result = MeasurementService.getRiskAssessment(pk)
        return Response(result['data'], status=result['status'])
