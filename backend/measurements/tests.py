import pytest
from unittest.mock import patch
from rest_framework.test import APIClient
from users.models import User
from patients.models import Patient
from measurements.models import Measurement, RiskAssessment
from measurements.services import MeasurementService
from django.utils import timezone
from datetime import timedelta, date

@pytest.fixture
def client():
    return APIClient()


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
def patient(db, patient_user):
    return Patient.objects.create(
        user=patient_user,
        height=165,
        weight=60,
        blood_type="A+"
    )


class TestCreateMeasurement:

    @pytest.mark.django_db
    @patch('measurements.services.predict_risk', return_value=('LOW', 80))
    @patch('measurements.services.AlertService.sendRiskAlert')
    def test_create_weight_measurement(self, mock_alert, mock_predict, client, patient):
        response = client.post('/measurements/MeasurementService/create_measurement/', {
            "patient_id": patient.id,
            "type": "WEIGHT",
            "value1": "70.00",
            "unit": "KG",
            "context": "Morning"
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

    @pytest.mark.django_db
    @patch('measurements.services.predict_risk', return_value=('HIGH', 90))
    @patch('measurements.services.AlertService.sendRiskAlert')
    def test_high_risk_triggers_alert(self, mock_alert, mock_predict, client, patient):
        Measurement.objects.create(patient=patient, type='GLYCEMIA', value1='1.50', unit='G_L')
        Measurement.objects.create(patient=patient, type='BLOOD_PRESSURE', value1='140', value2='90', unit='MMHG')

        response = client.post('/measurements/MeasurementService/create_measurement/', {
            "patient_id": patient.id,
            "type": "HEART_RATE",
            "value1": "110.00",
            "unit": "BPM",
            "context": "After exercise"
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_create_measurement_missing_fields(self, client, patient):
        response = client.post('/measurements/MeasurementService/create_measurement/', {
            "patient_id": patient.id,
            "type": "WEIGHT",
        }, format='json')
        assert response.status_code == 400

    @pytest.mark.django_db
    def test_create_measurement_invalid_patient(self, client):
        response = client.post('/measurements/MeasurementService/create_measurement/', {
            "patient_id": 9999,
            "type": "WEIGHT",
            "value1": "70.00",
            "unit": "KG",
        }, format='json')
        assert response.status_code == 400


class TestGetMeasurements:

    @pytest.mark.django_db
    def test_get_latest_measurements(self, client, patient):
        Measurement.objects.create(patient=patient, type='WEIGHT', value1='70', unit='KG')
        response = client.get(f'/measurements/MeasurementService/{patient.id}/get_latest_measurements/')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_get_latest_measurements_patient_not_found(self, client):
        response = client.get('/measurements/MeasurementService/9999/get_latest_measurements/')
        assert response.status_code == 404
        assert response.data['success'] == False

    @pytest.mark.django_db
    def test_get_patient_measurements(self, client, patient):
        Measurement.objects.create(patient=patient, type='WEIGHT', value1='70', unit='KG')
        Measurement.objects.create(patient=patient, type='HEART_RATE', value1='80', unit='BPM')
        response = client.get(f'/measurements/MeasurementService/{patient.id}/get_patient_measurements/')
        assert response.status_code == 200

    @pytest.mark.django_db
    def test_get_patient_measurements_empty(self, client, patient):
        response = client.get(f'/measurements/MeasurementService/{patient.id}/get_patient_measurements/')
        assert response.status_code == 200


class TestRiskAssessment:

    @pytest.mark.django_db
    def test_get_risk_assessment_not_found(self, client, patient):
        response = client.get(f'/measurements/MeasurementService/{patient.id}/get_risk_assessment/')
        assert response.status_code == 404
        assert response.data['success'] == False

    @pytest.mark.django_db
    def test_get_risk_assessment_success(self, client, patient):
        RiskAssessment.objects.create(
            patient=patient,
            global_risk_level='LOW',
            final_risk_level='LOW',
        )
        response = client.get(f'/measurements/MeasurementService/{patient.id}/get_risk_assessment/')
        assert response.status_code == 200
        assert response.data['success'] == True


class TestRiskNoteGeneration:

    def test_high_risk_high_glucose(self):
        note = MeasurementService.generate_risk_note(
            glucose=4.0, bp_sys=120, bp_dia=80,
            heart_rate=75, body_temp=37.0, risk_level='HIGH'
        )
        assert 'Glycémie' in note

    def test_high_risk_high_blood_pressure(self):
        note = MeasurementService.generate_risk_note(
            glucose=1.0, bp_sys=170, bp_dia=115,
            heart_rate=75, body_temp=37.0, risk_level='HIGH'
        )
        assert 'Tension artérielle' in note

    def test_low_risk_all_normal(self):
        note = MeasurementService.generate_risk_note(
            glucose=1.0, bp_sys=120, bp_dia=80,
            heart_rate=75, body_temp=37.0, risk_level='LOW'
        )
        assert 'normales' in note

    def test_combined_fever_and_tachycardia(self):
        note = MeasurementService.generate_risk_note(
            glucose=1.0, bp_sys=120, bp_dia=80,
            heart_rate=110, body_temp=39.0, risk_level='HIGH'
        )
        assert 'Fièvre' in note or 'tachycardie' in note