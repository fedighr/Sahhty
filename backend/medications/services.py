from .models import Treatment, TreatmentSchedule
from .serializers import TreatmentSerializer, TreatmentScheduleSerializer


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
                'data': {
                    'success': False,
                    'message': 'No treatments found for this patient'
                },
                'status': 404
            }

        return {
            'data': {
                'success': True,
                'treatments': TreatmentSerializer(treatments, many=True).data
            },
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