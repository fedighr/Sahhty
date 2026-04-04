from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import DCIView
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'DCI', DCIView, basename='DCI')
urlpatterns = [
    path('', include(router.urls)),
]