from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Measurement
from .serializers import MeasurementSerializer
from .services import MeasurementService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser

class MeasurementView(ViewSet):
    @action(detail=False, methods=['post'], url_path='MeasurementService', permission_classes=[AllowAny])
    def create_mesurement(self, request):
        serializer = MeasurementSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = MeasurementService.createMesurement(serializer.validated_data)
        return Response(result['data'], status=result['status'])


