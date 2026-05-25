from django.core.mail import EmailMultiAlternatives
from django.core.mail import BadHeaderError
import os

def send_verification_email(user_email, code, expires_at):
    try:
        formatted_expires = expires_at.strftime('%Y-%m-%d %H:%M')
    except AttributeError:
        formatted_expires = str(expires_at)

    cfg = {
        'bg':          '#eef2ff',
        'border':      '#5a67d8',
        'header_bg':   '#5a67d8',
        'badge_bg':    '#4c51bf',
        'badge_text':  '#ffffff',
        'icon':        '🔐',
      'label':       'Vérification de l’adresse e-mail',
      'subject':     '🔐 Votre code de vérification',
    }

    try:
        subject = cfg['subject']
        text_content = f'Votre code de vérification est : {code}. Il expire le {formatted_expires}.'
        html_content = f'''
<!DOCTYPE html>
    <html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:{cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {cfg["label"]}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Vérifiez votre adresse e-mail
              </h2>

              <!-- Code box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Utilisez le code ci-dessous pour vérifier votre adresse e-mail. Ne partagez pas ce code avec qui que ce soit.
                </p>
                <div style="text-align:center;margin:20px 0;">
                  <span style="display:inline-block;background-color:#eef2ff;border:2px dashed {cfg["border"]};border-radius:10px;padding:16px 40px;font-size:32px;font-weight:800;letter-spacing:8px;color:#5a67d8;">
                    {code}
                  </span>
                </div>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Expire le</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#5a67d8;">⏰ {formatted_expires}</strong>
                    </td>
                  </tr>
                </table>
              </div>

              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      {cfg["label"]}
                    </span>
                  </td>
                </tr>
              </table>

              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Si vous n’avez pas demandé ce code, vous pouvez ignorer cet e-mail en toute sécurité.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        email = EmailMultiAlternatives(subject, text_content, os.getenv('DEFAULT_FROM_EMAIL'), [user_email])
        email.attach_alternative(html_content, "text/html")
        email.send()
        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Email error: {e}")
        return False

def send_lockout_email(user_email):
    cfg = {
        'bg':          '#fff5f5',
        'border':      '#e53e3e',
        'header_bg':   '#e53e3e',
        'badge_bg':    '#c53030',
        'badge_text':  '#ffffff',
        'icon':        '🔒',
    'label':       'Compte bloqué',
    'subject':     '🔒 Votre compte a été temporairement bloqué',
    }

    try:
        subject = cfg['subject']
        text_content = 'Votre compte a été temporairement bloqué pendant 15 minutes en raison de plusieurs tentatives de connexion échouées.'
        html_content = f'''
