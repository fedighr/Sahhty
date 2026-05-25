from utils.email_service import send_verification_email
from utils.otp_service import OTPService
from utils.constraints import CheckConstraint
from .models import Patient, MenstrualCycle, PeriodEntry

from .serializers import PatientSerializer, MenstrualCycleSerializer, PeriodEntrySerializer
from users.serializers import UserSerializer
from users.models import User
from datetime import date
from django.db import IntegrityError, DatabaseError


class PatientService:

    @staticmethod
    def createPatient(data):
            try:
                data = dict(data)

                email = data.pop('email', None)
                menstrual_cycle_data = data.pop('menstrual_cycle', None)

                user = User.objects.filter(email=email).first()
                if not user:
                    return {'data': {'success': False, 'message': 'User not found'}, 'status': 404}

                if hasattr(user, 'patient'):
                    return {'data': {'success': False, 'message': 'Patient already exists'}, 'status': 400}

                patient = Patient.objects.create(user=user, **data)

                if menstrual_cycle_data and user.gender == 'F':                                                                        
                    MenstrualCycle.objects.create(patient=patient, **menstrual_cycle_data)

                return {'data': {'success': True, 'message': 'Patient created successfully', 'patient_id': patient.id}, 'status': 201}

            except Exception as e:
                return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def getPatientById(patient_id):
        try:
            patient = Patient.objects.select_related('user', 'menstrual_cycle').get(id=patient_id)
        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}

        try:
            cycle_menstrual = None
            if patient.user.gender == 'F':
                try:
                    cycle_menstrual = patient.menstrual_cycle
                except Exception:
                    cycle_menstrual = None

            today = date.today()
            birth_date = patient.user.birth_date
            if birth_date:
                age = today.year - birth_date.year
                if (today.month, today.day) < (birth_date.month, birth_date.day):
                    age -= 1
            else:
                age = None

            data = {
                'first_name': patient.user.first_name,
                'last_name': patient.user.last_name,
                'email': patient.user.email,
                'birth_date': patient.user.birth_date,
                'age' : age,
                'phone': patient.user.phone,
                'gender': patient.user.gender,
                'height': patient.height,
                'weight': patient.weight,
                'blood_type': patient.blood_type,
                'chronic_diseases': patient.chronic_diseases,
                'allergies': patient.allergies,
                'current_medications': patient.current_medications,
                'family_doctor_name': patient.family_doctor_name,
            }

            if patient.user.gender == 'F':
                data['menstrual_cycle'] = {
                    'menstrual_status': cycle_menstrual.menstrual_status if cycle_menstrual else None,
                    'start_date': cycle_menstrual.start_date if cycle_menstrual else None,
                    'end_date': cycle_menstrual.end_date if cycle_menstrual else None,
                    'cycle_length': (cycle_menstrual.end_date - cycle_menstrual.start_date).days
                        if cycle_menstrual and cycle_menstrual.start_date and cycle_menstrual.end_date else None,
                }

            return {'data': {'success': True, 'patient': data}, 'status': 200}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}      

    @staticmethod
    def updatePatient(patient_id, data):
        try:
            patient = Patient.objects.select_related('user').get(pk=patient_id)
        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}

        try:
            patient_serializer = PatientSerializer(patient, data=data, partial=True)
            if not patient_serializer.is_valid():
                return {'data': {'success': False, 'message': patient_serializer.errors}, 'status': 400}
            patient_serializer.save()

            user_serializer = UserSerializer(patient.user, data=data, partial=True)
            if not user_serializer.is_valid():
                return {'data': {'success': False, 'message': user_serializer.errors}, 'status': 400}
            user_serializer.save()

            return {'data': {'success': True, 'message': 'Patient updated successfully'}, 'status': 200}

        except IntegrityError as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}

        except DatabaseError:
            return {'data': {'success': False, 'message': 'Database error occurred'}, 'status': 500}

        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def getMenstrualCycle(patient_id):
        try:
            patient = Patient.objects.get(pk=patient_id)
            if patient.user.gender != 'F':
                return {'data': {'success': False, 'message': 'Patient is not female'}, 'status': 400}
            
            cycle = MenstrualCycle.objects.filter(patient=patient).first()
            if not cycle:
                return {'data': {'success': False, 'message': 'Menstrual cycle not found'}, 'status': 404}
            
            serializer = MenstrualCycleSerializer(cycle)
            return {'data': {'success': True, 'menstrual_cycle': serializer.data}, 'status': 200}
        
        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}


    @staticmethod
    def updateMenstrualCycle(patient_id, data):
        try:
            patient = Patient.objects.get(pk=patient_id)
            if patient.user.gender != 'F':
                return {'data': {'success': False, 'message': 'Patient is not female'}, 'status': 400}

            cycle = MenstrualCycle.objects.filter(patient=patient).first()
            if not cycle:
                return {'data': {'success': False, 'message': 'Menstrual cycle not found'}, 'status': 404}

            serializer = MenstrualCycleSerializer(cycle, data=data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return {'data': {'success': True, 'message': 'Menstrual cycle updated', 'menstrual_cycle': serializer.data}, 'status': 200}

        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}


    @staticmethod
    def logPeriod(patient_id, data):
        try:
            patient = Patient.objects.get(pk=patient_id)
            if patient.user.gender != 'F':
                return {'data': {'success': False, 'message': 'Patient is not female'}, 'status': 400}

            cycle = MenstrualCycle.objects.filter(patient=patient).first()
            if not cycle:
                return {'data': {'success': False, 'message': 'Menstrual cycle not found'}, 'status': 404}

            # check if there's already an active period
            active_period = PeriodEntry.objects.filter(menstrual_cycle=cycle, end_date__isnull=True).first()
            if active_period:
                return {'data': {'success': False, 'message': 'There is already an active period, end it first'}, 'status': 400}

            serializer = PeriodEntrySerializer(data=data)
            serializer.is_valid(raise_exception=True)
            period = PeriodEntry.objects.create(menstrual_cycle=cycle, **serializer.validated_data)
            return {'data': {'success': True, 'message': 'Period logged', 'period': PeriodEntrySerializer(period).data}, 'status': 201}

        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}


    @staticmethod
    def endPeriod(patient_id, data):
        try:
            patient = Patient.objects.get(pk=patient_id)
            if patient.user.gender != 'F':
                return {'data': {'success': False, 'message': 'Patient is not female'}, 'status': 400}

            cycle = MenstrualCycle.objects.filter(patient=patient).first()
            if not cycle:
                return {'data': {'success': False, 'message': 'Menstrual cycle not found'}, 'status': 404}

            active_period = PeriodEntry.objects.filter(menstrual_cycle=cycle, end_date__isnull=True).first()
            if not active_period:
                return {'data': {'success': False, 'message': 'No active period found'}, 'status': 404}

            end_date = data.get('end_date')
            if not end_date:
                return {'data': {'success': False, 'message': 'end_date is required'}, 'status': 400}

            if end_date < str(active_period.start_date):
                return {'data': {'success': False, 'message': 'end_date cannot be before start_date'}, 'status': 400}

            active_period.end_date = end_date
            active_period.save()
            return {'data': {'success': True, 'message': 'Period ended', 'period': PeriodEntrySerializer(active_period).data}, 'status': 200}

        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}


    @staticmethod
    def getPeriods(patient_id):
        try:
            patient = Patient.objects.get(pk=patient_id)
            if patient.user.gender != 'F':
                return {'data': {'success': False, 'message': 'Patient is not female'}, 'status': 400}

            cycle = MenstrualCycle.objects.filter(patient=patient).first()
            if not cycle:
                return {'data': {'success': False, 'message': 'Menstrual cycle not found'}, 'status': 404}

            periods = PeriodEntry.objects.filter(menstrual_cycle=cycle).order_by('-start_date')
            serializer = PeriodEntrySerializer(periods, many=True)
            return {'data': {'success': True, 'periods': serializer.data}, 'status': 200}

        except Patient.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient not found'}, 'status': 404}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        