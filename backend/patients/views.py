from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Patient, MenstrualCycle
from .serializers import PatientSerializer, MenstrualCycleSerializer
from users.serializers import EmailSerializer
from .services import PatientService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema
from .search import PatientSearch
from rest_framework.pagination import PageNumberPagination

class PatientView(ViewSet):
    pagination_class = PageNumberPagination

    @extend_schema(request=PatientSerializer, responses=PatientSerializer)
    @action(detail=False, methods=['post'], url_path='create_patient', permission_classes=[AllowAny])
    def create_patient(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        serializer = PatientSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = PatientService.createPatient(request.data)
        return Response(result['data'], result['status'])

    @extend_schema(request=PatientSerializer, responses=PatientSerializer)
    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def get_patient_by_id(self, request, pk=None):
        result = PatientService.getPatientById(pk)
        return Response(result['data'], result['status'])

    @extend_schema(request=PatientSerializer, responses=PatientSerializer)
    @action(detail=True, methods=['patch'], permission_classes=[AllowAny])
    def update_patient(self, request, pk=None):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        result = PatientService.updatePatient(pk, request.data)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=PatientSerializer, responses=PatientSerializer)
    @action(detail=False, methods=['get'], url_path="search", permission_classes=[AllowAny])
    def search(self, request):
        query = request.query_params.get('q', '').strip()

        if len(query) < 2:
                return Response(
                    {'detail': 'Query must be at least 2 characters.'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        patient = PatientSearch.search(query)
        if not patient.exists():
                return Response(
                    {'detail': 'No patient found.'},
                    status=status.HTTP_404_NOT_FOUND
                )

        paginator = self.pagination_class()
        result = paginator.paginate_queryset(patient, request)
        serializer = PatientSerializer(result, many=True)
        return paginator.get_paginated_response(serializer.data)
    
