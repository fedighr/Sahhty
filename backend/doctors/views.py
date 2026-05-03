from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Doctor, Speciality
from .serializers import DoctorSerializer, SpecialitySerializer, DoctorScheduleSerializer
from users.serializers import EmailSerializer
from .services import DoctorService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema
from .search import DoctorSearch

class DoctorView(ViewSet):
    @extend_schema(request=DoctorSerializer, responses=DoctorSerializer)
    @action(detail=False, methods=['post'], url_path="create_doctor", permission_classes=[AllowAny])
    def create_doctor(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
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

    @extend_schema(request=DoctorScheduleSerializer, responses=DoctorScheduleSerializer)
    @action(detail=False, methods=['post'],url_path="add_doctor_schedule", permission_classes=[AllowAny])
    def add_doctor_schedule(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No schedules provided'}, status=400)
        
        serializer = DoctorScheduleSerializer(data=request.data, many=True)
        serializer.is_valid(raise_exception=True)
        result = DoctorService.addDoctorSchedule(serializer.validated_data)
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=DoctorScheduleSerializer, responses=DoctorScheduleSerializer)
    @action(detail=True, methods=['get'], url_path="get_doctor_schedule", permission_classes=[AllowAny])
    def get_doctor_schedule(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Doctor ID is required'}, status=400)

        result = DoctorService.getDoctorSchedule(pk)
        return Response(result['data'], status=result['status'])

    @action(detail=False, methods=['get'], url_path="search", permission_classes=[AllowAny])
    def search(self, request):
        query = request.query_params.get('q', '').strip()

        if len(query) < 2:
            return Response(
                {'detail': 'Query must be at least 2 characters.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        doctors = list(DoctorSearch.search(query)[:20])
        if not doctors:
            return Response(
                {'detail': 'No doctors found.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = DoctorSerializer(doctors, many=True)

        return Response({
            'count': len(doctors),
            'results': serializer.data
        })