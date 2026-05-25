from locust import HttpUser, task, between

import json



TEST_EMAIL = "jimmysins60@gmail.com"   # ← replace with a real test account

TEST_PASSWORD = "sift11ff"        # ← replace



class SahhtyUser(HttpUser):

    host = "http://127.0.0.1:8000"

    wait_time = between(1, 3)

    token = None



    def on_start(self):

        """Login once per virtual user and store JWT"""

        response = self.client.post(

            "/users/auth/signin/",

            json={"email": TEST_EMAIL, "password": TEST_PASSWORD},

            name="POST /users/auth/signin/"

        )

        if response.status_code == 200:

            data = response.json()

            # Adjust the key below to match your actual response shape

            # e.g. data["access"], data["token"], data["data"]["access"]

            self.token = data.get("access") or data.get("token")

            self.client.headers.update({"Authorization": f"Bearer {self.token}"})

        else:

            self.token = None



    @task(3)

    def get_patients(self):

        with self.client.get(

            "/patients/PatientService/22/get_patient_by_id",

            name="GET /patients/PatientService/22/get_patient_by_id",

            catch_response=True

        ) as r:

            if r.status_code == 200:

                r.success()

            else:

                r.failure(f"Status {r.status_code}")



    @task(3)

    def get_measurements(self):

        with self.client.get(

            "/measurements/MeasurementService/22/get_latest_measurements/",

            name="GET /measurements/MeasurementService/22/get_latest_measurements/",

            catch_response=True

        ) as r:

            if r.status_code == 200:

                r.success()

            else:

                r.failure(f"Status {r.status_code}")



    @task(2)

    def get_appointments(self):

        with self.client.get(

            "/appointments/AppointmentService/22/get_patient_appointments",

            name="GET /appointments/AppointmentService/22/get_patient_appointments",

            catch_response=True

        ) as r:

            if r.status_code == 200:

                r.success()

            else:

                r.failure(f"Status {r.status_code}")