    """
    from django_eventstream import EventResponse
    from rest_framework.viewsets import ViewSet
    from rest_framework.decorators import action
    from rest_framework.permissions import IsAuthenticated, AllowAny
    from django_eventstream.eventresponse import EventResponse
    from django_eventstream.routing import route_eventstream

    class NotificationViewSet(ViewSet):
        
        @action(detail=False, methods=['get'], url_path='stream', permission_classes=[IsAuthenticated])
        def stream(self, request):
            user_id = request.user.id
            request.eventstream_channels = [f'user-{user_id}']
            return EventResponse()
    """
