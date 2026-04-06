from patients.models import Patient
from users.models import User
from Pregnancies.models import Pregnancy
from dci.models import DCI
from datetime import date


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
            },
            'status': 200
        }
 
    @staticmethod
    def _get_pregnancy_risk(medication_id, user_id):
        """
        Returns pregnancy risk data for a female patient.
        Result dict has either an 'error' key (a full API response dict)
        or 'pregnancy_data' and 'trimester_risk' keys.
        """
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
 