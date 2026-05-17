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
from rest_framework.pagination import PageNumberPagination

class DoctorView(ViewSet):
    pagination_class = PageNumberPagination

    @extend_schema(request=DoctorSerializer, responses=DoctorSerializer)
    @action(detail=False, methods=['post'], url_path="create_doctor", permission_classes=[AllowAny])
    def create_doctor(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        serializer = DoctorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = DoctorService.createDoctor(serializer.validated_data)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=DoctorSerializer,responses=DoctorSerializer)
    @action(detail=True, methods=['patch'], url_path="update_location", permission_classes=[AllowAny])
    def update_location(self, request, pk=None):
        doctor = self.get_object()
        serializer = DoctorSerializer(doctor, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({'success': True, 'message': 'Location updated'}, status=200)

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
    
    @action(detail=False, methods=['get'], url_path="get_all_doctors", permission_classes=[AllowAny])
    def get_all_doctors(self, request):
        speciality_filter = request.query_params.get('speciality', None)
        ville_filter = request.query_params.get('ville', None)
        gender_filter = request.query_params.get('gender', None)
        result = DoctorService.getAllDoctors(request, speciality_filter, ville_filter, gender_filter)
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

    @extend_schema(request=DoctorScheduleSerializer, responses=DoctorScheduleSerializer)
    @action(detail=True, methods=['get'], url_path="get_doctor_available_slots", permission_classes=[AllowAny])
    def get_doctor_available_slots(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Doctor ID is required'}, status=400)

        day = request.query_params.get('day')
        date = request.query_params.get('date')
        if not day or not date:
            return Response({'success': False, 'message': 'Day and date parameters are required'}, status=400)
        
        result = DoctorService.getDoctorAvailableSlots(pk, day, date)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=SpecialitySerializer, responses=SpecialitySerializer)
    @action(detail=False, methods=['get'], url_path="get_all_specialities", permission_classes=[AllowAny])
    def get_all_specialities(self, request):
        result = DoctorService.getAllSpecialities()
        return Response(result['data'], status=result['status'])

    @extend_schema(request=DoctorSerializer, responses=DoctorSerializer)
    @action(detail=False, methods=['get'], url_path="search", permission_classes=[AllowAny])
    def search(self, request):
        query = request.query_params.get('q', '').strip()

        if len(query) < 2:
            return Response(
                {'detail': 'Query must be at least 2 characters.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        doctors = DoctorSearch.search(query)
        if not doctors.exists():
            return Response(
                {'detail': 'No doctors found.'},
                status=status.HTTP_404_NOT_FOUND
            )

        paginator = self.pagination_class()
        result = paginator.paginate_queryset(doctors, request)
        serializer = DoctorSerializer(result, many=True)
        return paginator.get_paginated_response(serializer.data)