Sahhty 🩺

A mobile healthcare platform for pregnancy monitoring and health management

Sahhty is a full-stack mobile health application developed as a final-year internship project (PFE) at Pharmacie Nahla Noureddine, Sousse. It helps patients — with a focus on pregnant women — centralize their healthcare information, track health measurements, manage medications safely, and stay connected with healthcare providers, while giving doctors dedicated tools for patient follow-up and appointment management.

The project originated from a real need identified by the pharmacy: healthcare information in Tunisia is often fragmented across providers and paper records, making continuity of care difficult and increasing the risk of missed follow-ups or harmful drug interactions — a risk that is especially critical during pregnancy.

Key Features

For Patients

Health measurement tracking and pregnancy progression monitoring
AI-based maternal risk assessment (XGBoost model, ~84% accuracy / 0.85 macro F1-score)
Medication safety checks: drug-interaction and pregnancy-safety verification, allergy checks
Doctor discovery with interactive map (OpenStreetMap) and appointment booking
Secure medical file storage and sharing
Real-time push notifications and in-app alerts for appointments, medication reminders, and health alerts

For Doctors

Patient management dashboard
Appointment scheduling and follow-up tools
Secure, authorized access to shared medical records
Tech Stack

Frontend (Mobile)

Flutter 3.x / Dart
Riverpod (state management)
Dio (HTTP client, JWT-authenticated requests)
Go Router (declarative, role-based navigation)
Firebase Cloud Messaging (push notifications)
Flutter Map + OpenStreetMap (doctor geolocation)

Backend

Python 3.13, Django 5.x, Django REST Framework
Simple JWT (access/refresh token authentication)
Django Channels + WebSockets (real-time notifications, Memurai as channel layer)
APScheduler (background jobs: reminders, alerts)
Brevo (transactional email / OTP delivery)
Groq API (LLM-powered natural language features)

Machine Learning

scikit-learn, XGBoost — maternal risk classification model, selected after comparison against Random Forest, SVM, and Logistic Regression

Database & Infrastructure

PostgreSQL, hosted on Neon (serverless Postgres)
Architecture

Sahhty follows a three-layer architecture:

Presentation Layer (Flutter mobile client) — UI, state management, API communication, push notifications
Application Layer (Django REST API) — business logic, authentication/authorization, appointment and medical file workflows
Data Layer (PostgreSQL on Neon) — persistent storage for users, medical records, appointments, treatments, and alerts

The backend follows a layered structure (URL routing → views/serializers → business logic → data access) across domain-specific Django apps: users, patients, doctors, appointments, measurements, alerts, medications, and medical files.

Machine Learning: Maternal Risk Prediction

Four models were trained and compared for maternal risk classification (High / Medium / Low), evaluated on a held-out test set of 305 samples:

Model	Accuracy	Macro F1-score
XGBoost (selected)	~84%	~0.85
Random Forest	~81%	~0.82
SVM	~71%	~0.71
Logistic Regression	~66%	~0.66

XGBoost was selected for production integration based on its superior accuracy and balanced performance across all risk categories, including underrepresented classes.

My Contribution

This project was built by a two-person team (myself and my binôme, Abdelhedi Chakroun) under dual academic supervision (ESSTHS) and professional/medical supervision (Pharmacie Nahla Noureddine). I focused on backend development: designing the Django REST API architecture, the medication safety and drug-interaction module, JWT authentication, and integrating the machine learning risk-prediction model into the platform.

Development Tools

VS Code, Android Studio (emulator), Git/GitHub, Postman (API testing), Draw.io (UML diagrams)

Developed as a Final-Year Internship Project (PFE) — Bachelor's in Software Engineering, ESSTHS, 2025–2026.
