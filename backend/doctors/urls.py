from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import DoctorView
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'DoctorService', DoctorView, basename='DoctorService')
urlpatterns = [
    path('', include(router.urls)),
]