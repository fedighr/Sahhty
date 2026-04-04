from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import MedicationView
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'medicationsService', MedicationView, basename='medicationsService')
urlpatterns = [
    path('', include(router.urls)),
]