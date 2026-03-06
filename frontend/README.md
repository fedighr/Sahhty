# Sahhty — Frontend Flutter

Health tracking app for Tunisian users. Clean Architecture + Riverpod + Go Router.

## Setup

```bash
flutter pub get
# Set your backend URL in lib/core/constants/app_constants.dart
# baseUrl = 'http://10.0.2.2:8000'  ← Android emulator
# baseUrl = 'http://localhost:8000'  ← iOS simulator / web

flutter run
```

## Architecture

```
lib/
├── core/
│   ├── constants/    # API endpoints, storage keys
│   ├── routes/       # go_router config
│   ├── theme/        # Colors, typography, theme
│   └── utils/        # Failures, logger, validators
├── data/
│   ├── models/       # Request/response models
│   ├── services/     # Dio HTTP services
│   └── repositories/ # Orchestrate service + storage
└── features/
    ├── auth/         # Login, register, OTP, forgot password
    ├── profile_setup/# Patient & doctor profile creation
    └── home/         # Patient home, doctor home
```

## Backend Endpoints (wired)

| Screen | Endpoint |
|--------|----------|
| Register | POST /users/auth/signup/ |
| Login | POST /users/auth/signin/ |
| Verify OTP | POST /users/auth/verify_code/ |
| Resend OTP | POST /users/auth/resend_code/ |
| Forgot password (step 1) | POST /users/auth/verify_reset_email/ |
| Forgot password (step 2) | POST /users/auth/verify_reset_code/ |
| Forgot password (step 3) | POST /users/auth/forget_password/ |
| Create patient profile | POST /patients/PatientService/create_patient/ |
| Create doctor profile | POST /doctors/DoctorService/create_doctor/ |
| Token refresh | POST /users/refresh/ |

## User Flow

```
Splash → Login ─────────────────────────────────────→ PatientHome / DoctorHome
           ↓                                                    ↑
        Register → VerifyCode → ProfileSelection → PatientSetup/DoctorSetup
           ↓
        ForgotPassword → VerifyCode → ResetPassword → Login
```
