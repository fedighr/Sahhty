from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import User
from .serializers import UserSerializer, LoginSerializer
from .services import AuthService

class UserAuth(ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    @action(detail=False, methods=['post'],url_path='signup')
    def signup(self, request):
        serializer = UserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.register(serializer.data)
        return Response(result['data'], status=result['status'])
    
    @action(detail=False, methods=['post'], url_path='signin')
    def signin(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.login(serializer.data)
        return Response(result['data'], status=result['status'])

    @action(detail=False, methods=['post'], url_path="resendCode")
    def resendCode(self, request):
        result = AuthService.resendCode(request.data.get('email'))
        return Response(result['data'], status=result['status']) 

    @action(detail=False, methods=['Post'], url_path='verifyCode')
    def verifyCode(self, request):
        result = AuthService.verifyCode(request.data.get('email'), request.data.get('code'))    
        return Response(result['data'], status=result['status']) 


