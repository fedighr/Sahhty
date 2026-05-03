from users.models import User
from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action, permission_classes
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError, transaction
from .models import Medication, MedicationDci, Treatment, TreatmentSchedule
from patients.models import Patient
from .serializers import MedicationSerializer, TreatmentSerializer, TreatmentWithSchedulesSerializer
from users.serializers import EmailSerializer
from .search import MedicationSearch
import os
import re
from .services import TreatmentService, MedicationService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema
import pandas as pd
from dci.models import DCI
from dci.serializers import DCISerializer


def extract_dci_names(raw_dci, special_dcis):
    raw_dci = raw_dci.strip()
    upper_dci = raw_dci.upper()

    if upper_dci in special_dcis:
        return [raw_dci]

    if upper_dci.startswith('VACCIN :') or upper_dci.startswith('VACCIN:'):
        parts = re.split(r'\+', raw_dci)
        result = []
        for part in parts:
            part = part.strip()
            cleaned = re.sub(r'(?i)vaccin\s*:\s*', '', part).strip()
            if cleaned:
                result.append(cleaned)
        return result

    if re.search(r'[+/]', raw_dci):
        parts = re.split(r'[+/]', raw_dci)
        result = []
        for part in parts:
            part = part.strip()
            if not part:
                continue
            part_upper = part.upper()
            if part_upper in special_dcis:
                result.append(part)
            elif re.search(r'[-:]', part):
                sub = re.split(r'[-:]', part, maxsplit=1)
                result.append(sub[-1].strip())
            else:
                result.append(part)
        return result

    if re.search(r'[-:]', raw_dci):
        if upper_dci in special_dcis:
            return [raw_dci]
        parts = re.split(r'[-:]', raw_dci, maxsplit=1)
        return [parts[-1].strip()]

    return [raw_dci]

def safe_get(row, key):
    val = row.get(key, None)
    return val if pd.notna(val) else None

