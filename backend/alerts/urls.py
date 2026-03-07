from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import AlertView
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'AlertService', AlertView, basename='AlertService')
urlpatterns = [
    path('', include(router.urls)),
]