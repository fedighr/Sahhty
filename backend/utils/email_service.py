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
        'label':       'Email Verification',
        'subject':     '🔐 Your Verification Code',
    }

    try:
        subject = cfg['subject']
        text_content = f'Your verification code is: {code}. It expires at {formatted_expires}.'
        html_content = f'''
<!DOCTYPE html>
<html lang="en">
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
                Verify your email address
              </h2>

              <!-- Code box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Use the following code to verify your email address. Please do not share this code with anyone.
                </p>
                <div style="text-align:center;margin:20px 0;">
                  <span style="display:inline-block;background-color:#eef2ff;border:2px dashed {cfg["border"]};border-radius:10px;padding:16px 40px;font-size:32px;font-weight:800;letter-spacing:8px;color:#5a67d8;">
                    {code}
                  </span>
                </div>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Expires at</span>
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
                If you did not request this code, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                This is an automated message from <strong>Sahty</strong>. Please do not reply to this email.
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
            'label':       'Critical Alert',
            'subject':     '🔴 Critical Health Alert',
        },
        'WARNING': {
            'bg':          '#fffbeb',
            'border':      '#d69e2e',
            'header_bg':   '#d69e2e',
            'badge_bg':    '#b7791f',
            'badge_text':  '#ffffff',
            'icon':        '🟡',
            'label':       'Warning',
            'subject':     '🟡 Health Warning',
        },
        'INFO': {
            'bg':          '#ebf8ff',
            'border':      '#3182ce',
            'header_bg':   '#3182ce',
            'badge_bg':    '#2b6cb0',
            'badge_text':  '#ffffff',
            'icon':        '🔵',
            'label':       'Info',
            'subject':     '🔵 Health Notification',
        },
    }

    cfg = LEVEL_CONFIG.get(level.upper(), LEVEL_CONFIG['INFO'])

    try:
        subject = cfg['subject']
        text_content = f'[{cfg["label"]}] {alert_message}'
        html_content = f'''
<!DOCTYPE html>
<html lang="en">
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
                Sahty Health Alert
              </p>
              <h2 style="margin:0 0 20px;font-size:18px;color:#2d3748;">
                You have a new health notification
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
                Please review this alert in your Sahty app and take appropriate action if needed.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                This is an automated message from <strong>Sahty</strong>. Please do not reply to this email.
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
        'label':       'Medication Reminder',
        'subject':     '💊 Time to take your medication',
    }

    try:
        subject = cfg['subject']
        text_content = f"Reminder: Take your {medication_name} at {dose_time}"
        html_content = f'''
<!DOCTYPE html>
<html lang="en">
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
                Hello {first_name} 👋
              </h2>

              <!-- Reminder box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  This is a friendly reminder to take your medication:
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;">
                      <span style="font-size:13px;color:#718096;">Medication</span>
                    </td>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;text-align:right;">
                      <strong style="font-size:14px;color:#2d3748;">{medication_name}</strong>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Scheduled time</span>
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
                Please mark your medication as taken in the Sahty app after you have taken it.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                This is an automated message from <strong>Sahty</strong>. Please do not reply to this email.
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
        'label':       'Appointment Reminder',
        'subject':     '📅 Upcoming Appointment Reminder',
    }

    try:
        subject = cfg['subject']
        text_content = f"Reminder: You have an appointment with Dr. {doctor_name} on {appointment_date}"
        html_content = f'''
