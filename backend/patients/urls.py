from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import PatientView
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'PatientService', PatientView, basename='PatientService')
urlpatterns = [
    path('', include(router.urls)),
]