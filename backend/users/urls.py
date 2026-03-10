from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import UserAuth, FCMDeviceView
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

router = DefaultRouter()
router.register(r'auth', UserAuth, basename='auth')
router.register(r'devices', FCMDeviceView, basename='devices')

urlpatterns = [
    path('', include(router.urls)),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
