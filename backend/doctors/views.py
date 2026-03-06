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

class DoctorView(ViewSet):
    @action(detail=False, methods=['post'], url_path="create_doctor", permission_classes=[AllowAny])
    def create_doctor(self, request):
        serializer = DoctorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = DoctorService.createDoctor(serializer.validated_data)
        return Response(result['data'], status=result['status'])