from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import PregnancyView

router = DefaultRouter()
router.register(r'PregnancyService', PregnancyView, basename='PregnancyService')

urlpatterns = [
    path('', include(router.urls)),
]
