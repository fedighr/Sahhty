from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Attachment, PatientDoctorAccess
from .serializers import AttachmentSerializer, PatientDoctorAccessSerializer
from .services import MedicalFileService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema
from rest_framework.pagination import PageNumberPagination

class MedicalFileView(ViewSet):
    paginator_class = PageNumberPagination
    
    @extend_schema(request=AttachmentSerializer, responses=AttachmentSerializer)
    @action(detail=False, methods=['post'], url_path="create_attachment", permission_classes=[AllowAny])
    def create_attachment(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        serializer = AttachmentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = MedicalFileService.createAttachment(serializer.validated_data)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=PatientDoctorAccessSerializer, responses=PatientDoctorAccessSerializer)
    @action(detail=False, methods=['post'], url_path="create_patient_doctor_access", permission_classes=[AllowAny])
    def create_patient_doctor_access(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)

        result = MedicalFileService.createPatientDoctorAccess(request.data)
        return Response(result['data'], status=result['status'])
    
    @action(detail=True, methods=['get'], url_path="get_patient_medical_files", permission_classes=[AllowAny])
    def get_patient_medical_files(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Patient ID is required'}, status=400)
        
        type_filter = request.query_params.get('type', None)
        order = request.query_params.get('order', 'asc')
        result = MedicalFileService.getPatientMedicalFiles(pk, request, type_filter, order)
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=MedicalFileService, responses=MedicalFileService)
    @action(detail=True, methods=['get'], url_path="get_patient_doctors", permission_classes=[AllowAny])
    def get_patient_doctors(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Patient ID is required'}, status=400)

        result = MedicalFileService.getPatientDoctors(pk)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=PatientDoctorAccessSerializer, responses=PatientDoctorAccessSerializer)
    @action(detail=True, methods=['get'], url_path="get_doctor_patients", permission_classes=[AllowAny])
    def get_doctor_patients(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Doctor ID is required'}, status=400)

        result = MedicalFileService.getDoctorPatients(pk)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=PatientDoctorAccessSerializer, responses=PatientDoctorAccessSerializer)
    @action(detail=True, methods=['delete'], url_path="delete_attachment", permission_classes=[AllowAny])
    def delete_attachment(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Attachment ID is required'}, status=400)

        result = MedicalFileService.deleteAttachment(pk)
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=PatientDoctorAccessSerializer, responses=PatientDoctorAccessSerializer)
    @action(detail=True, methods=['patch'], url_path="update_attachment", permission_classes=[AllowAny])
    def update_attachment(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Attachment ID is required'}, status=400)

        serializer = AttachmentSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        result = MedicalFileService.updateAttachment(pk, serializer.validated_data, request)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=PatientDoctorAccessSerializer, responses=PatientDoctorAccessSerializer)
    @action(detail=True, methods=['delete'], url_path="delete_patient_doctor_access", permission_classes=[AllowAny])
    def delete_patient_doctor_access(self, request, pk=None):
        if not pk:
            return Response({'success': False, 'message': 'Access ID is required'}, status=400)

        result = MedicalFileService.deletePatientDoctorAccess(pk)
        return Response(result['data'], status=result['status'])
        
    @extend_schema(request=PatientDoctorAccessSerializer, responses=PatientDoctorAccessSerializer)
    @action(detail=False, methods=['delete'], url_path="revoke_access", permission_classes=[AllowAny])
    def revoke_access(self, request):
        patient_id = request.data.get('patient_id')
        doctor_id = request.data.get('doctor_id')
        if not patient_id or not doctor_id:
            return Response({'success': False, 'message': 'patient_id and doctor_id are required'}, status=400)
        deleted, _ = PatientDoctorAccess.objects.filter(patient_id=patient_id, doctor_id=doctor_id).delete()
        if deleted == 0:
            return Response({'success': False, 'message': 'Access not found'}, status=404)
        return Response({'success': True, 'message': 'Access revoked successfully'}, status=200)

    @extend_schema(request=PatientDoctorAccessSerializer, responses=PatientDoctorAccessSerializer)
    @action(detail=False, methods=['post'], url_path="request_medical_access", permission_classes=[AllowAny])
    def request_medical_access(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        serializer = PatientDoctorAccessSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = MedicalFileService.requestMedicalAccess(serializer.validated_data)
        return Response(result['data'], status=result['status'])

    @extend_schema(request=PatientDoctorAccessSerializer, responses=PatientDoctorAccessSerializer)
    @action(detail=True, methods=['get'], url_path="get_patient_doctors_requests", permission_classes=[AllowAny])
    def get_patient_doctors_requests(self, request, pk=None):
        patient_id = pk
        if not patient_id:
            return Response({'success': False, 'message': 'Patient ID is required'}, status=400)

        result = MedicalFileService.getPatientDoctorsRequests(patient_id)
        return Response(result['data'], status=result['status'])