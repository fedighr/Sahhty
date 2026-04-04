from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import DCI
from .serializers import DCISerializer
from users.serializers import EmailSerializer
import os
# .services import DCIService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema
import pandas as pd

class DCIView(ViewSet):
    @action(detail=False, methods=['post'], url_path="create_dci", permission_classes=[AllowAny])
    def create_dci(self, request):
        try:
            current_folder = os.path.dirname(os.path.abspath(__file__))
            file_path = os.path.join(current_folder, '..', 'sources', 'classifications.csv')
            dataset = pd.read_csv(file_path)
            for index, row in dataset.iterrows():
                print(str(index) +"/"+ str(len(dataset)))
                dci_data = {
                    'name': row['dci_name'],
                    'overall_status': row['overall_status'],
                    'first_trimester_status': row['trimester_details/T1'],
                    'second_trimester_status': row['trimester_details/T2'],
                    'third_trimester_status': row['trimester_details/T3'],
                    'delivery_status': row['trimester_details/DELIVERY'],
                    'summary': row['summary'] if pd.notna(row['summary']) else None,
                    'source_url': row['source_url'] if pd.notna(row['source_url']) else None
                }
                serializer = DCISerializer(data=dci_data)
                if serializer.is_valid():
                    serializer.save()
                else:
                    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            return Response({"message": "DCIs created successfully"}, status=status.HTTP_201_CREATED)
        
        except FileNotFoundError:
            return Response({"error": "CSV file not found"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except IntegrityError:
            return Response({"error": "Database integrity error"}, status=status.HTTP_400_BAD_REQUEST)
        except DatabaseError:
            return Response({"error": "Database error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
