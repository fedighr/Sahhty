import pytest
from rest_framework.test import APIClient
from users.models import User
from patients.models import Patient
from medications.models import Medication, Treatment, TreatmentSchedule
from medications.services import current_trimester
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


class TestCreateTreatment:

    @pytest.mark.django_db
    def test_success(self, client, patient, medication):
        response = client.post('/medications/medicationsService/create_treatment_with_schedules/', {
            "treatment": {
                "patient_id": patient.id,
                "medication_id": medication.id,
                "start_date": "2025-01-01",
                "end_date": "2025-06-01",
                "dose": "200mg",
                "frequency": "3 times a day"
            },
            "schedules": [
                {"dose_time": "08:00:00"},
                {"dose_time": "14:00:00"},
                {"dose_time": "20:00:00"}
            ]
        }, format='json')
        assert response.status_code == 201
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_end_date_before_start_date(self, client, patient, medication):
        response = client.post('/medications/medicationsService/create_treatment_with_schedules/', {
            "treatment": {
                "patient_id": patient.id,
                "medication_id": medication.id,
                "start_date": "2025-06-01",
                "end_date": "2025-01-01",
                "dose": "200mg",
                "frequency": "3 times a day"
            },
            "schedules": [
                {"dose_time": "08:00:00"}
            ]
        }, format='json')
        assert response.status_code == 500

    @pytest.mark.django_db
    def test_no_schedules(self, client, patient, medication):
        response = client.post('/medications/medicationsService/create_treatment_with_schedules/', {
            "treatment": {
                "patient_id": patient.id,
                "medication_id": medication.id,
                "start_date": "2025-01-01",
                "end_date": "2025-06-01",
                "dose": "200mg",
                "frequency": "3 times a day"
            },
            "schedules": []
        }, format='json')
        assert response.status_code == 500


class TestGetTreatments:

    @pytest.mark.django_db
    def test_success(self, client, patient, treatment):
        TreatmentSchedule.objects.create(treatment=treatment, dose_time="08:00:00")
        response = client.get(f'/medications/medicationsService/{patient.id}/get_treatments_by_patient_id/')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_no_treatments(self, client, patient):
        response = client.get(f'/medications/medicationsService/{patient.id}/get_treatments_by_patient_id/')
        assert response.status_code == 404
        assert response.data['success'] == False


class TestDeleteTreatment:

    @pytest.mark.django_db
    def test_success(self, client, treatment):
        response = client.delete(f'/medications/medicationsService/{treatment.id}/delete_treatment_by_id/')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_not_found(self, client):
        response = client.delete('/medications/medicationsService/9999/delete_treatment_by_id/')
        assert response.status_code == 404
        assert response.data['success'] == False


class TestUpdateSchedule:

    @pytest.mark.django_db
    def test_success(self, client, treatment):
        schedule = TreatmentSchedule.objects.create(treatment=treatment, dose_time="08:00:00")
        response = client.patch(f'/medications/medicationsService/{schedule.id}/update_schedule_by_id/', {
            "new_time": "09:00:00"
        }, format='json')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_not_found(self, client):
        response = client.patch('/medications/medicationsService/9999/update_schedule_by_id/', {
            "new_time": "09:00:00"
        }, format='json')
        assert response.status_code == 404
        assert response.data['success'] == False


class TestDeleteSchedule:

    @pytest.mark.django_db
    def test_success(self, client, treatment):
        schedule = TreatmentSchedule.objects.create(treatment=treatment, dose_time="08:00:00")
        response = client.delete(f'/medications/medicationsService/{schedule.id}/delete_schedule_by_id/')
        assert response.status_code == 200
        assert response.data['success'] == True

    @pytest.mark.django_db
    def test_not_found(self, client):
        response = client.delete('/medications/medicationsService/9999/delete_schedule_by_id/')
        assert response.status_code == 404
        assert response.data['success'] == False


class TestMedicationSearch:

    @pytest.mark.django_db
    def test_success(self, client, medication):
        response = client.get('/medications/medicationsService/search/?q=ABBOT')
        assert response.status_code == 200

    @pytest.mark.django_db
    def test_query_too_short(self, client):
        response = client.get('/medications/medicationsService/search/?q=A')
        assert response.status_code == 400

    @pytest.mark.django_db
    def test_no_results(self, client):
        response = client.get('/medications/medicationsService/search/?q=XXXXXXXXXX')
        assert response.status_code == 404

class TestTrimesterCalculation:

    def test_trimester_T1(self):
        start_date = date.today() - timedelta(weeks=6)
        assert current_trimester(start_date) == "T1"

    def test_trimester_T2(self):
        start_date = date.today() - timedelta(weeks=20)
        assert current_trimester(start_date) == "T2"

    def test_trimester_T3(self):
        start_date = date.today() - timedelta(weeks=35)
        assert current_trimester(start_date) == "T3"

    def test_trimester_none_no_start_date(self):
        assert current_trimester(None) == None