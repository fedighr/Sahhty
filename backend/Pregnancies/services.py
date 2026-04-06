from django.db.utils import IntegrityError, DatabaseError
from .models import Pregnancy
from .serializers import PregnancySerializer
from datetime import date
from datetime import timedelta


class PregnancyService:
    @staticmethod
    def CreatePregnancy(validated_data):
        try:
            pregnancy = Pregnancy.objects.create(**validated_data)
            serializer = PregnancySerializer(pregnancy)
            return {'data': {'success': True, 'pregnancy': serializer.data}, 'status': 201}
        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def getCurrentPregnancy(patient_id):
        try:
            nine_months_ago = date.today() - timedelta(days=270)
            pregnancy = Pregnancy.objects.filter(
                patient_id=patient_id,
                end_date__isnull=True,
                start_date__gte=nine_months_ago
            ).first()

            if pregnancy:
                day = (date.today() - pregnancy.start_date).days
                week = day // 7

                serializer = PregnancySerializer(pregnancy)
                return {
                    'data': {
                        'success': True,
                        'pregnancy': serializer.data,
                        'day': day,
                        'week': week
                    },
                    'status': 200
                }

            return {
                'data': {
                    'success': False,
                    'message': 'No current pregnancy found for this patient'
                },
                'status': 404
            }

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def updatePregnancy(pregnancy_id, data):
        try:
            pregnancy = Pregnancy.objects.get(pk=pregnancy_id)
        except Pregnancy.DoesNotExist:
            return {'data': {'success': False, 'message': 'Pregnancy not found'}, 'status': 404}

        try:
            serializer = PregnancySerializer(pregnancy, data=data, partial=True)
            if not serializer.is_valid():
                return {'data': {'success': False, 'message': serializer.errors}, 'status': 400}
            serializer.save()
            return {'data': {'success': True, 'pregnancy': serializer.data}, 'status': 200}

        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def deletePregnancy(pregnancy_id):
        try:
            pregnancy = Pregnancy.objects.get(pk=pregnancy_id)
        except Pregnancy.DoesNotExist:
            return {'data': {'success': False, 'message': 'Pregnancy not found'}, 'status': 404}

        try:
            pregnancy.delete()
            return {'data': {'success': True, 'message': 'Pregnancy deleted successfully'}, 'status': 200}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}