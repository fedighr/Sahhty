import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from rest_framework_simplejwt.tokens import AccessToken
from users.models import User


class NotificationConsumer(AsyncWebsocketConsumer):

    async def connect(self):
        try:
            # Get token from query string: ws://localhost:8000/ws/notifications/?token=xxx
            token = self.scope['query_string'].decode().split('token=')[1]
            user = await self.get_user_from_token(token)

            if user is None:
                await self.close()
                return

            self.user = user
            self.group_name = f'notifications_{user.id}'

            # Join user's notification group
            await self.channel_layer.group_add(
                self.group_name,
                self.channel_name
            )

            await self.accept()

        except Exception:
            await self.close()

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        # We don't expect messages from client, just keep connection alive
        pass

    async def send_notification(self, event):
        await self.send(text_data=json.dumps(event['data']))

    @database_sync_to_async
    def get_user_from_token(self, token):
        try:
            validated_token = AccessToken(token)
            user_id = validated_token['user_id']
            return User.objects.get(id=user_id)
        except Exception:
            return None