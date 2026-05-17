import pytest
from rest_framework.test import APIClient
from unittest.mock import patch
from users.models import User
from patients.models import Patient
from doctors.models import Doctor, Speciality
from medical_files.models import Attachment, PatientDoctorAccess
from django.core.files.uploadedfile import SimpleUploadedFile


@pytest.fixture
def client():
    return APIClient()


@pytest.fixture
def speciality(db):
    return Speciality.objects.create(name="Gynecology")


@pytest.fixture
def patient_user(db):
    user = User.objects.create_user(
        first_name="John", last_name="Doe",
        email="patient@test.com", password="Test1234!",
        phone="+21612345678", gender="F",
        birth_date="1990-01-01", role="P"
    )
    user.is_verified = True
    user.save()
    return user


@pytest.fixture
def doctor_user(db):
    user = User.objects.create_user(
        first_name="Dr", last_name="Smith",
        email="doctor@test.com", password="Test1234!",
        phone="+21612345679", gender="M",
        birth_date="1980-01-01", role="D"
    )
    user.is_verified = True
    user.save()
    return user


@pytest.fixture
def patient(db, patient_user):
    return Patient.objects.create(
        user=patient_user,
        height=165,
        weight=60,
        blood_type="A+"
    )


@pytest.fixture
def doctor(db, doctor_user, speciality):
    return Doctor.objects.create(
        user=doctor_user,
        speciality=speciality,
        address="123 Main St",
        experience=5,
        consultation_duration=30,
        ville="TUNIS"
    )


class TestPatientDoctorAccess:

    @pytest.mark.django_db
    @patch('medical_files.services.notify_user')
    def test_request_access_success(self, mock_notify, client, patient, doctor):
        response = client.post('/medical_files/MedicalFileService/request_medical_access/', {
            "patient_id": patient.id,
            "doctor_id": doctor.id,
        }, format='json')
        assert response.status_code == 201
        assert response.data['success'] == True

    @pytest.mark.django_db
    @patch('medical_files.services.notify_user')
    def test_request_access_already_requested(self, mock_notify, client, patient, doctor):
        PatientDoctorAccess.objects.create(
            patient=patient,
            doctor=doctor,
            status='PENDING'
        )
        response = client.post('/medical_files/MedicalFileService/request_medical_access/', {
            "patient_id": patient.id,
            "doctor_id": doctor.id,
        }, format='json')
        assert response.status_code == 400
        assert 'non_field_errors' in response.data

    @pytest.mark.django_db
    def test_grant_access_success(self, client, patient, doctor):
        PatientDoctorAccess.objects.create(
            patient=patient,
            doctor=doctor,
            status='PENDING'
        )
        response = client.post('/medical_files/MedicalFileService/create_patient_doctor_access/', {
            "patient_id": patient.id,
            "doctor_id": doctor.id,
        }, format='json')
        assert response.status_code == 201
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_grant_access_already_granted(self, client, patient, doctor):
        PatientDoctorAccess.objects.create(
            patient=patient,
            doctor=doctor,
            status='ACCEPTED'
        )
        response = client.post('/medical_files/MedicalFileService/create_patient_doctor_access/', {
            "patient_id": patient.id,
            "doctor_id": doctor.id,
        }, format='json')
        assert response.status_code == 400
        assert response.data['success'] == False

    @pytest.mark.django_db
    def test_revoke_access_success(self, client, patient, doctor):
        PatientDoctorAccess.objects.create(
            patient=patient,
            doctor=doctor,
            status='ACCEPTED'
        )
        response = client.delete('/medical_files/MedicalFileService/revoke_access/', {
            "patient_id": patient.id,
            "doctor_id": doctor.id,
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_revoke_access_not_found(self, client, patient, doctor):
        response = client.delete('/medical_files/MedicalFileService/revoke_access/', {
            "patient_id": patient.id,
            "doctor_id": doctor.id,
        }, format='json')
        assert response.status_code == 404
        assert response.data['success'] == False


class TestAttachment:

    @pytest.mark.django_db
    def test_get_patient_medical_files(self, client, patient):
        response = client.get(f'/medical_files/MedicalFileService/{patient.id}/get_patient_medical_files/')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_delete_attachment_success(self, client, patient):
        attachment = Attachment.objects.create(
            patient=patient,
            type='REPORT',
            file='attachments/patients/1/test.pdf'
        )
        response = client.delete(f'/medical_files/MedicalFileService/{attachment.id}/delete_attachment/')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_delete_attachment_not_found(self, client):
        response = client.delete('/medical_files/MedicalFileService/9999/delete_attachment/')
        assert response.status_code == 404
        assert response.data['success'] == False

        from django.core.files.uploadedfile import SimpleUploadedFile

    def test_upload_attachment_success(self, client, patient):
        file = SimpleUploadedFile(
            "test.pdf",
            b"test file content",
            content_type="application/pdf"
        )
        response = client.post('/medical_files/MedicalFileService/create_attachment/', {
            "patient_id": patient.id,
            "type": "REPORT",
            "file": file
        }, format='multipart')
        assert response.status_code == 201
        assert response.data['success'] == True

    def test_upload_attachment_file_too_large(self, client, patient):
        large_content = b"x" * (11 * 1024 * 1024)  # 11MB
        file = SimpleUploadedFile(
            "large.pdf",
            large_content,
            content_type="application/pdf"
        )
        response = client.post('/medical_files/MedicalFileService/create_attachment/', {
            "patient_id": patient.id,
            "type": "REPORT",
            "file": file
        }, format='multipart')
        assert response.status_code == 400

    def test_upload_attachment_invalid_type(self, client, patient):
        file = SimpleUploadedFile(
            "test.exe",
            b"fake exe content",
            content_type="application/x-msdownload"
        )
        response = client.post('/medical_files/MedicalFileService/create_attachment/', {
            "patient_id": patient.id,
            "type": "REPORT",
            "file": file
        }, format='multipart')
        assert response.status_code == 400