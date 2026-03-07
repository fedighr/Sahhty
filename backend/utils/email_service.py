from django.core.mail import EmailMultiAlternatives
from django.core.mail import BadHeaderError
import os

def send_verification_email(user_email, code, expires_at):

    try:
        
        subject = 'Your Verification Code'
        text_content = f'Your verification code is: {code}'
        html_content = f'''
            <div style="font-family: Arial, sans-serif; padding: 20px;">
                <h2>Email Verification</h2>
                <p>Your verification code is:</p>
                <h1 style="color: #2196F3;">{code}</h1>
                <p>This code expires at {expires_at}.</p>
            </div>
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