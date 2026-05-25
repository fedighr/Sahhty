import pytest
from unittest.mock import patch
from rest_framework.test import APIClient
from users.models import User
from django.utils import timezone
from datetime import timedelta
from django.core.cache import cache
from django.utils import timezone
from datetime import timedelta, date
from utils.otp_service import OTPService
from measurements.services import MeasurementService
from ml_engine.predictor import predict_risk

@pytest.fixture
def client():
    return APIClient()


@pytest.fixture
def verified_user(db):
    user = User.objects.create_user(
        first_name="John",
        last_name="Doe",
        email="john@test.com",
        password="Test1234!",
        phone="+21612345678",
        gender="M",
        birth_date="1990-01-01",role="A"
    )
    user.is_verified = True
    user.verification_code = "123456"
    user.expiration_date = timezone.now() + timedelta(minutes=5)
    user.save()
    return user


class TestSignup:

    @pytest.mark.django_db
    @patch('users.services.send_verification_email', return_value=True)
    def test_success(self, mock_email, client):
        response = client.post('/users/auth/signup/', {
            "first_name": "John", "last_name": "Doe",
            "email": "john@test.com", "password": "Test1234!",
            "phone": "+21612345678", "gender": "M", "birth_date": "1990-01-01"
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    @patch('users.services.send_verification_email', return_value=True)
    def test_duplicate_phone(self, mock_email, client):
        client.post('/users/auth/signup/', {
            "first_name": "John", "last_name": "Doe",
            "email": "john@test.com", "password": "Test1234!",
            "phone": "+21612345678", "gender": "M", "birth_date": "1990-01-01"
        }, format='json')
        response = client.post('/users/auth/signup/', {
            "first_name": "Jane", "last_name": "Doe",
            "email": "jane@test.com", "password": "Test1234!",
            "phone": "+21612345678", "gender": "F", "birth_date": "1992-01-01"
        }, format='json')
        assert response.status_code == 400
        assert response.data['phone'][0] == 'user with this phone already exists.'

    @pytest.mark.django_db
    @patch('users.services.send_verification_email', return_value=True)
    def test_duplicate_email(self, mock_email, client):
        client.post('/users/auth/signup/', {
            "first_name": "John", "last_name": "Doe",
            "email": "john@test.com", "password": "Test1234!",
            "phone": "+21612345678", "gender": "M", "birth_date": "1990-01-01"
        }, format='json')
        response = client.post('/users/auth/signup/', {
            "first_name": "Jane", "last_name": "Doe",
            "email": "john@test.com", "password": "Test1234!",
            "phone": "+21612345679", "gender": "F", "birth_date": "1992-01-01"
        }, format='json')
        assert response.status_code == 400
        assert response.data['email'][0] == 'user with this email already exists.'


class TestVerifyCode:

    @pytest.mark.django_db
    def test_success(self, client, verified_user):
        response = client.post('/users/auth/verify_code/', {
            "email": "john@test.com",
            "code": "123456"
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_wrong_code(self, client, verified_user):
        response = client.post('/users/auth/verify_code/', {
            "email": "john@test.com",
            "code": "000000"
        }, format='json')
        assert response.status_code == 400
        assert response.data['success'] == False

    @pytest.mark.django_db
    def test_expired_code(self, client, verified_user):
        verified_user.expiration_date = timezone.now() - timedelta(minutes=10)
        verified_user.save()
        response = client.post('/users/auth/verify_code/', {
            "email": "john@test.com",
            "code": "123456"
        }, format='json')
        assert response.status_code == 400
        assert 'expired' in response.data['message'].lower()


class TestLogin:

    @pytest.mark.django_db
    def test_success(self, client, verified_user):
        response = client.post('/users/auth/signin/', {
            "email": "john@test.com",
            "password": "Test1234!"
        }, format='json')
        assert response.status_code == 200
        assert 'access' in response.data

    @pytest.mark.django_db
    def test_wrong_password(self, client, verified_user):
        response = client.post('/users/auth/signin/', {
            "email": "john@test.com",
            "password": "WrongPass!"
        }, format='json')
        assert response.status_code == 400
        assert response.data['success'] == False

    @pytest.mark.django_db
    def test_unverified_user(self, client):
        User.objects.create_user(
            first_name="Jane", last_name="Doe",
            email="jane@test.com", password="Test1234!",
            phone="+21612345679", gender="F", birth_date="1992-01-01"
        )
        response = client.post('/users/auth/signin/', {
            "email": "jane@test.com",
            "password": "Test1234!"
        }, format='json')
        assert response.status_code == 403
        assert response.data['message'] == 'Email not verified'

    @pytest.mark.django_db
    def test_locked_account(self, client, verified_user):
        verified_user.lockout_until = timezone.now() + timedelta(minutes=15)
        verified_user.save()
        response = client.post('/users/auth/signin/', {
            "email": "john@test.com",
            "password": "Test1234!"
        }, format='json')
        assert response.status_code == 403
        assert 'locked' in response.data['message'].lower()

    @pytest.mark.django_db
    def test_rate_limit(self, client, verified_user):
        cache.clear()
        for _ in range(5):
            client.post('/users/auth/signin/', {
                "email": "john@test.com",
                "password": "WrongPass!"
            }, format='json')
        response = client.post('/users/auth/signin/', {
            "email": "john@test.com",
            "password": "WrongPass!"
        }, format='json')
        assert response.status_code == 429


class TestTwoFactorAuth:

    @pytest.mark.django_db
    @patch('users.services.send_verification_email', return_value=True)
    def test_2fa_success_flow(self, mock_email, client, verified_user):
        verified_user.two_factor_enabled = True
        verified_user.save(update_fields=['two_factor_enabled'])

        signin = client.post('/users/auth/signin/', {
            "email": verified_user.email,
            "password": "Test1234!"
        }, format='json')
        assert signin.status_code == 200
        assert signin.data['requires_2fa'] == True
        assert 'message' in signin.data

        verified_user.refresh_from_db()
        assert verified_user.two_factor_code is not None
        assert verified_user.two_factor_expiration is not None

        verify = client.post('/users/auth/verify_2fa/', {
            "email": verified_user.email,
            "code": verified_user.two_factor_code,
        }, format='json')
        assert verify.status_code == 200
        assert verify.data['success'] == True
        assert 'access' in verify.data
        assert 'refresh' in verify.data

        verified_user.refresh_from_db()
        assert verified_user.two_factor_code is None
        assert verified_user.two_factor_expiration is None


class TestForgetPassword:

    @pytest.mark.django_db
    @patch('users.services.send_verification_email', return_value=True)
    def test_success(self, mock_email, client, verified_user):
        verified_user.can_reset_password = True
        verified_user.save()
        response = client.post('/users/auth/forget_password/', {
            "email": "john@test.com",
            "password": "NewPass1234!"
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_without_verification(self, client, verified_user):
        response = client.post('/users/auth/forget_password/', {
            "email": "john@test.com",
            "password": "NewPass1234!"
        }, format='json')
        assert response.status_code == 400
        assert response.data['success'] == False


class TestSecurity:

    @pytest.mark.django_db
    def test_protected_route_without_jwt(self, client):
        response = client.delete('/users/auth/1/delete_account/')
        assert response.status_code == 401

    @pytest.mark.django_db
    def test_logout_blacklists_token(self, client, verified_user):
        cache.clear()
        login = client.post('/users/auth/signin/', {
            "email": "john@test.com",
            "password": "Test1234!"
        }, format='json')
        refresh = login.data['refresh']
        access = login.data['access']
        
        client.credentials(HTTP_AUTHORIZATION='Bearer ' + access)
        logout = client.post('/users/auth/logout/', {"refresh": refresh}, format='json')
        assert logout.status_code == 200

        client.credentials()
        response = client.post('/users/refresh/', {"refresh": refresh}, format='json')
        assert response.status_code == 401

    @pytest.mark.django_db
    def test_delete_account_owner(self, client, verified_user):
        client.force_authenticate(user=verified_user)
        response = client.delete(f'/users/auth/{verified_user.id}/delete_account/')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_delete_account_another_user(self, client, verified_user):
        other_user = User.objects.create_user(
            first_name="Jane", last_name="Doe",
            email="jane@test.com", password="Test1234!",
            phone="+21612345679", gender="F",
            birth_date="1992-01-01",
            role="A"
        )
        other_user.is_verified = True
        other_user.is_staff = False
        other_user.save()
        client.force_authenticate(user=other_user)
        response = client.delete(f'/users/auth/{verified_user.id}/delete_account/')
        assert response.status_code == 403

class TestPasswordHashing:

    def test_hash_differs_from_plain_text(self):
        plain = "Test1234!"
        user = User(email="test@test.com")
        user.set_password(plain)
        assert user.password != plain
        assert user.password.startswith("pbkdf2_sha256$")

    def test_verify_correct_password(self):
        plain = "Test1234!"
        user = User(email="test@test.com")
        user.set_password(plain)
        assert user.check_password(plain) is True

    def test_verify_wrong_password(self):
        user = User(email="test@test.com")
        user.set_password("Test1234!")
        assert user.check_password("WrongPass!") is False

    def test_hash_uniqueness(self):
        user1 = User(email="test1@test.com")
        user2 = User(email="test2@test.com")
        user1.set_password("Test1234!")
        user2.set_password("Test1234!")
        assert user1.password != user2.password

class TestOTPService:

    def test_otp_code_is_6_digits(self):
        otp = OTPService.create_otp()
        assert len(otp['code']) == 6

    def test_otp_code_is_numeric(self):
        otp = OTPService.create_otp()
        assert otp['code'].isdigit()

    def test_otp_is_expired(self):
        expired_time = timezone.now() - timedelta(minutes=10)
        assert OTPService.is_expired(expired_time) == True

    def test_otp_not_expired(self):
        valid_time = timezone.now() + timedelta(minutes=5)
        assert OTPService.is_expired(valid_time) == False

    def test_otp_none_expiry_returns_false(self):
        assert OTPService.is_expired(None) == False

class TestUnitaire:

    def test_hash_differs_from_plain_text(self):
        plain = "111111ttT!"
        user = User(email="fedi@abdelhed.com")
        user.set_password(plain)
        assert user.password != plain
        assert user.password.startswith("pbkdf2_sha256$")

    def test_otp_is_expired(self):
        expired_time = timezone.now() - timedelta(minutes=10)
        assert OTPService.is_expired(expired_time) == True

    def test_high_risk_high_glucose(self):
        note = MeasurementService.generate_risk_note(
            glucose=4.0, bp_sys=120, bp_dia=80,
            heart_rate=75, body_temp=37.0, risk_level='HIGH'
        )
        assert "Glycémie dangereusement élevée" in note

    def test_out_of_range_glucose_high(self):
        result, _ = predict_risk({"Age": 28,"BS": 3.5,"SystolicBP": 120,"DiastolicBP": 80,"BodyTemp": 37.0,"HeartRate": 78,})
        assert result == "HIGH"


    def test_out_of_range_glucose_low(self):
        result, _ = predict_risk({"Age": 28,"BS": 0.25,"SystolicBP": 120,"DiastolicBP": 80,"BodyTemp": 37.0,"HeartRate": 78,})

        assert result == "HIGH"

class IntegrationTest:

    @pytest.mark.django_db
    @patch('users.services.send_verification_email', return_value=True)
    def test_success(self, mock_email, client):
        response = client.post('/users/auth/signup/', {
            "first_name": "John", "last_name": "Doe",
            "email": "john@test.com", "password": "Test1234!",
            "phone": "+21612345678", "gender": "M", "birth_date": "1990-01-01"
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    @patch('measurements.services.predict_risk', return_value=('LOW', 80))
    @patch('measurements.services.AlertService.sendRiskAlert')
    def test_create_blood_pressure_measurement(self, mock_alert, mock_predict, client, patient):
        response = client.post('/measurements/MeasurementService/create_measurement/', {
            "patient_id": patient.id,
            "type": "BLOOD_PRESSURE",
            "value1": "120.00",
            "value2": "80.00",
            "unit": "MMHG",
            "context": "Morning"
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

import pytest
from unittest.mock import patch
from rest_framework.test import APIClient
from django.utils import timezone
from datetime import timedelta
from users.models import User
from patients.models import Patient
from doctors.models import Doctor, Speciality
from appointments.models import Appointment
from medications.models import Medication, Treatment, TreatmentSchedule


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


@pytest.fixture
def medication(db):
    return Medication.objects.create(
        name="ABBOTICINE",
        dci="ERYTHROMYCINE",
        code="304172",
        form="Suspension Buvable",
        dosage="200mg/5ml",
        category="E",
    )


@pytest.fixture
def treatment(db, patient, medication):
    return Treatment.objects.create(
        patient=patient,
        medication=medication,
        start_date="2025-01-01",
        end_date="2025-06-01",
        dose="200mg",
        frequency="3 times a day"
    )


class TestIntegration:

    @pytest.mark.django_db
    @patch('users.services.send_verification_email', return_value=True)
    def test_user_signup_and_otp_verification(self, mock_email, client):
        response = client.post('/users/auth/signup/', {
            "first_name": "John", "last_name": "Doe","email": "john@test.com", "password": "Test1234!",
            "phone": "+21612345678", "gender": "M", "birth_date": "1990-01-01"
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    @patch('appointments.services.notify_user')
    def test_appointment_creation_and_notification(self, mock_notify, client, patient, doctor, appointment_date):
        response = client.post('/appointments/AppointmentService/create_appointment/', {
            "patient_id": patient.id,"doctor_id": doctor.id,"appointment_date": appointment_date,"reason": "Regular checkup"
        }, format='json')
        assert response.status_code == 201
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_treatment_retrieval_and_medication_analysis(self, client, patient, treatment):
        TreatmentSchedule.objects.create(treatment=treatment, dose_time="08:00:00")
        response = client.get(f'/medications/medicationsService/{patient.id}/get_treatments_by_patient_id/')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    @patch('measurements.services.predict_risk', return_value=('LOW', 80))
    @patch('measurements.services.AlertService.sendRiskAlert')
    def test_measurement_creation_and_risk_assessment(self, mock_alert, mock_predict, client, patient):
        response = client.post('/measurements/MeasurementService/create_measurement/', {
            "patient_id": patient.id,"type": "BLOOD_PRESSURE","value1": "120.00","value2": "80.00","unit": "MMHG",
            "context": "Morning"}, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True