from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import User, FCMDevice
from .serializers import UserSerializer, LoginSerializer, EmailSerializer, PhoneSerializer, FCMDeviceSerializer
from .services import AuthService
from utils.constraints import IsOwnerOrAdmin
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema

class UserAuth(ViewSet):
    @extend_schema(request=UserSerializer, responses=UserSerializer)
    @action(detail=False, methods=['post'], url_path='signup', permission_classes=[AllowAny])
    def signup(self, request):
        print(request.data)
        serializer = UserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.register(serializer.validated_data)
        return Response(result['data'], status=result['status'])
    
    
    @extend_schema(request=LoginSerializer, responses=LoginSerializer)
    @action(detail=False, methods=['post'], url_path='signin', permission_classes=[AllowAny])
    def signin(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.login(serializer.validated_data)
        return Response(result['data'], status=result['status'])

    
    @extend_schema(request=EmailSerializer, responses=EmailSerializer)
    @action(detail=False, methods=['post'], url_path="resend_code", permission_classes=[AllowAny])
    def resend_code(self, request):
        serializer = EmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.resendCode(serializer.validated_data.get('email'))
        return Response(result['data'], status=result['status']) 

    @extend_schema(request=EmailSerializer, responses=EmailSerializer)
    @action(detail=False, methods=['post'], url_path='verify_reset_code', permission_classes=[AllowAny])
    def verify_reset_code(self, request):
        serializer = EmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)        
        result = AuthService.verifyResetCode(serializer.validated_data.get('email'), request.data.get('code'))    
        return Response(result['data'], status=result['status']) 

    @extend_schema(request=EmailSerializer, responses=EmailSerializer)
    @action(detail=False, methods=['post'], url_path='verify_code', permission_classes=[AllowAny])
    def verify_code(self, request):
        serializer = EmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)        
        result = AuthService.verifyCode(serializer.validated_data.get('email'), request.data.get('code'))    
        return Response(result['data'], status=result['status'])    

    @extend_schema(request=EmailSerializer, responses=EmailSerializer)
    @action(detail=False, methods=['post'], url_path="is_email_available", permission_classes=[AllowAny])
    def is_email_available(self, request):
        serializer = EmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.verifyEmailAvailable(serializer.validated_data.get('email'))
        return Response(result['data'], status=result['status'])

    @extend_schema(request=EmailSerializer, responses=EmailSerializer)
    @action(detail=False, methods=['post'], url_path="verify_reset_email", permission_classes=[AllowAny])
    def verify_reset_email(self, request):
        serializer = EmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.verifyResetEmail(serializer.validated_data.get('email'))
        return Response(result['data'], status=result['status'])    

    @extend_schema(request=PhoneSerializer, responses=PhoneSerializer)
    @action(detail=False, methods=['post'], url_path='verify_phone', permission_classes=[AllowAny])
    def verify_phone(self, request):
        serializer = PhoneSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.verifyPhone(serializer.validated_data.get('phone'))
        return Response(result['data'], status=result['status'])

    @extend_schema(request=LoginSerializer, responses=LoginSerializer)
    @action(detail=False, methods=['post'], url_path='forget_password', permission_classes=[AllowAny])
    def forget_password(self,request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = AuthService.forgetPassword(serializer.validated_data)
        return Response(result['data'], status=result['status'])
    
    @extend_schema(request=UserSerializer, responses=UserSerializer)
    @action(detail=True, methods=['delete'], url_path='delete_account', permission_classes=[IsAuthenticated, IsOwnerOrAdmin])
    def delete_account(self, request, pk=None):
        try:
            target_user = get_object_or_404(User, id=pk)
            self.check_object_permissions(request, target_user)
            result = AuthService.delete_user_account(target_user)
            return Response(result['data'], status=result['status'])
        
        except Http404:
            return Response({'success' : False ,'message' : 'User does not exist'}, status=status.HTTP_404_NOT_FOUND)
        
        except Exception as e:
            return Response({'success' : False ,'message' : str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        

class FCMDeviceView(ViewSet):
    @extend_schema(request=FCMDeviceSerializer, responses=FCMDeviceSerializer)
    @action(detail=False, methods=['post'], url_path='register_device', permission_classes=[IsAuthenticated])
    def register_device(self, request):
        try:
            token = request.data.get('fcm_token')

            if not token:
                return Response(
                    {'success': False, 'message': 'fcm_token is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            if not isinstance(token, str) or len(token.strip()) == 0:
                return Response(
                    {'success': False, 'message': 'fcm_token must be a non-empty string'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            serializer = FCMDeviceSerializer(data=request.data)
            if not serializer.is_valid():
                return Response(
                    {'success': False, 'message': 'Invalid data', 'errors': serializer.errors},
                    status=status.HTTP_400_BAD_REQUEST
                )

            FCMDevice.objects.update_or_create(
                user=request.user,
                defaults={'fcm_token': token.strip()}
            )

            return Response(
                {'success': True, 'message': 'Device registered successfully'},
                status=status.HTTP_200_OK
            )

        except IntegrityError as e:
            return Response(
                {'success': False, 'message': 'Device registration conflict, token may already be in use', 'error': str(e)},
                status=status.HTTP_409_CONFLICT
            )

        except DatabaseError as e:
            return Response(
                {'success': False, 'message': 'A database error occurred, please try again later', 'error': str(e)},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        except Exception as e:
            return Response(
                {'success': False, 'message': 'An unexpected error occurred', 'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
