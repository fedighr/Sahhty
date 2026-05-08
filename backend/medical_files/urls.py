from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import MedicalFileView

router = DefaultRouter()
router.register(r'MedicalFileService', MedicalFileView, basename='MedicalFileService')
urlpatterns = [
    path('', include(router.urls)),
]