<!DOCTYPE html>
<html lang="en">
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
                Hello {patient_name} 👋
              </h2>

              <!-- Reminder box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  This is a friendly reminder about your upcoming appointment:
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;">
                      <span style="font-size:13px;color:#718096;">Doctor</span>
                    </td>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;text-align:right;">
                      <strong style="font-size:14px;color:#2d3748;">Dr. {doctor_name}</strong>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Appointment Date</span>
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
                Please make sure to be on time for your appointment. You can manage your appointments in the Sahty app.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                This is an automated message from <strong>Sahty</strong>. Please do not reply to this email.
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
        'label':       'Measurement Update Needed',
        'subject':     '📊 You have missing health measurements',
    }

    try:
        subject = cfg['subject']
        text_content = f"Hi {patient_name}, you have not updated the following measurements for more than a week: {missing_measurements}. Please log in to the Sahty app and update them."
        html_content = f'''
<!DOCTYPE html>
<html lang="en">
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
                Hello {patient_name} 👋
              </h2>

              <!-- Alert box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  It looks like you haven't updated the following health measurements for <strong>more than a week</strong>. Keeping your data up to date helps us provide better care for you.
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Missing Measurements</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#dd6b20;">⚠️ {missing_measurements}</strong>
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
                Please open the Sahty app and log your measurements to keep your health record accurate and up to date.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                This is an automated message from <strong>Sahty</strong>. Please do not reply to this email.
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
        'label':       'Appointment Pending Confirmation',
        'subject':     '⏳ Your appointment is not confirmed yet',
    }
    doctor_cfg = {
        'bg':          '#e6fffa',
        'border':      '#319795',
        'header_bg':   '#319795',
        'badge_bg':    '#2c7a7b',
        'badge_text':  '#ffffff',
        'icon':        '🔔',
        'label':       'Action Required',
        'subject':     '🔔 Appointment awaiting your confirmation',
    }

    try:
        # --- Email to patient ---
        patient_text = f"Hi {patient_name}, your appointment with Dr. {doctor_name} on {appointment_date} is still pending confirmation. Please check back later or contact us for more information."
        patient_html = f'''
<!DOCTYPE html>
<html lang="en">
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
                Hello {patient_name} 👋
              </h2>

              <!-- Info box -->
              <div style="background-color:#ffffff;border-left:5px solid {patient_cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  Your upcoming appointment is <strong>still pending confirmation</strong> from the doctor. Please check back later or contact us if needed.
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;">
                      <span style="font-size:13px;color:#718096;">Doctor</span>
                    </td>
                    <td style="padding:8px 0;border-bottom:1px solid #e2e8f0;text-align:right;">
                      <strong style="font-size:14px;color:#2d3748;">Dr. {doctor_name}</strong>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Appointment Date</span>
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
                You can check your appointment status anytime in the Sahty app.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                This is an automated message from <strong>Sahty</strong>. Please do not reply to this email.
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
        doctor_text = f"Dear Dr. {doctor_name}, there is a pending appointment with patient {patient_name} on {appointment_date} that requires your confirmation."
        doctor_html = f'''
<!DOCTYPE html>
<html lang="en">
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
                Dear Dr. {doctor_name} 👋
              </h2>

              <!-- Info box -->
              <div style="background-color:#ffffff;border-left:5px solid {doctor_cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  You have an appointment scheduled for <strong>tomorrow</strong> that is still awaiting your confirmation. Please review and confirm it as soon as possible.
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
                      <span style="font-size:13px;color:#718096;">Appointment Date</span>
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
                Please log in to the Sahty app to confirm or manage this appointment.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                This is an automated message from <strong>Sahty</strong>. Please do not reply to this email.
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
        'label':       'Prenatal Care Reminder',
        'subject':     '🤰 Schedule your prenatal appointment',
    }

    try:
        subject = cfg['subject']
        text_content = f"Hi {patient_name}, we noticed you haven't booked a prenatal appointment in the last 2 weeks. Please schedule a check-up to ensure the health of you and your baby."
        html_content = f'''
<!DOCTYPE html>
<html lang="en">
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
                Hello {patient_name} 👋
              </h2>

              <!-- Alert box -->
              <div style="background-color:#ffffff;border-left:5px solid {cfg["border"]};border-radius:8px;padding:20px 24px;margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <p style="margin:0 0 12px;font-size:15px;color:#2d3748;line-height:1.7;">
                  We noticed that you haven't booked a prenatal appointment in the <strong>last 2 weeks</strong>. Regular check-ups are essential during pregnancy to monitor the health of both you and your baby.
                </p>
                <table cellpadding="0" cellspacing="0" width="100%">
                  <tr>
                    <td style="padding:8px 0;">
                      <span style="font-size:13px;color:#718096;">Status</span>
                    </td>
                    <td style="padding:8px 0;text-align:right;">
                      <strong style="font-size:14px;color:#d53f8c;">⚠️ No appointment in the last 2 weeks</strong>
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
                Please open the Sahty app to book your next prenatal appointment. Your health and your baby's health are our priority.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#edf2f7;padding:18px 32px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;font-size:12px;color:#718096;">
                This is an automated message from <strong>Sahty</strong>. Please do not reply to this email.
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