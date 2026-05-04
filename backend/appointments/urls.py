from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import AppointmentView
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'AppointmentService', AppointmentView, basename='AppointmentService')

urlpatterns = [
    path('', include(router.urls)),
]