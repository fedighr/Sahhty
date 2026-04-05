# 🚨 Problèmes Backend à corriger

Ce document liste les problèmes identifiés dans le backend Django qui empêchent le frontend de fonctionner correctement. **Merci de les corriger quand possible.**

---

## 🔴 CRITIQUE — Le backend ne démarre pas

**Fichier**: `ml_engine/predictor.py`
**Erreur**: `FileNotFoundError: No such file or directory: 'C:\Sahhty\backend\ml_engine\best_model.pkl'`

Le fichier `best_model.pkl` est absent du dossier `ml_engine/`. Sans ce fichier, le serveur crashe au démarrage quand il essaie d'importer `measurements.views`.

**Solution**: Ajouter le fichier `best_model.pkl` dans `ml_engine/`, ou rendre l'import conditionnel pour que le serveur puisse démarrer même sans le modèle ML.

---

## 🔴 CRITIQUE — Le login ne retourne pas le `patient_id`

**Fichier**: `users/services.py` → `AuthService.login()`
**Problème**: La réponse de login retourne `{ success, access, refresh }` mais **pas** le `patient_id` (PK de la table Patient). 

Le JWT contient `user_id` (PK de User), mais les endpoints patient/pregnancy/measurements utilisent le **Patient PK** qui est différent du User PK.

**Impact**: Le frontend ne peut pas charger les données patient après le login car il ne connaît pas le bon patient_id.

**Solution proposée**: Ajouter `patient_id` dans la réponse de login :
```python
# Dans AuthService.login(), après la génération du token :
patient = Patient.objects.filter(user=user).first()
return {
    'data': {
        'success': True,
        'access': str(token.access_token),
        'refresh': str(token),
        'patient_id': patient.id if patient else None,
    },
    'status': 200
}
```

---

## 🟡 IMPORTANT — `getPatientById` ne retourne pas l'`id` du patient

**Fichier**: `patients/services.py` → `PatientService.getPatientById()`
**Problème**: Le dictionnaire retourné ne contient pas `'id': patient.id`. Le frontend a besoin de cet ID pour les requêtes suivantes.

**Solution**: Ajouter `'id': patient.id,` dans le dictionnaire `data`.

---

## 🟡 IMPORTANT — Le serializer Alert n'inclut pas le champ `level`

**Fichier**: `alerts/serializers.py` → `AlertSerializer`
**Problème**: Les `fields` sont `['id', 'type', 'message', 'Status', 'created_at', 'user_id', 'user']`. Le champ `level` (INFO/WARNING/CRITICAL) n'est **pas inclus**, donc le frontend ne reçoit jamais le niveau d'alerte.

**Solution**: Ajouter `'level'` dans les fields :
```python
fields = ['id', 'type', 'message', 'level', 'Status', 'created_at', 'user_id', 'user']
```

---

## 🟡 IMPORTANT — Le serializer Alert utilise 'Status' avec un S majuscule

**Fichier**: `alerts/serializers.py` → `AlertSerializer`
**Problème**: Le champ est défini comme `'Status'` dans les fields, mais le modèle utilise `status` (minuscule). La convention REST standard est en minuscule.

**Note**: Le frontend gère déjà les deux cas (`json['Status'] ?? json['status']`), mais la correction côté backend serait plus propre.

---

## 🟢 MINEUR — `RiskAssessment` : `global_risk_percentage` dans le serializer mais pas dans le modèle

**Fichier**: `measurements/serializers.py` → `RiskAssessmentSerializer`
**Problème**: Le champ `global_risk_percentage` est listé dans les `fields` du serializer, mais il **n'existe pas** dans le modèle `RiskAssessment`.

**Solution**: Soit ajouter le champ au modèle, soit le retirer du serializer.

---

## 🟢 MINEUR — `createPatient` ne retourne pas l'ID créé

**Fichier**: `patients/services.py` → `PatientService.createPatient()`
**Problème**: Retourne `{success: True, message: 'Patient created successfully'}` sans l'`id` du patient créé.

**Solution**: Ajouter `'patient_id': patient.id` dans la réponse.

---

## 🟢 MINEUR — `register_device` a `AllowAny` mais utilise `request.user`

**Fichier**: `users/views.py` → `FCMDeviceView.register_device()`
**Problème**: La permission est `AllowAny` mais le code fait `defaults={'user': request.user}`. Si appelé sans authentification, `request.user` sera `AnonymousUser`, ce qui causera une erreur IntegrityError (FK NOT NULL).

**Solution**: Soit changer `AllowAny` en `IsAuthenticated`, soit vérifier que `request.user.is_authenticated` avant de sauvegarder.
