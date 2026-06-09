from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Pregnancy
from .serializers import PregnancySerializer
from users.serializers import EmailSerializer
from .services import PregnancyService
from utils.constraints import IsOwnerOrAdmin
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema

class PregnancyView(ViewSet):
    @extend_schema(request=PregnancySerializer, responses=PregnancySerializer)
    @action(detail=False, methods=['post'], url_path='create_pregnancy', permission_classes=[AllowAny])
    def create_pregnancy(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        serializer = PregnancySerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        result = PregnancyService.CreatePregnancy(serializer.validated_data)
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=PregnancySerializer, responses=PregnancySerializer)
    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def get_current_pregnancy(self, request, pk=None):
        result = PregnancyService.getCurrentPregnancy(pk)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=PregnancySerializer, responses=PregnancySerializer)
    @action(detail=True, methods=['patch'], permission_classes=[AllowAny])
    def update_pregnancy(self, request, pk=None):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        result = PregnancyService.updatePregnancy(pk, request.data)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=PregnancySerializer, responses=PregnancySerializer)
    @action(detail=True, methods=['patch'], url_path='end_pregnancy', permission_classes=[AllowAny])
    def end_pregnancy(self, request, pk=None):
        if(request.data.get('end_date') is None):
            return Response({'success': False, 'message': 'End date is required to end pregnancy'}, status=400)
        
        result = PregnancyService.endPregnancy(pk, request.data.get('end_date'))
        return Response(result['data'], status=result['status'])

    @extend_schema(responses=PregnancySerializer)
    @action(detail=True, methods=['delete'], permission_classes=[AllowAny])
    def delete_pregnancy(self, request, pk=None):
        result = PregnancyService.deletePregnancy(pk)
        return Response(result['data'], status=result['status'])