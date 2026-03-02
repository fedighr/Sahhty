from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import UserAuth
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

router = DefaultRouter()
router.register(r'auth', UserAuth, basename='auth')

urlpatterns = [
    path('', include(router.urls)),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),

]
