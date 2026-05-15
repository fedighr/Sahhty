from django.db import DatabaseError, IntegrityError

from patients.serializers import PatientSerializer
from drf_spectacular.types import date
from rest_framework.utils.timezone import datetime
from .models import Attachment, PatientDoctorAccess
from .serializers import AttachmentSerializer, PatientDoctorAccessSerializer
from alerts.models import Alert
from alerts.serializers import AlertSerializer
from patients.models import Patient
from doctors.models import Doctor
from doctors.serializers import DoctorSerializer
from django.db import transaction
from alerts.services import AlertService
#from notifications.services import notify_user

class MedicalFileService:
    @staticmethod
    def createAttachment(validated_data):
        try:
            attachment = Attachment.objects.create(**validated_data)
            serializer = AttachmentSerializer(attachment)
            return {'data': {'success': True, 'message': 'Attachment created successfully', 'attachment': serializer.data}, 'status': 201}
        except (IntegrityError, DatabaseError) as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def createPatientDoctorAccess(data):
        try:
            with transaction.atomic():
                access_exists = PatientDoctorAccess.objects.filter(patient=data['patient_id'], doctor=data['doctor_id']).first()
                if access_exists:
                    if(access_exists.status == 'PENDING'):
                        access_exists.status = 'ACCEPTED'
                        access_exists.save()

                    elif access_exists.status == 'ACCEPTED':
                        return {'data': {'success': False, 'message': 'Access already granted'}, 'status': 400}
                    
                    access = access_exists
                
                else:
                    serializer = PatientDoctorAccessSerializer(data=data)
                    serializer.is_valid(raise_exception=True)

                    access = PatientDoctorAccess.objects.create(
                        patient=serializer.validated_data['patient'],
                        doctor=serializer.validated_data['doctor'],
                        status='ACCEPTED',
                    )

                doctor = access_exists.doctor if access_exists else serializer.validated_data['doctor']
                patient = access_exists.patient if access_exists else serializer.validated_data['patient']

                Alert.objects.create(
                    type='SYSTEM',
                    user=doctor.user,
                    message=f"You have been granted access to patient {patient.user.first_name} {patient.user.last_name}'s medical files.",
                )

                serializer = PatientDoctorAccessSerializer(access)
                return {'data': {'success': True, 'message': 'Patient-Doctor access created successfully', 'access': serializer.data}, 'status': 201}
            
        except (IntegrityError, DatabaseError) as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def getPatientMedicalFiles(patient_id):
        try:
            attachments = Attachment.objects.filter(patient_id=patient_id)
            serializer = AttachmentSerializer(attachments, many=True)
            return {'data': {'success': True, 'medical_files': serializer.data}, 'status': 200}
        
        except (IntegrityError, DatabaseError) as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def getPatientDoctorsRequests(patient_id):
        try:
            accesses = PatientDoctorAccess.objects.filter(patient_id=patient_id, status='PENDING').select_related('doctor')
            doctor_list = [access.doctor for access in accesses]
            serializer = DoctorSerializer(doctor_list, many=True)
            return {'data': {'success': True, 'doctors': serializer.data}, 'status': 200}

        except (IntegrityError, DatabaseError) as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def deleteAttachment(attachment_id):
        try:
            attachment = Attachment.objects.get(id=attachment_id)
            file = attachment.file
            attachment.delete()
            if file:
                file.delete(save=False)

            return {'data': {'success': True, 'message': 'Attachment deleted successfully'}, 'status': 200}
        except Attachment.DoesNotExist:
            return {'data': {'success': False, 'message': 'Attachment not found'}, 'status': 404}
        except (IntegrityError, DatabaseError) as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def updateAttachment(attachment_id, validated_data, request):
        try:

            attachment = Attachment.objects.get(id=attachment_id)
            old_file = attachment.file if 'file' in validated_data else None

            for attr, value in validated_data.items():
                setattr(attachment, attr, value)

            attachment.save()
            attachment.refresh_from_db()
            serializer = AttachmentSerializer(attachment, context={'request': request})
            data = dict(serializer.data)

            if old_file:
                old_file.delete(save=False)

            return {'data': {'success': True, 'message': 'Attachment updated successfully', 'attachment': data}, 'status': 200}
        
        except Attachment.DoesNotExist:
            return {'data': {'success': False, 'message': 'Attachment not found'}, 'status': 404}
        except (IntegrityError, DatabaseError) as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def deletePatientDoctorAccess(access_id):
        try:
            access = PatientDoctorAccess.objects.get(id=access_id)
            access.delete()
            return {'data': {'success': True, 'message': 'Patient-Doctor access deleted successfully'}, 'status': 200}
        
        except PatientDoctorAccess.DoesNotExist:
            return {'data': {'success': False, 'message': 'Patient-Doctor access not found'}, 'status': 404}
        except (IntegrityError, DatabaseError) as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}

    @staticmethod
    def getPatientDoctors(patient_id):
        try:
            doctors = PatientDoctorAccess.objects.filter(patient_id=patient_id, status='ACCEPTED').select_related('doctor')
            doctor_list = [access.doctor for access in doctors]
            serializer = DoctorSerializer(doctor_list, many=True)
            return {'data': {'success': True, 'doctors': serializer.data}, 'status': 200}
        
        except (IntegrityError, DatabaseError) as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def getDoctorPatients(doctor_id):
        try:
            accesses = PatientDoctorAccess.objects.filter(doctor_id=doctor_id, status='ACCEPTED').select_related('patient')
            patient_list = [access.patient for access in accesses]
            serializer = PatientSerializer(patient_list, many=True)
            return {'data': {'success': True, 'patients': serializer.data}, 'status': 200}
        
        except (IntegrityError, DatabaseError) as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}
        
    @staticmethod
    def requestMedicalAccess(validated_data):
        try:
            with transaction.atomic():
                access = PatientDoctorAccess.objects.create(
                    patient=validated_data['patient'],
                    doctor=validated_data['doctor'],
                )

            patient_user = validated_data['patient'].user
            doctor_user = validated_data['doctor'].user

            Alert.objects.create(
                user=patient_user,
                type='SYSTEM',
                message=f"Doctor {doctor_user.first_name} {doctor_user.last_name} has requested access to your medical files."
            )
            """
            device = patient_user.devices.first()
            fcm_token = device.fcm_token if device else None

            notify_user(
                user_id=patient_user.id,
                event_type='access_request',
                data={
                    'access_id': access.id,
                    'doctor_name': f'{doctor_user.first_name} {doctor_user.last_name}',
                    'specialty': validated_data['doctor'].speciality.name,
                    'request_date': str(access.created_at),
                },
                fcm_token=fcm_token,
                email=patient_user.email,
            )
            """
            serializer = PatientDoctorAccessSerializer(access)
            return {'data': {'success': True, 'message': 'Medical access requested successfully', 'access': serializer.data}, 'status': 201}

        except (IntegrityError, DatabaseError) as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 400}
        except Exception as e:
            return {'data': {'success': False, 'message': str(e)}, 'status': 500}