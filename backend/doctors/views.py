from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Doctor, Speciality
from .serializers import DoctorSerializer, SpecialitySerializer
from users.serializers import EmailSerializer
from .services import DoctorService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema

class DoctorView(ViewSet):
    @extend_schema(request=DoctorSerializer, responses=DoctorSerializer)
    @action(detail=False, methods=['post'], url_path="create_doctor", permission_classes=[AllowAny])
    def create_doctor(self, request):
        serializer = DoctorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = DoctorService.createDoctor(serializer.validated_data)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=DoctorSerializer, responses=DoctorSerializer)
    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def get_doctor_by_id(self, request, pk=None):
        result = DoctorService.getDoctorById(pk)
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=DoctorSerializer, responses=DoctorSerializer)
    @action(detail=True, methods=['patch'], permission_classes=[AllowAny])
    def update_doctor(self, request, pk=None):
        result = DoctorService.updateDoctor(pk, request.data)
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=EmailSerializer, responses=EmailSerializer)
    @action(detail=False, methods=['get'], url_path="get_all_doctors", permission_classes=[AllowAny])
    def get_all_doctors(self, request):
        result = DoctorService.getAllDoctors()
        return Response(result['data'], status=result['status'])