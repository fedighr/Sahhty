from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import PatientAuth
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'PatientAuth', PatientAuth, basename='PatientAuth')
urlpatterns = [
    path('', include(router.urls)),
]