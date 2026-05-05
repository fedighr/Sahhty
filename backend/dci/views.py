from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import transaction, IntegrityError, DatabaseError
from .models import DCI
from .serializers import DCISerializer, DCIInteractionSerializer
from users.serializers import EmailSerializer
import os
# .services import DCIService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema
import pandas as pd
from .search import DCISearch

class DCIView(ViewSet):
    @action(detail=False, methods=['post'], url_path="create_dci", permission_classes=[AllowAny])
    def create_dci(self, request):
        try:
            current_folder = os.path.dirname(os.path.abspath(__file__))
            file_path = os.path.join(current_folder, '..', 'sources', 'classifications.csv')
            dataset = pd.read_csv(file_path)

            with transaction.atomic():
                for index, row in dataset.iterrows():
                    print(str(index) + "/" + str(len(dataset)))
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
                        raise Exception(serializer.errors)

            return Response({"message": "DCIs created successfully"}, status=status.HTTP_201_CREATED)

        except FileNotFoundError:
            return Response({"error": "CSV file not found"}, status=status.HTTP_404_NOT_FOUND)
        except IntegrityError as e:
            return Response({"error": f"Database integrity error: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)
        except DatabaseError as e:
            return Response({"error": f"Database error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['post'], url_path="create_dci_interaction", permission_classes=[AllowAny])
    def create_dci_interaction(self, request):
        try:
            current_folder = os.path.dirname(os.path.abspath(__file__))
            file_path = os.path.join(current_folder, '..', 'sources', 'interactions_valid.csv')
            dataset = pd.read_csv(file_path)
            for index, row in dataset.iterrows():
                print(str(index) +"/"+ str(len(dataset)))
                dci1 = get_object_or_404(DCI, name=row['dci_a'])
                dci2 = get_object_or_404(DCI, name=row['dci_b'])
                interaction_data = {
                    'dci1': dci1.id,
                    'dci2': dci2.id,
                    'severity': row['severity'],
                    'description': row['description'] if pd.notna(row['description']) else None
                }
                serializer = DCIInteractionSerializer(data=interaction_data)
                if serializer.is_valid():
                    serializer.save()
                else:
                    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            return Response({"message": "DCI interactions created successfully"}, status=status.HTTP_201_CREATED)

        except FileNotFoundError:
            return Response({"error": "CSV file not found"}, status=status.HTTP_404_NOT_FOUND)
        except Http404:
            return Response({"error": "DCI not found for interaction"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except IntegrityError:
            return Response({"error": "Database integrity error"}, status=status.HTTP_400_BAD_REQUEST)
        except DatabaseError:
            return Response({"error": "Database error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
    @action(detail=False, methods=['post'], url_path="adding_new_dci", permission_classes=[AllowAny])
    def adding_new_dci(self, request):
        current_folder = os.path.dirname(os.path.abspath(__file__))
        unmatched_path = os.path.join(current_folder, '..', 'sources', 'unmatched_dci.csv')
        df = pd.read_csv(unmatched_path)

        unsafe_dci = df['Safe'].to_list()
        have_status = []
        not_found = []
        i=1
        with transaction.atomic():
            for dci_name in unsafe_dci:
                print(f"Processing DCI {i}/{len(unsafe_dci)}: {dci_name}")
                if pd.notna(dci_name):
                    dci_name = dci_name.strip()
                    updated = DCI.objects.filter(name=dci_name, overall_status='UNKNOWN').update(
                        overall_status='SAFE',
                        first_trimester_status='SAFE',
                        second_trimester_status='SAFE',
                        third_trimester_status='SAFE',
                        delivery_status='SAFE',
                        summary='Ce médicament a été classifié comme SÛR selon les dernières données disponibles.',
                        source_url='https://www.vidal.fr'
                    )
                    if updated:
                        have_status.append(dci_name)
                    else:
                        not_found.append(dci_name)
                i += 1

        print(f"DCIs with status: {len(have_status)}")
        for dci_name in have_status:
            print(f" - {dci_name}")
        print(f"DCIs not found in database: {len(not_found)}")
        for dci_name in not_found:
            print(f" - {dci_name}")

        return Response({"message": f"Processed {len(unsafe_dci)} DCIs, {len(have_status)} have statuses."}, status=status.HTTP_200_OK)

    @extend_schema(request=DCISerializer, responses=DCISerializer)
    @action(detail=False, methods=['get'], url_path="search", permission_classes=[AllowAny])
    def search(self, request):
        query = request.query_params.get('q', '').strip()

        if len(query) < 2:
            return Response(
                {'detail': 'Query must be at least 2 characters.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        dci_list = list(DCISearch.search(query)[:20])
        if not dci_list:
            return Response(
                {'detail': 'No DCIs found.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = DCISerializer(dci_list, many=True)
        dci_names = [dci.name for dci in dci_list]
        return Response(dci_names, status=status.HTTP_200_OK)