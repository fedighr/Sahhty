import pytest
from rest_framework.test import APIClient
from django.utils import timezone
from datetime import timedelta
from users.models import User
from patients.models import Patient
from doctors.models import Doctor, Speciality
from appointments.models import Appointment
from unittest.mock import patch


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


@pytest.fixture
def appointment_date():
    return timezone.now() + timedelta(days=1)


class TestCreateAppointment:

    @pytest.mark.django_db
    @patch('appointments.services.notify_user')
    def test_success(self, mock_notify, client, patient, doctor, appointment_date):
        response = client.post('/appointments/AppointmentService/create_appointment/', {
            "patient_id": patient.id,
            "doctor_id": doctor.id,
            "appointment_date": appointment_date,
            "reason": "Regular checkup"
        }, format='json')
        assert response.status_code == 201
        assert response.data['success'] == True

    @pytest.mark.django_db
    @patch('appointments.services.notify_user')
    def test_doctor_double_booked(self, mock_notify, client, patient, doctor, appointment_date, speciality):
        Appointment.objects.create(
            patient=patient,
            doctor=doctor,
            appointment_date=appointment_date,
            status='PENDING'
        )
        other_patient_user = User.objects.create_user(
            first_name="Jane", last_name="Doe",
            email="jane@test.com", password="Test1234!",
            phone="+21612345670", gender="F",
            birth_date="1992-01-01", role="P"
        )
        other_patient = Patient.objects.create(
            user=other_patient_user,
            height=160, weight=55, blood_type="B+"
        )
        response = client.post('/appointments/AppointmentService/create_appointment/', {
            "patient_id": other_patient.id,
            "doctor_id": doctor.id,
            "appointment_date": appointment_date,
        }, format='json')
        assert response.status_code == 400
        assert response.data['success'] == False
        assert 'not available' in response.data['message'].lower()

    @pytest.mark.django_db
    @patch('appointments.services.notify_user')
    def test_patient_double_booked(self, mock_notify, client, patient, doctor, appointment_date, speciality):
        Appointment.objects.create(
            patient=patient,
            doctor=doctor,
            appointment_date=appointment_date,
            status='PENDING'
        )
        other_doctor_user = User.objects.create_user(
            first_name="Dr", last_name="Jones",
            email="jones@test.com", password="Test1234!",
            phone="+21612345671", gender="M",
            birth_date="1975-01-01", role="D"
        )
        other_doctor = Doctor.objects.create(
            user=other_doctor_user,
            speciality=speciality,
            address="456 Other St",
            experience=3,
            consultation_duration=30,
            ville="SOUSSE"
        )
        response = client.post('/appointments/AppointmentService/create_appointment/', {
            "patient_id": patient.id,
            "doctor_id": other_doctor.id,
            "appointment_date": appointment_date,
        }, format='json')
        assert response.status_code == 400
        assert response.data['success'] == False
        assert 'already has an appointment' in response.data['message'].lower()


class TestConfirmAppointment:

    @pytest.mark.django_db
    def test_success(self, client, patient, doctor, appointment_date):
        appointment = Appointment.objects.create(
            patient=patient, doctor=doctor,
            appointment_date=appointment_date,
            status='PENDING'
        )
        response = client.put(f'/appointments/AppointmentService/{appointment.id}/confirm_appointment/')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_confirm_already_confirmed(self, client, patient, doctor, appointment_date):
        appointment = Appointment.objects.create(
            patient=patient, doctor=doctor,
            appointment_date=appointment_date,
            status='CONFIRMED'
        )
        response = client.put(f'/appointments/AppointmentService/{appointment.id}/confirm_appointment/')
        assert response.status_code == 400
        assert response.data['success'] == False

    @pytest.mark.django_db
    def test_confirm_not_found(self, client):
        response = client.put('/appointments/AppointmentService/confirm_appointment/9999/')
        assert response.status_code == 404


class TestCancelAppointment:

    @pytest.mark.django_db
    def test_cancel_by_doctor(self, client, patient, doctor, appointment_date):
        appointment = Appointment.objects.create(
            patient=patient, doctor=doctor,
            appointment_date=appointment_date,
            status='PENDING'
        )
        response = client.put(f'/appointments/AppointmentService/{appointment.id}/cancel_appointment/', {
            "cancelled_by": "DOCTOR"
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_cancel_by_patient(self, client, patient, doctor, appointment_date):
        appointment = Appointment.objects.create(
            patient=patient, doctor=doctor,
            appointment_date=appointment_date,
            status='PENDING'
        )
        response = client.put(f'/appointments/AppointmentService/{appointment.id}/cancel_appointment/', {
            "cancelled_by": "PATIENT"
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_cancel_already_cancelled(self, client, patient, doctor, appointment_date):
        appointment = Appointment.objects.create(
            patient=patient, doctor=doctor,
            appointment_date=appointment_date,
            status='CANCELLED'
        )
        response = client.put(f'/appointments/AppointmentService/{appointment.id}/cancel_appointment/', {
            "cancelled_by": "DOCTOR"
        }, format='json')
        assert response.status_code == 400
        assert response.data['success'] == False

    @pytest.mark.django_db
    def test_cancel_not_found(self, client):
        response = client.put('/appointments/AppointmentService/9999/cancel_appointment/', {
            "cancelled_by": "DOCTOR"
        }, format='json')
        assert response.status_code == 404