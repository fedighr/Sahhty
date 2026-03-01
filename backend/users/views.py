from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import User
from .serializers import UserSerializer, LoginSerializer, EmailSerializer, PhoneSerializer
from .services import AuthService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser

class UserAuth(ViewSet):

    @action(detail=False, methods=['post'], url_path='signup', permission_classes=[AllowAny])
    def signup(self, request):
        serializer = UserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.register(serializer.validated_data)
        return Response(result['data'], status=result['status'])
    
    @action(detail=False, methods=['post'], url_path='signin', permission_classes=[AllowAny])
    def signin(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.login(serializer.validated_data)
        return Response(result['data'], status=result['status'])

    @action(detail=False, methods=['post'], url_path="resend_code", permission_classes=[AllowAny])
    def resend_code(self, request):
        serializer = EmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.resendCode(serializer.validated_data)
        return Response(result['data'], status=result['status']) 

    @action(detail=False, methods=['post'], url_path='verify_code', permission_classes=[AllowAny])
    def verify_code(self, request):
        serializer = EmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)        
        result = AuthService.verifyCode(serializer.validated_data.get('email'), request.data.get('code'))    
        return Response(result['data'], status=result['status']) 

    @action(detail=False, methods=['post'], url_path="verify_email", permission_classes=[AllowAny])
    def verify_email(self, request):
        serializer = EmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.verifyEmail(serializer.validated_data.get('email'))
        return Response(result['data'], status=result['status'])

    @action(detail=False, methods=['post'], url_path='verify_phone', permission_classes=[AllowAny])
    def verify_phone(self, request):
        serializer = PhoneSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.verifyPhone(serializer.validated_data.get('phone'))
        return Response(result['data'], status=result['status'])
    


