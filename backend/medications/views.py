from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.db import IntegrityError, DatabaseError
from .models import Medication, MedicationDci
from .serializers import MedicationSerializer
from users.serializers import EmailSerializer
import os
import re
# .services import MedicationService
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from drf_spectacular.utils import extend_schema
import pandas as pd
from dci.models import DCI
from dci.serializers import DCISerializer

class MedicationView(ViewSet):
    @action(detail=False, methods=['post'], url_path="create_medications", permission_classes=[AllowAny])
    def create_medications(self, request):
        try:
            current_folder = os.path.dirname(os.path.abspath(__file__))
            file_path = os.path.join(current_folder, '..', 'sources', 'MED_CNAM.csv')
            dataset = pd.read_csv(file_path)
            for index, row in dataset.iterrows():
                print(str(index) +"/"+ str(len(dataset)))
                medication_data = {
                    'code': row['CODE_PCT'],
                    'name': row['NAME_MAIN'] if pd.notna(row['NAME_MAIN']) else None,
                    'commercial_name': row['NOM_COMMERCIAL'] if pd.notna(row['NOM_COMMERCIAL']) else None,
                    'form': row['FORM'] if pd.notna(row['FORM']) else None,
                    'dosage': row['STRENGTH'] if pd.notna(row['STRENGTH']) else None,
                    'package': row['PACKAGE'] if pd.notna(row['PACKAGE']) else None,
                    'public_price': row['PRIX_PUBLIC'] if pd.notna(row['PRIX_PUBLIC']) else None,
                    'tarif_reference': row['TARIF_REFERENCE'] if pd.notna(row['TARIF_REFERENCE']) else None,
                    'category': row['CATEGORIE'] if pd.notna(row['CATEGORIE']) else None,
                    'dci': row['DCI'] if pd.notna(row['DCI']) else None,
                    'prior_approval': row['AP'] if pd.notna(row['AP']) else None,
                    
                    }
                serializer = MedicationSerializer(data=medication_data)
                if serializer.is_valid():
                    serializer.save()
                else:
                    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            return Response({"message": "Medications created successfully"}, status=status.HTTP_201_CREATED)
        
        except FileNotFoundError:
            return Response({"error": "CSV file not found"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except IntegrityError:
            return Response({"error": "Database integrity error"}, status=status.HTTP_400_BAD_REQUEST)
        except DatabaseError:
            return Response({"error": "Database error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

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

            def extract_dci_names(raw_dci):
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

            for i, value in enumerate(medications, start=1):
                print(f"{i}/{total}")

                raw_dci = value['dci'] or ''
                if not raw_dci:
                    continue

                dci_names = extract_dci_names(raw_dci)

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
        