class MedicationView(ViewSet):
    @action(detail=False, methods=['post'], url_path="create_medications", permission_classes=[AllowAny])
    def create_medications(self, request):
        try:
            current_folder = os.path.dirname(os.path.abspath(__file__))
            file_path = os.path.join(current_folder, '..', 'sources', 'new_medications.csv')
            dataset = pd.read_csv(file_path)
            with transaction.atomic():
                for index, row in dataset.iterrows():
                    print(str(index) +"/"+ str(len(dataset)))
                    medication_data = {
                        'code': safe_get(row, 'CODE_PCT'),
                        'name': safe_get(row, 'NAME_MAIN'),
                        'commercial_name': safe_get(row, 'NAME_MAIN'),
                        'form': safe_get(row, 'FORM'),
                        'dosage': safe_get(row, 'STRENGTH'),
                        'package': safe_get(row, 'PACKAGE'),
                        'public_price': safe_get(row, 'PRIX_PUBLIC'),
                        'tarif_reference': safe_get(row, 'TARIF_REFERENCE'),
                        'category': safe_get(row, 'CATEGORIE'),
                        'dci': safe_get(row, 'DCI'),
                        'prior_approval': safe_get(row, 'AP'),
                    }
                    serializer = MedicationSerializer(data=medication_data)
                    if serializer.is_valid():
                        serializer.save()
                    else:
                        raise Exception(serializer.errors)
            return Response({"message": "Medications created successfully"}, status=status.HTTP_201_CREATED)
        
        except FileNotFoundError:
            return Response({"error": "CSV file not found"}, status=status.HTTP_404_NOT_FOUND)
        except IntegrityError:
            return Response({"error": "Database integrity error"}, status=status.HTTP_400_BAD_REQUEST)
        except DatabaseError:
            return Response({"error": "Database error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['post'], url_path="create_medications_dci", permission_classes=[AllowAny])
    def create_medications_dci(self, request):
        try:
            current_folder = os.path.dirname(os.path.abspath(__file__))
            special_dci_path = os.path.join(current_folder, '..', 'sources', 'special_DCI.txt')
            
            with open(special_dci_path, 'r', encoding='utf-8') as f:
                special_dcis = set(line.strip().upper() for line in f if line.strip())

            medications = Medication.objects.values('id', 'dci')
            total = medications.count()
            not_found = []

            for i, value in enumerate(medications, start=1):
                print(f"{i}/{total}")

                raw_dci = value['dci'] or ''
                if not raw_dci:
                    continue

                dci_names = extract_dci_names(raw_dci, special_dcis)

                for dci_name in dci_names:
                    try:
                        dci_obj = DCI.objects.get(name__iexact=dci_name)
                        MedicationDci.objects.get_or_create(
                            medication_id=value['id'],
                            dci=dci_obj
                        )
                    except DCI.DoesNotExist:
                        not_found.append({'medication_id': value['id'], 'dci_name': dci_name})
                    except DCI.MultipleObjectsReturned:
                        not_found.append({'medication_id': value['id'], 'dci_name': f"DUPLICATE: {dci_name}"})

            if not_found:
                return Response({
                    "message": "Completed with some unmatched DCIs",
                    "unmatched": not_found
                }, status=status.HTTP_207_MULTI_STATUS)

            return Response({"message": "Medication-DCI relationships created successfully"}, status=status.HTTP_201_CREATED)

        except FileNotFoundError:
            return Response({"error": "special_DCI.txt file not found"}, status=status.HTTP_404_NOT_FOUND)
        except IntegrityError:
            return Response({"error": "Database integrity error"}, status=status.HTTP_400_BAD_REQUEST)
        except DatabaseError:
            return Response({"error": "Database error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        

    @action(detail=False, methods=['post'], url_path='create_treatment_with_schedules', permission_classes=[AllowAny])
    def create_treatment_with_schedules(self, request):
        if not request.data:
            return Response({'success': False, 'message': 'No data provided'}, status=400)
        
        try:
            serializer = TreatmentWithSchedulesSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            result = TreatmentService.create_treatment_with_schedules(
                treatment_data=serializer.validated_data['treatment'],
                schedules_data=serializer.validated_data['schedules']
            )

            return Response(result['data'], status=result['status'])
        
        except IntegrityError:
            return Response({'success': False, 'message': 'Invalid data or constraint violated'}, status=status.HTTP_400_BAD_REQUEST)
        
        except DatabaseError:
            return Response({'success': False, 'message': 'Database error occurred'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        except Exception as e:
            return Response({'success': False, 'message': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    
    @action(detail=True, methods=['get'], url_path='get_treatments_by_patient_id', permission_classes=[AllowAny])
    def get_treatments_by_patient_id(self, request, pk=None):
        result = TreatmentService.getTreatmentByPatientId(pk)
        return Response(result['data'], status=result['status'])


    @action(detail=True, methods=['patch'], url_path='update_schedule_by_id', permission_classes=[AllowAny])
    def update_schedule_by_id(self, request, pk=None):
        new_time = request.data.get('new_time')

        if not new_time:
            return Response({'success': False, 'message': 'new_time is required'}, status=status.HTTP_400_BAD_REQUEST)

        result = TreatmentService.updateScheduleById(pk, new_time)
        return Response(result['data'], status=result['status'])


    @action(detail=True, methods=['delete'], url_path='delete_treatment_by_id', permission_classes=[AllowAny])
    def delete_treatment_by_id(self, request, pk=None):
        result = TreatmentService.deleteTreatmentById(pk)
        return Response(result['data'], status=result['status'])
    

    @action(detail=True, methods=['delete'], url_path='delete_schedule_by_id', permission_classes=[AllowAny])
    def delete_schedule_by_id(self, request, pk=None):
        result = TreatmentService.deleteScheduleById(pk)
        return Response(result['data'], status=result['status'])


    @action(detail=True, methods=['get'], url_path='get_medication_by_id', permission_classes=[AllowAny])  
    def get_medication_by_id(self, request, pk=None):
        user_id = request.user.id if request.user.is_authenticated else None
        if(user_id is None):
            return Response({'success': False, 'message': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
        
        if(not User.objects.filter(id=user_id).exists()):
            return Response({'success': False, 'message': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        results = MedicationService.getMedicationById(pk, user_id)
        return Response(results['data'], status=results['status'])


    @action(detail=False, methods=['get'], url_path="search", permission_classes=[AllowAny])
    def search(self, request):
        query = request.query_params.get('q', '').strip()

        if len(query) < 2:
            return Response(
                {'detail': 'Query must be at least 2 characters.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        medications = list(MedicationSearch.search(query)[:20])
        if not medications:
            return Response(
                {'detail': 'No medications found.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = MedicationSerializer(medications, many=True)

        return Response({
            'count': len(medications),
            'results': serializer.data
        })


    
