# 🚨 Problèmes Backend à corriger

Ce document liste les problèmes identifiés dans le backend Django qui empêchent le frontend de fonctionner correctement. **Merci de les corriger quand possible.**

---

## ✅ RÉSOLU — `patient_id` dans le JWT

**Fichier**: `users/services.py` → `AuthService.login()`
Le JWT contient maintenant `patient_id` et `doctor_id`. Le frontend les extrait et les sauvegarde lors du login. ✅

---

## ✅ RÉSOLU — Le serializer Alert inclut `level` et utilise `status` en minuscule

**Fichier**: `alerts/serializers.py` → `AlertSerializer`
Les `fields` incluent maintenant `level` et utilisent `status` (minuscule). ✅

---

## ✅ RÉSOLU — `register_device` utilise `IsAuthenticated`

**Fichier**: `users/views.py` → `FCMDeviceView.register_device()`
Le endpoint utilise maintenant `IsAuthenticated` comme permission. ✅

---

## ✅ RÉSOLU — `best_model.pkl` ajouté

**Fichier**: `ml_engine/best_model.pkl`
Le fichier a été ajouté au repo. ✅

---

## 🟡 IMPORTANT — `getPatientById` ne retourne pas l'`id` du patient

**Fichier**: `patients/services.py` → `PatientService.getPatientById()`
**Problème**: Le dictionnaire `data` retourné ne contient pas `'id': patient.id`. Le frontend lit `json['id']` et reçoit `null`.

**Impact**: Le frontend ne peut pas utiliser l'ID patient retourné par ce endpoint. Actuellement contourné car le `patient_id` est extrait du JWT lors du login.

**Solution**: Ajouter `'id': patient.id,` dans le dictionnaire `data` :
```python
data = {
    'id': patient.id,  # ← Ajouter cette ligne
    'first_name': patient.user.first_name,
    ...
}
```

---

## 🟡 IMPORTANT — `createPatient` ne retourne pas l'ID créé

**Fichier**: `patients/services.py` → `PatientService.createPatient()`
**Problème**: Retourne `{success: True, message: 'Patient created successfully'}` sans l'`id` du patient créé.

**Impact**: Après l'inscription, le frontend ne peut pas connaître le `patient_id` sans relancer un login.

**Solution**: Ajouter `'patient_id': patient.id` dans la réponse :
```python
return {'data': {'success': True, 'message': 'Patient created successfully', 'patient_id': patient.id}, 'status': 201}
```

---

## 🟢 EN COURS — `global_risk_percentage` dans le serializer mais pas dans le modèle

**Fichier**: `measurements/serializers.py` → `RiskAssessmentSerializer`
**Problème**: Le champ `global_risk_percentage` était listé dans les `fields` du serializer, mais il n'existe pas dans le modèle `RiskAssessment`. Ton ami est en train de corriger ça.

**Note**: Le frontend gère déjà le cas où ce champ est absent (valeur par défaut 0.0).

---

## 🟢 MINEUR — Endpoints `appointments` non implémentés

**Fichier**: `appointments/urls.py` (vide), `appointments/views.py` (vide)
**Problème**: Le module appointments n'a pas d'API REST exposée.

**Impact**: Le frontend affiche une liste vide pour les rendez-vous. Le frontend gère ce cas gracieusement.

**Solution**: Implémenter les endpoints CRUD pour les rendez-vous quand c'est prêt.

---

## 🟢 MINEUR — Module `medical_files` non implémenté

**Problème**: Aucun endpoint REST. Le frontend affiche un écran vide pour le dossier médical.
