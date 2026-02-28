from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import UserAuth
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'crud', UserAuth)
urlpatterns = [
    path('', include(router.urls)),
]
