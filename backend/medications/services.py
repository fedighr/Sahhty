from patients.models import Patient
from users.models import User
from Pregnancies.models import Pregnancy
from dci.models import DCI, DciInteraction
from dci.serializers import DCISerializer, DCIInteractionSerializer
from datetime import date
import re
import os
from django.db.models import Q
from .models import Medication, Treatment, TreatmentSchedule, MedicationDci
from .serializers import TreatmentSerializer, TreatmentScheduleSerializer, MedicationSerializer
from patients.serializers import PatientSerializer


def current_trimester(start_date):
    if not start_date:
        return None
 
    days = (date.today() - start_date).days
    if days < 0:
        return None
 
    weeks = days // 7
 
    if 0 <= weeks <= 13:
        return "T1"
    elif 14 <= weeks <= 27:
        return "T2"
    elif weeks <= 42:
        return "T3"
    else:
        return None

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

class TreatmentService:

    @staticmethod
    def create_treatment_with_schedules(treatment_data, schedules_data):
        treatment = Treatment.objects.create(**treatment_data)

        schedules = TreatmentSchedule.objects.bulk_create([
            TreatmentSchedule(
                treatment=treatment,
                dose_time=schedule['dose_time']
            )
            for schedule in schedules_data
        ])

        return {
            'data': {
                'success': True,
                'message': 'Treatment created successfully',
                'treatment': TreatmentSerializer(treatment).data,
                'schedules': TreatmentScheduleSerializer(schedules, many=True).data
            },
            'status': 201
        }
    
    @staticmethod
    def getTreatmentByPatientId(patient_id):
        treatments = Treatment.objects.filter(patient_id=patient_id).prefetch_related('schedules')

        if not treatments.exists():
            return {
                'data': {'success': False, 'message': 'No treatments found for this patient'},
                'status': 404
            }

        treatments_schedules = {}
        for treatment in treatments:
            med_result = MedicationService.getMedicationById(
                medication_id=treatment.medication_id,
                user_id=treatment.patient.user_id
            )
            success = med_result and med_result['data']['success']

            treatments_schedules[f"treatment_{treatment.id}"] = {
                'id':           treatment.id,
                'start_date':   treatment.start_date,
                'end_date':     treatment.end_date,
                'dose':         treatment.dose,
                'frequency':    treatment.frequency,
                'patient_id':   treatment.patient_id,
                'schedules':    [
                    {'id': s.id, 'dose_time': s.dose_time, 'last_sent_at': s.last_sent_at}
                    for s in treatment.schedules.all()
                ],
                'medication':       med_result['data']['medication'] if success else None,
                'pregnancy_data':   med_result['data']['pregnancy_data'] if success else None,
                'interactions':     med_result['data']['medication_interactions'] if success else None,
            }

        return {
            'data': {'success': True, 'treatments': treatments_schedules},
            'status': 200
        }
    
    @staticmethod
    def updateScheduleById(schedule_id, new_dose_time):
        try:
            schedule = TreatmentSchedule.objects.get(id=schedule_id)
            schedule.dose_time = new_dose_time
            schedule.save()
            return {
                'data': {
                    'success': True,
                    'message': 'Schedule updated successfully',
                    'schedule': TreatmentScheduleSerializer(schedule).data
                },
                'status': 200
            }
        except TreatmentSchedule.DoesNotExist:
            return {
                'data': {
                    'success': False,
                    'message': 'Schedule not found'
                },
                'status': 404
            }
        
        except Exception as e:
            return {
                'data': {
                    'success': False,
                    'message': str(e)
                },
                'status': 500
            }
        
    @staticmethod
    def deleteTreatmentById(treatment_id):
        try:
            treatment = Treatment.objects.get(id=treatment_id)
            treatment.delete()
            return {
                'data': {
                    'success': True,
                    'message': 'Treatment deleted successfully'
                },
                'status': 200
            }
        except Treatment.DoesNotExist:
            return {
                'data': {
                    'success': False,
                    'message': 'Treatment not found'
                },
                'status': 404
            }
        
        except Exception as e:
            return {
                'data': {
                    'success': False,
                    'message': str(e)
                },
                'status': 500
            }
        
    @staticmethod
    def deleteScheduleById(schedule_id):
        try:
            schedule = TreatmentSchedule.objects.get(id=schedule_id)
            schedule.delete()
            return {
                'data': {
                    'success': True,
                    'message': 'Schedule deleted successfully'
                },
                'status': 200
            }
        except TreatmentSchedule.DoesNotExist:
            return {
                'data': {
                    'success': False,
                    'message': 'Schedule not found'
                },
                'status': 404
            }
        
        except Exception as e:
            return {
                'data': {
                    'success': False,
                    'message': str(e)
                },
                'status': 500
            }

