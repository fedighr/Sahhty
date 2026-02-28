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