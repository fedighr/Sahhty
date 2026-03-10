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

class PatientView(ViewSet):

    @extend_schema(request=PatientSerializer, responses=PatientSerializer)
    @action(detail=False, methods=['post'], url_path='create_patient', permission_classes=[AllowAny])
    def create_patient(self, request):
        serializer = PatientSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = PatientService.createPatient(serializer.validated_data)
        return Response(result['data'], result['status'])