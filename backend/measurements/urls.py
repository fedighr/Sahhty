from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import MeasurementView
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'MeasurementService', MeasurementView, basename='MeasurementService')
urlpatterns = [
    path('', include(router.urls)),
]