class MedicationService:
 
    @staticmethod
    def getMedicationById(medication_id, user_id):
        pregnancy_data = None
        trimester_risk = None
        patient_allergy = Patient.objects.get(user=user_id).allergies if Patient.objects.filter(user_id=user_id).exists() else None

        try:
            medication = Medication.objects.get(id=medication_id)
        except Medication.DoesNotExist:
            return {
                'data': {'success': False, 'message': 'Medication not found'},
                'status': 404
            }

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return {
                'data': {'success': False, 'message': 'User not found'},
                'status': 404
            }

        interaction_result = MedicationService.get_medication_interactions(medication.name, medication.dci, user_id)
        medication_interactions = interaction_result.get('interactions', []) if interaction_result.get('success') else []
        allergy_interactions = MedicationService.get_allergy_interactions(medication, patient_allergy) if patient_allergy else []

        if user.gender == 'F':
            result = MedicationService._get_pregnancy_risk(medication_id, user_id)
            if result.get('error'):
                return result['error']
            pregnancy_data = result.get('pregnancy_data')
            trimester_risk = result.get('trimester_risk')
            

        return {
            'data': {
                'success': True,
                'medication': MedicationSerializer(medication).data,
                'pregnancy_data': pregnancy_data,
                'medication_interactions': medication_interactions,
                'allergy_interactions': allergy_interactions
            },
            'status': 200
        }
 
    @staticmethod
    def _get_pregnancy_risk(medication_id, user_id):
        patient = Patient.objects.filter(user_id=user_id).first()
        if not patient:
            return {'error': {
                'data': {'success': False, 'message': 'Patient not found'},
                'status': 404
            }}
 
        pregnancy = Pregnancy.objects.filter(
            patient=patient, end_date__isnull=True
        ).first()
        if not pregnancy:
            return {'error': {
                'data': {'success': False, 'message': 'No active pregnancy found for this patient'},
                'status': 404
            }}
 
        trimester = current_trimester(pregnancy.start_date)
        if trimester is None:
            return {'error': {
                'data': {'success': False, 'message': 'Unable to determine current trimester'},
                'status': 400
            }}
 
        dci_links = MedicationDci.objects.filter(
            medication=medication_id
        ).select_related('dci')
 
        if not dci_links.exists():
            return {
                'pregnancy_data': None,
                'trimester_risk': None
            }
 
        risk_rank = {"UNSAFE": 4, "CAUTION": 3, "SAFE": 2, "NOT_APPLICABLE": 1, "UNKNOWN": 0}
        worst_risk = None
 
        for link in dci_links:
            dci = link.dci
 
            candidate = {
                "overall":    dci.overall_status,
                "T1":         dci.first_trimester_status,
                "T2":         dci.second_trimester_status,
                "T3":         dci.third_trimester_status,
                "Delivery":   dci.delivery_status,
                "summary":    dci.summary,
                "source_url": dci.source_url,
            }
 
            if worst_risk is None:
                worst_risk = candidate
            else:
                for field in ["overall", "T1", "T2", "T3", "Delivery"]:
                    if risk_rank.get(candidate[field], 0) > risk_rank.get(worst_risk[field], 0):
                        worst_risk[field] = candidate[field]
                if risk_rank.get(candidate["overall"], 0) > risk_rank.get(worst_risk["overall"], 0):
                    worst_risk["summary"] = candidate["summary"]
                    worst_risk["source_url"] = candidate["source_url"]
 
        trimester_risk = worst_risk.get(trimester) if worst_risk else None
 
        pregnancy_data = {
            "dci_risk":         worst_risk,
            "trimester_risk":   trimester_risk,
            "current_trimester": trimester,
        }
 
        return {
            'pregnancy_data': pregnancy_data,
            'trimester_risk': trimester_risk
        }

    @staticmethod
    def get_medication_interactions(medication_name, medication_dci, user_id):
        if not medication_dci:
            return {'success': False, 'message': 'No DCI provided'}

        patient = Patient.objects.filter(user_id=user_id).first()
        if not patient:
            return {'success': False, 'message': 'Patient not found'}

        try:
            current_folder = os.path.dirname(os.path.abspath(__file__))
            special_dci_path = os.path.join(current_folder, '..', 'sources', 'special_DCI.txt')
            with open(special_dci_path, 'r', encoding='utf-8') as f:
                special_dcis = set(line.strip().upper() for line in f if line.strip())
        except FileNotFoundError:
            return {'success': False, 'message': 'special_DCI.txt not found'}

        raw_medication_dcis = extract_dci_names(medication_dci, special_dcis)
        if not raw_medication_dcis:
            return {'success': False, 'message': 'Could not extract DCI names'}

        dcis_id = set(DCI.objects.filter(name__in=raw_medication_dcis).values_list('id', flat=True))
        if not dcis_id:
            return {'success': False, 'message': 'No matching DCIs found in database'}

        user_medication_dcis = (
            Treatment.objects.filter(patient=patient)
            .select_related('medication')
            .values_list('medication__dci', 'medication__name')
        )

        all_user_dci_ids = []
        dci_id_to_med_name = {}

        for med_dci, med_name in user_medication_dcis:
            if not med_dci:
                continue
            if med_name == medication_name:
                continue
            raw_dci = extract_dci_names(med_dci, special_dcis)
            user_dci_ids = list(DCI.objects.filter(name__in=raw_dci).values_list('id', flat=True))
            for dci_id in user_dci_ids:
                if dci_id in dcis_id:
                    continue
                all_user_dci_ids.append(dci_id)
                dci_id_to_med_name[dci_id] = med_name

        if not all_user_dci_ids:
            return {'success': True, 'interactions': [], 'message': 'No interactions found with current medications.'}

        interactions = DciInteraction.objects.filter(
            (Q(dci1_id__in=dcis_id) & Q(dci2_id__in=all_user_dci_ids)) |
            (Q(dci2_id__in=dcis_id) & Q(dci1_id__in=all_user_dci_ids))
        ).select_related('dci1', 'dci2')

        seen = set()
        risk_med = []

        for interaction in interactions:
            pair = frozenset([interaction.dci1_id, interaction.dci2_id])
            if pair in seen:
                continue
            seen.add(pair)

            if interaction.dci2_id in all_user_dci_ids:
                user_med_name = dci_id_to_med_name.get(interaction.dci2_id, 'Unknown')
            else:
                user_med_name = dci_id_to_med_name.get(interaction.dci1_id, 'Unknown')

            risk_med.append({
                'searched_medication': medication_name,
                'user_medication': user_med_name,
                'interaction': interaction.description,
                'severity': interaction.severity,
                'dci1': interaction.dci1.name,
                'dci2': interaction.dci2.name,
            })

        if not risk_med:
            return {'success': True, 'interactions': [], 'message': 'No interactions found with current medications.'}

        return {'success': True, 'interactions': risk_med}

    def get_allergy_interactions(medication, allergy):
        current_folder = os.path.dirname(os.path.abspath(__file__))
        special_dci_path = os.path.join(current_folder, '..', 'sources', 'special_DCI.txt')
        with open(special_dci_path, 'r', encoding='utf-8') as f:
            special_dcis = set(line.strip().upper() for line in f if line.strip())
        raw_medication_dcis = extract_dci_names(medication.dci, special_dcis)
        if not raw_medication_dcis:
            return []
        if(allergy.upper() in raw_medication_dcis):
                return [{'medication': medication.name, 'allergy': allergy, 'message': 'This medication contains a substance you are allergic to.'}]
        
        return []