<!DOCTYPE html>
    <html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:{cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {cfg["label"]}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Activité suspecte détectée
              </h2>

              <!-- Message box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Votre compte a été temporairement bloqué pendant <strong>15 minutes</strong> en raison de plusieurs tentatives de connexion échouées.
                </p>
                <p style="margin:0;font-size:15px;color:#2d3748;line-height:1.7;">
                  Si c’était vous, veuillez patienter 15 minutes puis réessayer. Si ce n’était pas vous, nous vous recommandons de réinitialiser votre mot de passe immédiatement.
                </p>
              </div>

              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      {cfg["label"]}
                    </span>
                  </td>
                </tr>
              </table>

              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Si vous n’avez pas tenté de vous connecter, veuillez contacter le support immédiatement.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        email = EmailMultiAlternatives(subject, text_content, os.getenv('DEFAULT_FROM_EMAIL'), [user_email])
        email.attach_alternative(html_content, "text/html")
        email.send()
        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Email error: {e}")
        return False

def send_alert_email(user_email, alert_message, level='INFO', alert_type=''):

    LEVEL_CONFIG = {
        'CRITICAL': {
            'bg':          '#fff5f5',
            'border':      '#e53e3e',
            'header_bg':   '#e53e3e',
            'badge_bg':    '#c53030',
            'badge_text':  '#ffffff',
            'icon':        '🔴',
        'label':       'Alerte critique',
        'subject':     '🔴 Alerte santé critique',
        },
        'WARNING': {
            'bg':          '#fffbeb',
            'border':      '#d69e2e',
            'header_bg':   '#d69e2e',
            'badge_bg':    '#b7791f',
            'badge_text':  '#ffffff',
            'icon':        '🟡',
        'label':       'Avertissement',
        'subject':     '🟡 Avertissement santé',
        },
        'INFO': {
            'bg':          '#ebf8ff',
            'border':      '#3182ce',
            'header_bg':   '#3182ce',
            'badge_bg':    '#2b6cb0',
            'badge_text':  '#ffffff',
            'icon':        '🔵',
        'label':       'Information',
        'subject':     '🔵 Notification de santé',
        },
    }

    cfg = LEVEL_CONFIG.get(level.upper(), LEVEL_CONFIG['INFO'])

    try:
        subject = cfg['subject']
        text_content = f'[{cfg["label"]}] {alert_message}'
        html_content = f'''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:{cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {cfg["label"]}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Alerte Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Vous avez une nouvelle notification de santé
              </h2>

              <!-- Alert message box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0;font-size:15px;color:#2d3748;line-height:1.7;">
                  {alert_message}
                </p>
              </div>

              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      {cfg["label"]}
                    </span>
                  </td>
                  {'<td style="width:12px;"></td><td style="background-color:#e2e8f0;border-radius:20px;padding:6px 16px;"><span style="color:#4a5568;font-size:12px;font-weight:600;">' + alert_type.replace('_', ' ').title() + '</span></td>' if alert_type else ''}
                </tr>
              </table>

              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Veuillez consulter cette alerte dans l’application Sahty et prendre les mesures nécessaires si besoin.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        email = EmailMultiAlternatives(subject, text_content, os.getenv('DEFAULT_FROM_EMAIL'), [user_email])
        email.attach_alternative(html_content, "text/html")
        email.send()
        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Email error: {e}")
        return False

def send_medication_reminder_email(email, medication_name, first_name, dose_time):
    cfg = {
        'bg':          '#f0fff4',
        'border':      '#38a169',
        'header_bg':   '#38a169',
        'badge_bg':    '#276749',
        'badge_text':  '#ffffff',
        'icon':        '💊',
    'label':       'Rappel de médicament',
    'subject':     '💊 Il est temps de prendre votre médicament',
    }

    try:
        subject = cfg['subject']
        text_content = f"Rappel : prenez votre {medication_name} à {dose_time}"
        html_content = f'''
<!DOCTYPE html>
    <html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:{cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {cfg["label"]}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Bonjour {first_name} 👋
              </h2>

              <!-- Reminder box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Ceci est un rappel amical pour prendre votre médicament :
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;">
                      <span style="font-size:13px;color:#718096;">Médicament</span>
                    </td>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;text-align:right;">
                      <strong style="font-size:14px;color:#2d3748;">{medication_name}</strong>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Heure prévue</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#38a169;">🕐 {dose_time}</strong>
                    </td>
                  </tr>
                </table>
              </div>

              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      {cfg["label"]}
                    </span>
                  </td>
                </tr>
              </table>

              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Après l’avoir pris, merci d’indiquer dans l’application Sahty que votre médicament a été pris.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        email_msg = EmailMultiAlternatives(subject, text_content, os.getenv('DEFAULT_FROM_EMAIL'), [email])
        email_msg.attach_alternative(html_content, "text/html")
        email_msg.send()
        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Email error: {e}")
        return False        

def send_appointment_reminder_email(patient_email, patient_name, doctor_name, appointment_date):
    cfg = {
        'bg':          '#faf5ff',
        'border':      '#805ad5',
        'header_bg':   '#805ad5',
        'badge_bg':    '#553c9a',
        'badge_text':  '#ffffff',
        'icon':        '📅',
    'label':       'Rappel de rendez-vous',
    'subject':     '📅 Rappel : rendez-vous à venir',
    }

    try:
        subject = cfg['subject']
        text_content = f"Rappel : vous avez un rendez-vous avec Dr. {doctor_name} le {appointment_date}"
        html_content = f'''
<!DOCTYPE html>
    <html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:{cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {cfg["label"]}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Bonjour {patient_name} 👋
              </h2>

              <!-- Reminder box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Ceci est un rappel amical concernant votre rendez-vous à venir :
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;">
                      <span style="font-size:13px;color:#718096;">Médecin</span>
                    </td>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;text-align:right;">
                      <strong style="font-size:14px;color:#2d3748;">Dr. {doctor_name}</strong>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Date du rendez-vous</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#805ad5;">🗓️ {appointment_date}</strong>
                    </td>
                  </tr>
                </table>
              </div>

              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      {cfg["label"]}
                    </span>
                  </td>
                </tr>
              </table>

              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Merci d’être à l’heure pour votre rendez-vous. Vous pouvez gérer vos rendez-vous dans l’application Sahty.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        email_msg = EmailMultiAlternatives(subject, text_content, os.getenv('DEFAULT_FROM_EMAIL'), [patient_email])
        email_msg.attach_alternative(html_content, "text/html")
        email_msg.send()
        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Email error: {e}")
        return False

def send_missing_measurement_email(patient_email, patient_name, missing_measurements):
    cfg = {
        'bg':          '#fffaf0',
        'border':      '#dd6b20',
        'header_bg':   '#dd6b20',
        'badge_bg':    '#c05621',
        'badge_text':  '#ffffff',
        'icon':        '📊',
    'label':       'Mise à jour des mesures requise',
    'subject':     '📊 Vous avez des mesures de santé manquantes',
    }

    try:
        subject = cfg['subject']
        measurement_translations = {
            'BLOOD_PRESSURE': 'Tension artérielle',
            'WEIGHT': 'Poids',
            'GLYCEMIA': 'Glycémie',
        }

        try:
            parts = [p.strip() for p in str(missing_measurements).split(',')]
            translated_parts = [
                measurement_translations.get(p, p.replace('_', ' ').title())
                for p in parts
                if p
            ]
            missing_measurements_fr = (
                ', '.join(translated_parts) if translated_parts else str(missing_measurements)
            )
        except Exception:
            missing_measurements_fr = str(missing_measurements)

        text_content = (
            f"Bonjour {patient_name}, vous n’avez pas mis à jour les mesures suivantes depuis plus d’une semaine : "
            f"{missing_measurements_fr}. Veuillez ouvrir l’application Sahty et les mettre à jour."
        )
        html_content = f'''
<!DOCTYPE html>
  <html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:{cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {cfg["label"]}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Bonjour {patient_name} 👋
              </h2>

              <!-- Alert box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Il semble que vous n’ayez pas mis à jour les mesures de santé suivantes depuis <strong>plus d’une semaine</strong>. Garder vos données à jour nous aide à mieux vous accompagner.
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Mesures manquantes</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#dd6b20;">⚠️ {missing_measurements_fr}</strong>
                    </td>
                  </tr>
                </table>
              </div>

              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      {cfg["label"]}
                    </span>
                  </td>
                </tr>
              </table>

              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Veuillez ouvrir l’application Sahty et enregistrer vos mesures afin de garder votre dossier de santé exact et à jour.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        email_msg = EmailMultiAlternatives(subject, text_content, os.getenv('DEFAULT_FROM_EMAIL'), [patient_email])
        email_msg.attach_alternative(html_content, "text/html")
        email_msg.send()
        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Email error: {e}")
        return False

def send_unconfirmed_appointment_email(patient_email, patient_name, doctor_name, doctor_email, appointment_date):
    patient_cfg = {
        'bg':          '#e6fffa',
        'border':      '#319795',
        'header_bg':   '#319795',
        'badge_bg':    '#2c7a7b',
        'badge_text':  '#ffffff',
        'icon':        '⏳',
    'label':       'Rendez-vous en attente de confirmation',
    'subject':     '⏳ Votre rendez-vous n’est pas encore confirmé',
    }
    doctor_cfg = {
        'bg':          '#e6fffa',
        'border':      '#319795',
        'header_bg':   '#319795',
        'badge_bg':    '#2c7a7b',
        'badge_text':  '#ffffff',
        'icon':        '🔔',
    'label':       'Action requise',
    'subject':     '🔔 Rendez-vous en attente de votre confirmation',
    }

    try:
        # --- Email to patient ---
        patient_text = (
            f"Bonjour {patient_name}, votre rendez-vous avec Dr. {doctor_name} le {appointment_date} "
            f"est toujours en attente de confirmation. Merci de réessayer plus tard ou de nous contacter pour plus d’informations."
        )
        patient_html = f'''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{patient_cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {patient_cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:{patient_cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{patient_cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {patient_cfg["label"]}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Bonjour {patient_name} 👋
              </h2>

              <!-- Info box -->
              <div style="background-color:#ffffff;border-left:5px solid {patient_cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Votre rendez-vous à venir est <strong>toujours en attente de confirmation</strong> de la part du médecin. Merci de réessayer plus tard ou de nous contacter si besoin.
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;">
                      <span style="font-size:13px;color:#718096;">Médecin</span>
                    </td>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;text-align:right;">
                      <strong style="font-size:14px;color:#2d3748;">Dr. {doctor_name}</strong>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Date du rendez-vous</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#319795;">🗓️ {appointment_date}</strong>
                    </td>
                  </tr>
                </table>
              </div>

              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{patient_cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{patient_cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      {patient_cfg["label"]}
                    </span>
                  </td>
                </tr>
              </table>

              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Vous pouvez consulter le statut de votre rendez-vous à tout moment dans l’application Sahty.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        patient_msg = EmailMultiAlternatives(patient_cfg['subject'], patient_text, os.getenv('DEFAULT_FROM_EMAIL'), [patient_email])
        patient_msg.attach_alternative(patient_html, "text/html")
        patient_msg.send()

        # --- Email to doctor ---
        doctor_text = (
            f"Bonjour Dr. {doctor_name}, un rendez-vous avec le patient {patient_name} le {appointment_date} "
            f"est en attente de votre confirmation."
        )
        doctor_html = f'''
<!DOCTYPE html>
      <html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{doctor_cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {doctor_cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:{doctor_cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{doctor_cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {doctor_cfg["label"]}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Bonjour Dr. {doctor_name} 👋
              </h2>

              <!-- Info box -->
              <div style="background-color:#ffffff;border-left:5px solid {doctor_cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Vous avez un rendez-vous prévu pour <strong>demain</strong> qui est toujours en attente de votre confirmation. Merci de le consulter et de le confirmer dès que possible.
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;">
                      <span style="font-size:13px;color:#718096;">Patient</span>
                    </td>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;text-align:right;">
                      <strong style="font-size:14px;color:#2d3748;">{patient_name}</strong>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Date du rendez-vous</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#319795;">🗓️ {appointment_date}</strong>
                    </td>
                  </tr>
                </table>
              </div>

              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{doctor_cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{doctor_cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      {doctor_cfg["label"]}
                    </span>
                  </td>
                </tr>
              </table>

              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Veuillez ouvrir l’application Sahty pour confirmer ou gérer ce rendez-vous.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        doctor_msg = EmailMultiAlternatives(doctor_cfg['subject'], doctor_text, os.getenv('DEFAULT_FROM_EMAIL'), [doctor_email])
        doctor_msg.attach_alternative(doctor_html, "text/html")
        doctor_msg.send()

        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Email error: {e}")
        return False

def send_pregnancy_no_appointment_email(patient_email, patient_name):
    cfg = {
        'bg':          '#fff5f7',
        'border':      '#d53f8c',
        'header_bg':   '#d53f8c',
        'badge_bg':    '#b83280',
        'badge_text':  '#ffffff',
        'icon':        '🤰',
    'label':       'Rappel de suivi prénatal',
    'subject':     '🤰 Planifiez votre rendez-vous prénatal',
    }

    try:
        subject = cfg['subject']
        text_content = (
            f"Bonjour {patient_name}, nous avons remarqué que vous n’avez pas pris de rendez-vous prénatal "
            f"au cours des 2 dernières semaines. Veuillez planifier un contrôle afin d’assurer votre santé et celle de votre bébé."
        )
        html_content = f'''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:{cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {cfg["label"]}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Bonjour {patient_name} 👋
              </h2>

              <!-- Alert box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Nous avons remarqué que vous n’avez pas pris de rendez-vous prénatal au cours des <strong>2 dernières semaines</strong>. Des contrôles réguliers sont essentiels pendant la grossesse pour surveiller votre santé et celle de votre bébé.
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Statut</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#d53f8c;">⚠️ Aucun rendez-vous au cours des 2 dernières semaines</strong>
                    </td>
                  </tr>
                </table>
              </div>

              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      {cfg["label"]}
                    </span>
                  </td>
                </tr>
              </table>

              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Veuillez ouvrir l’application Sahty pour réserver votre prochain rendez-vous prénatal. Votre santé et celle de votre bébé sont notre priorité.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        email_msg = EmailMultiAlternatives(subject, text_content, os.getenv('DEFAULT_FROM_EMAIL'), [patient_email])
        email_msg.attach_alternative(html_content, "text/html")
        email_msg.send()
        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Email error: {e}")
        return False

def send_appointment_notification_email(doctor_email, patient_name, appointment_datetime):
    """
    Sent to the doctor when a patient books an appointment.
    Action (confirm/decline) is done in the app.
    """
    try:
      formatted_dt = appointment_datetime.strftime('%d/%m/%Y à %H:%M')
    except AttributeError:
        formatted_dt = str(appointment_datetime)
 
    cfg = {
        'bg':         '#f0fff4',
        'border':     '#38a169',
        'header_bg':  '#38a169',
        'badge_bg':   '#276749',
        'badge_text': '#ffffff',
        'icon':       '📅',
      'label':      'Nouvelle demande de rendez-vous',
      'subject':    '📅 Nouvelle demande de rendez-vous',
    }
 
    try:
        text_content = (
            f'Vous avez une nouvelle demande de rendez-vous de la part de {patient_name} '
            f'prévue le {formatted_dt}. Veuillez ouvrir l’application pour confirmer ou refuser.'
        )
        html_content = f'''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">
 
          <!-- Header -->
          <tr>
            <td style="background-color:{cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {cfg["label"]}
              </h1>
            </td>
          </tr>
 
          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Vous avez une nouvelle demande de rendez-vous
              </h2>
 
              <!-- Info box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 16px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Un patient a demandé un rendez-vous avec vous. Veuillez ouvrir l’application pour confirmer ou refuser.
                </p>
 
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;">
                      <span style="font-size:13px;color:#718096;">Patient</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;border-bottom:1px solid #e2e8f0;">
                      <strong style="font-size:14px;color:#2d3748;">👤 {patient_name}</strong>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Date et heure</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#38a169;">🕐 {formatted_dt}</strong>
                    </td>
                  </tr>
                </table>
              </div>
 
              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      Action requise dans l’application
                    </span>
                  </td>
                </tr>
              </table>
 
              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Ouvrez l’application Sahty pour gérer cette demande de rendez-vous.
              </p>
            </td>
          </tr>
 
          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>
 
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        msg = EmailMultiAlternatives(
            cfg['subject'], text_content,
            os.getenv('DEFAULT_FROM_EMAIL'), [doctor_email]
        )
        msg.attach_alternative(html_content, "text/html")
        msg.send()
        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Appointment email error: {e}")
        return False
 
 
def send_access_request_email(patient_email, doctor_name, specialty, request_date):
    """
    Sent to the patient when a doctor requests access to their health data.
    Action (approve/decline) is done in the app.
    """
    try:
      formatted_date = request_date.strftime('%d/%m/%Y à %H:%M')
    except AttributeError:
        formatted_date = str(request_date)
 
    cfg = {
        'bg':         '#fffaf0',
        'border':     '#dd6b20',
        'header_bg':  '#dd6b20',
        'badge_bg':   '#9c4221',
        'badge_text': '#ffffff',
        'icon':       '🔓',
      'label':      'Demande d’accès du médecin',
      'subject':    '🔓 Un médecin a demandé l’accès à vos données',
    }
 
    try:
        text_content = (
            f'Dr. {doctor_name} ({specialty}) a demandé l’accès à vos données de santé '
            f'le {formatted_date}. Veuillez ouvrir l’application pour accepter ou refuser.'
        )
        html_content = f'''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">
 
          <!-- Header -->
          <tr>
            <td style="background-color:{cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {cfg["label"]}
              </h1>
            </td>
          </tr>
 
          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Un médecin souhaite accéder à vos données de santé
              </h2>
 
              <!-- Info box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 16px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Le médecin suivant a demandé l’accès à votre dossier médical. Ouvrez l’application pour accepter ou refuser.
                </p>
 
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;">
                      <span style="font-size:13px;color:#718096;">Médecin</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;border-bottom:1px solid #e2e8f0;">
                      <strong style="font-size:14px;color:#2d3748;">👨‍⚕️ Dr. {doctor_name}</strong>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;">
                      <span style="font-size:13px;color:#718096;">Spécialité</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;border-bottom:1px solid #e2e8f0;">
                      <strong style="font-size:14px;color:#2d3748;">🏥 {specialty}</strong>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Demandé le</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#dd6b20;">🕐 {formatted_date}</strong>
                    </td>
                  </tr>
                </table>
              </div>
 
              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      Action requise dans l’application
                    </span>
                  </td>
                </tr>
              </table>
 
              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Si vous ne reconnaissez pas ce médecin, vous pouvez refuser en toute sécurité dans l’application.
              </p>
            </td>
          </tr>
 
          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>
 
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        msg = EmailMultiAlternatives(
            cfg['subject'], text_content,
            os.getenv('DEFAULT_FROM_EMAIL'), [patient_email]
        )
        msg.attach_alternative(html_content, "text/html")
        msg.send()
        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Access request email error: {e}")
        return False

def send_two_factor_code_email(user_email, code, expires_at):
    try:
        formatted_expires = expires_at.strftime('%Y-%m-%d %H:%M')
    except AttributeError:
        formatted_expires = str(expires_at)
    cfg = {
        'bg':          '#eef2ff',
        'border':      '#5a67d8',
        'header_bg':   '#5a67d8',
        'badge_bg':    '#4c51bf',
        'badge_text':  '#ffffff',
        'icon':        '🛡️',
        'label':       'Authentification à deux facteurs',
        'subject':     '🛡️ Votre code de connexion sécurisé',
    }

    try:
        subject = cfg['subject']
        text_content = f'Votre code d\'authentification à deux facteurs est : {code}. Il expire le {formatted_expires}.'
        html_content = f'''
<!DOCTYPE html>
    <html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background-color:#f7fafc;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7fafc;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:{cfg["bg"]};border-radius:12px;overflow:hidden;border:2px solid {cfg["border"]};box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:{cfg["header_bg"]};padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:36px;line-height:1;">{cfg["icon"]}</p>
              <h1 style="margin:10px 0 0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
                {cfg["label"]}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 8px;font-size:13px;color:#718096;text-transform:uppercase;letter-spacing:1px;font-weight:600;">
                Sahty Health
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                Connectez-vous en toute sécurité
              </h2>

              <!-- Code box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Utilisez le code à usage unique ci-dessous pour terminer votre connexion. Ne partagez jamais ce code.
                </p>
                <div style="text-align:center;margin:20px 0;">
                  <span style="display:inline-block;background-color:#eef2ff;border:2px dashed {cfg["border"]};border-radius:10px;padding:16px 40px;font-size:32px;font-weight:800;letter-spacing:8px;color:#5a67d8;">
                    {code}
                  </span>
                </div>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Expire le</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#5a67d8;">⏰ {formatted_expires}</strong>
                    </td>
                  </tr>
                </table>
              </div>

              <!-- Badge -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:{cfg["badge_bg"]};border-radius:20px;padding:6px 16px;">
                    <span style="color:{cfg["badge_text"]};font-size:12px;font-weight:700;letter-spacing:0.8px;text-transform:uppercase;">
                      {cfg["label"]}
                    </span>
                  </td>
                </tr>
              </table>

              <p style="margin:28px 0 0;font-size:13px;color:#a0aec0;">
                Si vous n’avez pas tenté de vous connecter, vous pouvez ignorer cet e-mail en toute sécurité.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                Ceci est un message automatique de <strong>Sahty</strong>. Merci de ne pas répondre à cet e-mail.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        '''
        email = EmailMultiAlternatives(subject, text_content, os.getenv('DEFAULT_FROM_EMAIL'), [user_email])
        email.attach_alternative(html_content, "text/html")
        email.send()
        return True
    except BadHeaderError:
        return False
    except Exception as e:
        print(f"Email error: {e}")
        return False
