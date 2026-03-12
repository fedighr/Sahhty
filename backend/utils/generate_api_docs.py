"""
Sahty API Documentation PDF Generator
Generates a beautifully styled PDF with all API endpoints
"""

from fpdf import FPDF
from datetime import datetime


class SahtyAPIDocs(FPDF):
    # ── Colors ──────────────────────────────────────
    PRIMARY = (42, 67, 101)        # Dark navy
    ACCENT = (90, 103, 216)        # Indigo
    SUCCESS = (56, 161, 105)       # Green
    WARNING = (214, 158, 46)       # Yellow
    DANGER = (229, 62, 62)         # Red
    INFO = (49, 130, 206)          # Blue
    LIGHT_BG = (247, 250, 252)     # Very light gray
    WHITE = (255, 255, 255)
    DARK_TEXT = (45, 55, 72)
    MEDIUM_TEXT = (74, 85, 104)
    LIGHT_TEXT = (160, 174, 192)
    TABLE_HEADER_BG = (237, 242, 247)
    TABLE_BORDER = (226, 232, 240)
    SECTION_BG = (235, 244, 254)
    
    # Method badge colors
    METHOD_COLORS = {
        'POST': (56, 161, 105),       # Green
        'GET': (49, 130, 206),         # Blue  
        'PATCH': (214, 158, 46),       # Yellow/Orange
        'DELETE': (229, 62, 62),       # Red
        'PUT': (128, 90, 213),         # Purple
    }

    def __init__(self):
        super().__init__()
        self.set_auto_page_break(auto=True, margin=25)

    # ── Header / Footer ────────────────────────────
    def header(self):
        if self.page_no() == 1:
            return
        self.set_fill_color(*self.PRIMARY)
        self.rect(0, 0, 210, 12, 'F')
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*self.WHITE)
        self.set_xy(10, 3)
        self.cell(0, 6, 'SAHTY API Documentation', align='L')
        self.set_font('Helvetica', '', 7)
        self.set_xy(10, 3)
        self.cell(0, 6, f'Page {self.page_no()}', align='R')
        self.ln(15)

    def footer(self):
        self.set_y(-15)
        self.set_draw_color(*self.TABLE_BORDER)
        self.line(10, self.get_y(), 200, self.get_y())
        self.set_font('Helvetica', 'I', 7)
        self.set_text_color(*self.LIGHT_TEXT)
        self.cell(0, 10, f'Generated on {datetime.now().strftime("%B %d, %Y at %H:%M")}  |  Sahty Health Monitoring Platform', align='C')

    # ── Cover Page ──────────────────────────────────
    def cover_page(self):
        self.add_page()
        # Background gradient effect
        self.set_fill_color(*self.PRIMARY)
        self.rect(0, 0, 210, 297, 'F')
        
        # Decorative circles
        self.set_fill_color(55, 80, 120)
        self.ellipse(140, 20, 100, 100, 'F')
        self.set_fill_color(50, 75, 115)
        self.ellipse(-20, 180, 80, 80, 'F')
        
        # Main title
        self.set_y(80)
        self.set_font('Helvetica', 'B', 42)
        self.set_text_color(*self.WHITE)
        self.cell(0, 20, 'SAHTY', align='C', new_x="LMARGIN", new_y="NEXT")
        
        # Subtitle
        self.set_font('Helvetica', '', 16)
        self.set_text_color(180, 200, 230)
        self.cell(0, 10, 'Health Monitoring Platform', align='C', new_x="LMARGIN", new_y="NEXT")
        
        # Divider line
        self.ln(5)
        self.set_draw_color(*self.ACCENT)
        self.set_line_width(0.8)
        self.line(70, self.get_y(), 140, self.get_y())
        self.ln(10)
        
        # API Documentation label
        self.set_font('Helvetica', 'B', 22)
        self.set_text_color(*self.WHITE)
        self.cell(0, 12, 'API Documentation', align='C', new_x="LMARGIN", new_y="NEXT")
        
        self.ln(5)
        self.set_font('Helvetica', '', 11)
        self.set_text_color(160, 180, 210)
        self.cell(0, 8, 'Complete REST API Reference Guide', align='C', new_x="LMARGIN", new_y="NEXT")
        
        # Version & Date box
        self.ln(20)
        box_w = 80
        box_x = (210 - box_w) / 2
        self.set_fill_color(55, 80, 120)
        self.set_draw_color(70, 100, 140)
        self.rect(box_x, self.get_y(), box_w, 40, 'DF')
        
        self.set_xy(box_x, self.get_y() + 5)
        self.set_font('Helvetica', 'B', 9)
        self.set_text_color(180, 200, 230)
        self.cell(box_w, 6, 'VERSION', align='C', new_x="LMARGIN", new_y="NEXT")
        self.set_x(box_x)
        self.set_font('Helvetica', 'B', 14)
        self.set_text_color(*self.WHITE)
        self.cell(box_w, 8, '1.0.0', align='C', new_x="LMARGIN", new_y="NEXT")
        self.ln(2)
        self.set_x(box_x)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(160, 180, 210)
        self.cell(box_w, 6, datetime.now().strftime('%B %d, %Y'), align='C', new_x="LMARGIN", new_y="NEXT")
        
        # Bottom info
        self.set_y(250)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(120, 140, 170)
        self.cell(0, 6, 'Base URL:  http://localhost:8000', align='C', new_x="LMARGIN", new_y="NEXT")
        self.cell(0, 6, 'Django REST Framework  |  Python 3.13  |  PostgreSQL', align='C', new_x="LMARGIN", new_y="NEXT")

    # ── Table of Contents ───────────────────────────
    def table_of_contents(self, sections):
        self.add_page()
        self.set_font('Helvetica', 'B', 24)
        self.set_text_color(*self.PRIMARY)
        self.cell(0, 15, 'Table of Contents', new_x="LMARGIN", new_y="NEXT")
        self.ln(2)
        self.set_draw_color(*self.ACCENT)
        self.set_line_width(0.6)
        self.line(10, self.get_y(), 60, self.get_y())
        self.ln(10)

        for i, section in enumerate(sections, 1):
            icon_color = section.get('color', self.ACCENT)
            # Colored dot
            self.set_fill_color(*icon_color)
            self.ellipse(15, self.get_y() + 3.5, 3, 3, 'F')
            
            # Section number
            self.set_x(22)
            self.set_font('Helvetica', 'B', 12)
            self.set_text_color(*self.PRIMARY)
            num_text = f'{i:02d}'
            self.cell(12, 10, num_text)
            
            # Section name
            self.set_font('Helvetica', '', 12)
            self.set_text_color(*self.DARK_TEXT)
            self.cell(100, 10, section['name'])
            
            # Endpoint count
            self.set_font('Helvetica', '', 10)
            self.set_text_color(*self.LIGHT_TEXT)
            count = section.get('count', 0)
            self.cell(0, 10, f'{count} endpoint{"s" if count != 1 else ""}', align='R', new_x="LMARGIN", new_y="NEXT")
            
            # Separator line
            if i < len(sections):
                self.set_draw_color(*self.TABLE_BORDER)
                self.set_line_width(0.2)
                self.line(22, self.get_y(), 195, self.get_y())
                self.ln(2)

    # ── Section Header ──────────────────────────────
    def section_header(self, number, title, description, color=None):
        if color is None:
            color = self.ACCENT
        
        if self.get_y() > 230:
            self.add_page()
        
        self.add_page()
        
        # Colored top bar
        self.set_fill_color(*color)
        self.rect(0, 12, 210, 3, 'F')
        
        self.ln(5)
        
        # Section number badge
        self.set_fill_color(*color)
        self.set_font('Helvetica', 'B', 11)
        self.set_text_color(*self.WHITE)
        badge_w = 12
        self.rect(10, self.get_y(), badge_w, 8, 'F')
        self.set_xy(10, self.get_y())
        self.cell(badge_w, 8, f' {number:02d}', align='C')
        
        # Section title
        self.set_xy(25, self.get_y())
        self.set_font('Helvetica', 'B', 20)
        self.set_text_color(*self.PRIMARY)
        self.cell(0, 8, title, new_x="LMARGIN", new_y="NEXT")
        self.ln(3)
        
        # Description
        self.set_font('Helvetica', '', 10)
        self.set_text_color(*self.MEDIUM_TEXT)
        self.set_x(10)
        self.multi_cell(185, 5, description)
        self.ln(3)
        
        # Base URL tag
        self.set_fill_color(*self.LIGHT_BG)
        self.set_draw_color(*self.TABLE_BORDER)
        base = title.lower().replace(' ', '').replace('authentication', 'users').replace('&', '').replace('fcmdevices', 'users')
        # Map section titles to URL prefixes
        url_map = {
            'Authentication': 'users/auth',
            'FCM Devices': 'users/devices',
            'Patients': 'patients/PatientService',
            'Doctors': 'doctors/DoctorService',
            'Measurements': 'measurements/MeasurementService',
            'Alerts': 'alerts/AlertService',
            'Pregnancies': 'pregnancies/PregnancyService',
        }
        base_url = url_map.get(title, base)
        self.set_x(10)
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*self.MEDIUM_TEXT)
        self.cell(18, 7, ' BASE URL', fill=True, border=1)
        self.set_font('Courier', '', 8)
        self.set_text_color(*self.ACCENT)
        self.cell(100, 7, f'  /{base_url}/', border=1, fill=True, new_x="LMARGIN", new_y="NEXT")
        self.ln(6)

    # ── Endpoint Card ───────────────────────────────
    def endpoint_card(self, method, path, description, params=None, request_body=None, success_response=None, error_responses=None, notes=None):
        needed = 60
        if params:
            needed += len(params) * 6 + 12
        if request_body:
            needed += len(request_body) * 6 + 12
        if success_response:
            needed += 25
        if error_responses:
            needed += len(error_responses) * 6 + 12
        if self.get_y() + needed > 270:
            self.add_page()

        start_y = self.get_y()
        
        # ── Method badge + Path ──
        method_color = self.METHOD_COLORS.get(method, self.ACCENT)
        
        # Method badge
        self.set_fill_color(*method_color)
        self.set_font('Helvetica', 'B', 9)
        self.set_text_color(*self.WHITE)
        badge_w = 18
        self.rect(12, self.get_y(), badge_w, 7, 'F')
        self.set_xy(12, self.get_y())
        self.cell(badge_w, 7, method, align='C')
        
        # Path
        self.set_xy(33, self.get_y())
        self.set_font('Courier', 'B', 10)
        self.set_text_color(*self.DARK_TEXT)
        self.cell(0, 7, path, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)
        
        # Description
        self.set_x(14)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(*self.MEDIUM_TEXT)
        self.multi_cell(178, 5, description)
        self.ln(2)

        # ── URL Parameters ──
        if params:
            self._table_section('URL Parameters', params, (237, 242, 247))
        
        # ── Request Body ──
        if request_body:
            self._table_section('Request Body (JSON)', request_body, (235, 244, 254))
        
        # ── Success Response ──
        if success_response:
            self._response_block('Success Response', success_response, self.SUCCESS)
        
        # ── Error Responses ──
        if error_responses:
            self._error_responses_block(error_responses)

        # ── Notes ──
        if notes:
            self._notes_block(notes)

        # Card border (left accent line)
        end_y = self.get_y()
        self.set_draw_color(*method_color)
        self.set_line_width(0.8)
        self.line(10, start_y, 10, end_y)
        
        # Bottom separator
        self.set_draw_color(*self.TABLE_BORDER)
        self.set_line_width(0.2)
        self.line(12, end_y + 2, 198, end_y + 2)
        self.ln(6)

    def _table_section(self, title, rows, bg_color):
        if self.get_y() + len(rows) * 7 + 18 > 270:
            self.add_page()
            
        self.set_x(14)
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*self.DARK_TEXT)
        self.cell(0, 6, title, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)
        
        # Table header
        self.set_x(14)
        self.set_fill_color(*bg_color)
        self.set_font('Helvetica', 'B', 7.5)
        self.set_text_color(*self.MEDIUM_TEXT)
        self.set_draw_color(*self.TABLE_BORDER)
        self.cell(40, 6, '  Name', border=1, fill=True)
        self.cell(30, 6, '  Type', border=1, fill=True)
        self.cell(20, 6, '  Required', border=1, fill=True)
        self.cell(88, 6, '  Description', border=1, fill=True, new_x="LMARGIN", new_y="NEXT")
        
        # Table rows
        self.set_font('Helvetica', '', 7.5)
        self.set_text_color(*self.DARK_TEXT)
        for row in rows:
            if self.get_y() + 7 > 270:
                self.add_page()
            self.set_x(14)
            self.set_font('Courier', '', 7.5)
            self.cell(40, 6, f'  {row["name"]}', border=1)
            self.set_font('Helvetica', '', 7.5)
            self.cell(30, 6, f'  {row["type"]}', border=1)
            
            req_text = row.get("required", "Yes")
            if req_text == "Yes":
                self.set_text_color(*self.DANGER)
            else:
                self.set_text_color(*self.SUCCESS)
            self.set_font('Helvetica', 'B', 7.5)
            self.cell(20, 6, f'  {req_text}', border=1)
            self.set_text_color(*self.DARK_TEXT)
            self.set_font('Helvetica', '', 7.5)
            self.cell(88, 6, f'  {row.get("desc", "")}', border=1, new_x="LMARGIN", new_y="NEXT")
        self.ln(3)

    def _response_block(self, title, response, color):
        if self.get_y() + 25 > 270:
            self.add_page()
        self.set_x(14)
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*self.DARK_TEXT)
        self.cell(0, 6, title, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)
        
        # Status code badge
        self.set_x(14)
        status_code = response.get('status', 200)
        if status_code < 300:
            badge_color = self.SUCCESS
        elif status_code < 400:
            badge_color = self.WARNING
        else:
            badge_color = self.DANGER
        
        self.set_fill_color(*badge_color)
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*self.WHITE)
        self.cell(14, 6, f' {status_code}', fill=True)
        
        self.set_font('Courier', '', 7.5)
        self.set_text_color(*self.DARK_TEXT)
        self.set_fill_color(*self.LIGHT_BG)
        body_text = response.get('body', '')
        self.cell(164, 6, f'  {body_text}', fill=True, new_x="LMARGIN", new_y="NEXT")
        self.ln(3)

    def _error_responses_block(self, errors):
        if self.get_y() + len(errors) * 7 + 12 > 270:
            self.add_page()
        self.set_x(14)
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*self.DARK_TEXT)
        self.cell(0, 6, 'Error Responses', new_x="LMARGIN", new_y="NEXT")
        self.ln(1)
        
        for err in errors:
            if self.get_y() + 7 > 270:
                self.add_page()
            self.set_x(14)
            status_code = err.get('status', 400)
            if status_code >= 500:
                badge_color = self.DANGER
            elif status_code >= 400:
                badge_color = (214, 158, 46)
            else:
                badge_color = self.INFO
            
            self.set_fill_color(*badge_color)
            self.set_font('Helvetica', 'B', 7.5)
            self.set_text_color(*self.WHITE)
            self.cell(14, 6, f' {status_code}', fill=True)
            
            self.set_font('Helvetica', '', 7.5)
            self.set_text_color(*self.MEDIUM_TEXT)
            self.cell(164, 6, f'  {err.get("desc", "")}', new_x="LMARGIN", new_y="NEXT")
        self.ln(3)

    def _notes_block(self, notes):
        if self.get_y() + 15 > 270:
            self.add_page()
        self.set_x(14)
        self.set_fill_color(255, 251, 235)
        self.set_draw_color(*self.WARNING)
        self.set_line_width(0.3)
        self.rect(14, self.get_y(), 178, 10, 'DF')
        self.set_font('Helvetica', 'B', 7)
        self.set_text_color(*self.WARNING)
        self.cell(15, 10, '  NOTE')
        self.set_font('Helvetica', '', 7.5)
        self.set_text_color(*self.DARK_TEXT)
        self.cell(160, 10, notes, new_x="LMARGIN", new_y="NEXT")
        self.ln(3)


def build_pdf():
    pdf = SahtyAPIDocs()
    
    # ══════════════════════════════════════════════
    #  COVER PAGE
    # ══════════════════════════════════════════════
    pdf.cover_page()

    # ══════════════════════════════════════════════
    #  TABLE OF CONTENTS
    # ══════════════════════════════════════════════
    sections = [
        {'name': 'Authentication', 'count': 9, 'color': (90, 103, 216)},
        {'name': 'FCM Devices', 'count': 1, 'color': (49, 130, 206)},
        {'name': 'Patients', 'count': 3, 'color': (56, 161, 105)},
        {'name': 'Doctors', 'count': 4, 'color': (128, 90, 213)},
        {'name': 'Measurements', 'count': 4, 'color': (214, 158, 46)},
        {'name': 'Pregnancies', 'count': 4, 'color': (213, 63, 140)},
        {'name': 'Alerts', 'count': 8, 'color': (229, 62, 62)},
    ]
    pdf.table_of_contents(sections)

    # ══════════════════════════════════════════════
    #  1. AUTHENTICATION
    # ══════════════════════════════════════════════
    pdf.section_header(1, 'Authentication', 
        'User registration, login, email/phone verification, password reset, and account management. '
        'All authentication endpoints are public (AllowAny) except delete_account which requires IsAuthenticated.',
        color=(90, 103, 216))

    # 1.1 Signup
    pdf.endpoint_card(
        'POST', '/users/auth/signup/',
        'Register a new user account. Sends a verification code to the provided email address.',
        request_body=[
            {'name': 'first_name', 'type': 'string', 'required': 'Yes', 'desc': 'First name (letters only, max 25)'},
            {'name': 'last_name', 'type': 'string', 'required': 'Yes', 'desc': 'Last name (letters only, max 25)'},
            {'name': 'email', 'type': 'email', 'required': 'Yes', 'desc': 'Unique email address'},
            {'name': 'password', 'type': 'string', 'required': 'Yes', 'desc': 'Account password'},
            {'name': 'phone', 'type': 'string', 'required': 'Yes', 'desc': 'Unique phone number (+XXXXXXXXXXX)'},
            {'name': 'birth_date', 'type': 'date', 'required': 'Yes', 'desc': 'Date of birth (YYYY-MM-DD)'},
            {'name': 'gender', 'type': 'string', 'required': 'No', 'desc': 'M or F (default: F)'},
            {'name': 'role', 'type': 'string', 'required': 'No', 'desc': 'P (Patient) or D (Doctor), default: P'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Code sent successfully", "user_id": 1}'},
        error_responses=[
            {'status': 400, 'desc': 'Phone number already used / Email already used / Validation errors'},
            {'status': 500, 'desc': 'Email not sent (SMTP failure)'},
        ]
    )

    # 1.2 Signin
    pdf.endpoint_card(
        'POST', '/users/auth/signin/',
        'Authenticate a user and return JWT access & refresh tokens.',
        request_body=[
            {'name': 'email', 'type': 'email', 'required': 'Yes', 'desc': 'Registered email address'},
            {'name': 'password', 'type': 'string', 'required': 'Yes', 'desc': 'Account password'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "access": "<jwt_token>", "refresh": "<refresh_token>"}'},
        error_responses=[
            {'status': 400, 'desc': 'Invalid email or password'},
            {'status': 403, 'desc': 'Email not verified / User did not complete signup'},
        ]
    )

    # 1.3 Resend Code
    pdf.endpoint_card(
        'POST', '/users/auth/resend_code/',
        'Resend the email verification OTP code to an existing user.',
        request_body=[
            {'name': 'email', 'type': 'email', 'required': 'Yes', 'desc': 'Registered email address'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Code sent successfully", "user_id": 1}'},
        error_responses=[
            {'status': 404, 'desc': 'User not found'},
            {'status': 500, 'desc': 'Email not sent'},
        ]
    )

    # 1.4 Verify Code
    pdf.endpoint_card(
        'POST', '/users/auth/verify_code/',
        'Verify the email OTP code to activate the user account.',
        request_body=[
            {'name': 'email', 'type': 'email', 'required': 'Yes', 'desc': 'Registered email address'},
            {'name': 'code', 'type': 'string', 'required': 'Yes', 'desc': '6-digit verification code'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "User verified successfully"}'},
        error_responses=[
            {'status': 400, 'desc': 'Code expired (new code sent automatically) / Incorrect verification code'},
            {'status': 404, 'desc': 'User not found'},
        ]
    )

    # 1.5 Verify Reset Code
    pdf.endpoint_card(
        'POST', '/users/auth/verify_reset_code/',
        'Verify the OTP code for password reset flow. Sets can_reset_password flag.',
        request_body=[
            {'name': 'email', 'type': 'email', 'required': 'Yes', 'desc': 'Registered email address'},
            {'name': 'code', 'type': 'string', 'required': 'Yes', 'desc': '6-digit verification code'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "User verified successfully"}'},
        error_responses=[
            {'status': 400, 'desc': 'Code expired / Incorrect verification code'},
            {'status': 404, 'desc': 'User not found'},
        ]
    )

    # 1.6 Is Email Available
    pdf.endpoint_card(
        'POST', '/users/auth/is_email_available/',
        'Check if an email address is available for registration.',
        request_body=[
            {'name': 'email', 'type': 'email', 'required': 'Yes', 'desc': 'Email address to check'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Email is available"}'},
        error_responses=[
            {'status': 400, 'desc': 'Email is already used'},
        ]
    )

    # 1.7 Verify Reset Email
    pdf.endpoint_card(
        'POST', '/users/auth/verify_reset_email/',
        'Verify email exists and send a reset code for the password reset flow.',
        request_body=[
            {'name': 'email', 'type': 'email', 'required': 'Yes', 'desc': 'Registered email address'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Email exists, verification code sent"}'},
        error_responses=[
            {'status': 400, 'desc': 'Email does not exist'},
        ]
    )

    # 1.8 Verify Phone
    pdf.endpoint_card(
        'POST', '/users/auth/verify_phone/',
        'Check if a phone number is available for registration.',
        request_body=[
            {'name': 'phone', 'type': 'string', 'required': 'Yes', 'desc': 'Phone number (+XXXXXXXXXXX, 8-15 digits)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Phone number is available"}'},
        error_responses=[
            {'status': 400, 'desc': 'Phone number is already used / Invalid phone format'},
        ]
    )

    # 1.9 Forget Password
    pdf.endpoint_card(
        'POST', '/users/auth/forget_password/',
        'Reset user password. Requires prior verification via verify_reset_code.',
        request_body=[
            {'name': 'email', 'type': 'email', 'required': 'Yes', 'desc': 'Registered email address'},
            {'name': 'password', 'type': 'string', 'required': 'Yes', 'desc': 'New password'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Password updated"}'},
        error_responses=[
            {'status': 400, 'desc': 'Email not verified for reset / Invalid email'},
        ]
    )

    # 1.10 Delete Account
    pdf.endpoint_card(
        'DELETE', '/users/auth/{id}/delete_account/',
        'Soft-delete a user account. Appends ".deleted" to email and phone. Requires authentication and ownership.',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'User ID (URL parameter)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Account deleted successfully"}'},
        error_responses=[
            {'status': 400, 'desc': 'Account already deleted'},
            {'status': 404, 'desc': 'User does not exist'},
            {'status': 403, 'desc': 'Permission denied (not owner or admin)'},
            {'status': 500, 'desc': 'Internal server error'},
        ],
        notes='Permission: IsAuthenticated + IsOwnerOrAdmin'
    )

    # ══════════════════════════════════════════════
    #  2. FCM DEVICES
    # ══════════════════════════════════════════════
    pdf.section_header(2, 'FCM Devices',
        'Firebase Cloud Messaging device registration for push notifications. '
        'Requires authentication.',
        color=(49, 130, 206))

    pdf.endpoint_card(
        'POST', '/users/devices/register_device/',
        'Register or update an FCM device token for the authenticated user.',
        request_body=[
            {'name': 'fcm_token', 'type': 'string', 'required': 'Yes', 'desc': 'Firebase Cloud Messaging device token'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Device registered successfully"}'},
        error_responses=[
            {'status': 401, 'desc': 'Authentication credentials not provided'},
        ],
        notes='Permission: IsAuthenticated. Uses update_or_create to avoid duplicates.'
    )

    # ══════════════════════════════════════════════
    #  3. PATIENTS
    # ══════════════════════════════════════════════
    pdf.section_header(3, 'Patients',
        'Patient profile management including creation (linked to User), retrieval with computed fields '
        '(age, BMI, menstrual cycle), and profile updates.',
        color=(56, 161, 105))

    # 3.1 Create Patient
    pdf.endpoint_card(
        'POST', '/patients/PatientService/create_patient/',
        'Create a patient profile linked to an existing User. For female patients, also creates a MenstrualCycle record.',
        request_body=[
            {'name': 'email', 'type': 'email', 'required': 'Yes', 'desc': 'Email of the linked User account'},
            {'name': 'height', 'type': 'integer', 'required': 'Yes', 'desc': 'Height in cm (min: 1)'},
            {'name': 'weight', 'type': 'decimal', 'required': 'Yes', 'desc': 'Weight in kg (min: 1)'},
            {'name': 'blood_type', 'type': 'string', 'required': 'No', 'desc': 'A+, A-, B+, B-, AB+, AB-, O+, O-'},
            {'name': 'chronic_diseases', 'type': 'string', 'required': 'No', 'desc': 'Chronic diseases description'},
            {'name': 'allergies', 'type': 'string', 'required': 'No', 'desc': 'Known allergies'},
            {'name': 'current_medications', 'type': 'string', 'required': 'No', 'desc': 'Current medications'},
            {'name': 'family_doctor_name', 'type': 'string', 'required': 'No', 'desc': 'Family doctor name (letters only)'},
        ],
        success_response={'status': 201, 'body': '{"success": true, "message": "Patient created", "patient_id": 1}'},
        error_responses=[
            {'status': 400, 'desc': 'Invalid data or constraint violated / User not found'},
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # 3.2 Get Patient By ID
    pdf.endpoint_card(
        'GET', '/patients/PatientService/{id}/get_patient_by_id/',
        'Get full patient profile with computed fields: age, BMI, menstrual cycle info (females only), and pregnancy week.',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Patient ID (URL parameter)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "patient": {...}, "age": 28, "bmi": 22.5, "menstrual_cycle": {...}}'},
        error_responses=[
            {'status': 404, 'desc': 'Patient not found'},
            {'status': 400, 'desc': 'Patient has incomplete information'},
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='BMI, age, and pregnancy_week are computed server-side. menstrual_cycle is null for male patients.'
    )

    # 3.3 Update Patient
    pdf.endpoint_card(
        'PATCH', '/patients/PatientService/{id}/update_patient/',
        'Partially update patient profile fields. Only provided fields are updated.',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Patient ID (URL parameter)'},
        ],
        request_body=[
            {'name': 'height', 'type': 'integer', 'required': 'No', 'desc': 'Height in cm'},
            {'name': 'weight', 'type': 'decimal', 'required': 'No', 'desc': 'Weight in kg'},
            {'name': 'blood_type', 'type': 'string', 'required': 'No', 'desc': 'Blood type'},
            {'name': 'chronic_diseases', 'type': 'string', 'required': 'No', 'desc': 'Chronic diseases'},
            {'name': 'allergies', 'type': 'string', 'required': 'No', 'desc': 'Known allergies'},
            {'name': 'first_name', 'type': 'string', 'required': 'No', 'desc': 'Update user first name'},
            {'name': 'last_name', 'type': 'string', 'required': 'No', 'desc': 'Update user last name'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Patient updated"}'},
        error_responses=[
            {'status': 404, 'desc': 'Patient not found'},
            {'status': 400, 'desc': 'No fields to update / Validation error'},
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # ══════════════════════════════════════════════
    #  4. DOCTORS
    # ══════════════════════════════════════════════
    pdf.section_header(4, 'Doctors',
        'Doctor profile management. Doctors are linked to User accounts and have specialities. '
        'Includes CRUD operations and listing all doctors.',
        color=(128, 90, 213))

    # 4.1 Create Doctor
    pdf.endpoint_card(
        'POST', '/doctors/DoctorService/create_doctor/',
        'Create a doctor profile linked to an existing User account.',
        request_body=[
            {'name': 'user_id', 'type': 'integer', 'required': 'Yes', 'desc': 'ID of the linked User account'},
            {'name': 'speciality_id', 'type': 'integer', 'required': 'Yes', 'desc': 'ID of the doctor speciality'},
            {'name': 'ville', 'type': 'string', 'required': 'No', 'desc': 'City (TUNIS, ARIANA, SOUSSE, etc.)'},
            {'name': 'address', 'type': 'string', 'required': 'Yes', 'desc': 'Full address'},
            {'name': 'experience', 'type': 'integer', 'required': 'Yes', 'desc': 'Years of experience (min: 0)'},
            {'name': 'consultation_price', 'type': 'decimal', 'required': 'No', 'desc': 'Consultation price'},
            {'name': 'bio', 'type': 'string', 'required': 'No', 'desc': 'Brief bio/description'},
        ],
        success_response={'status': 201, 'body': '{"success": true, "message": "Doctor created successfully", "doctor_id": 1}'},
        error_responses=[
            {'status': 400, 'desc': 'Invalid data or constraint violated'},
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # 4.2 Get Doctor By ID
    pdf.endpoint_card(
        'GET', '/doctors/DoctorService/{id}/get_doctor_by_id/',
        'Get full doctor profile with computed age, speciality details, and user information.',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Doctor ID (URL parameter)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "doctor": {...}, "age": 35}'},
        error_responses=[
            {'status': 404, 'desc': 'Doctor not found'},
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='Age is computed from user birth_date. Returns null age if birth_date is missing.'
    )

    # 4.3 Update Doctor
    pdf.endpoint_card(
        'PATCH', '/doctors/DoctorService/{id}/update_doctor/',
        'Partially update doctor profile. Can update both doctor fields and linked user fields.',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Doctor ID (URL parameter)'},
        ],
        request_body=[
            {'name': 'ville', 'type': 'string', 'required': 'No', 'desc': 'City'},
            {'name': 'address', 'type': 'string', 'required': 'No', 'desc': 'Full address'},
            {'name': 'experience', 'type': 'integer', 'required': 'No', 'desc': 'Years of experience'},
            {'name': 'consultation_price', 'type': 'decimal', 'required': 'No', 'desc': 'Consultation price'},
            {'name': 'bio', 'type': 'string', 'required': 'No', 'desc': 'Brief bio/description'},
            {'name': 'first_name', 'type': 'string', 'required': 'No', 'desc': 'Update user first name'},
            {'name': 'last_name', 'type': 'string', 'required': 'No', 'desc': 'Update user last name'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Doctor updated"}'},
        error_responses=[
            {'status': 404, 'desc': 'Doctor not found'},
            {'status': 400, 'desc': 'No fields to update / Validation error'},
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # 4.4 Get All Doctors
    pdf.endpoint_card(
        'GET', '/doctors/DoctorService/get_all_doctors/',
        'Retrieve a list of all registered doctors with their profiles and specialities.',
        success_response={'status': 200, 'body': '{"success": true, "doctors": [{...}, {...}]}'},
        error_responses=[
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # ══════════════════════════════════════════════
    #  5. MEASUREMENTS
    # ══════════════════════════════════════════════
    pdf.section_header(5, 'Measurements',
        'Health measurement tracking and ML-powered risk assessment. Supports weight, blood pressure, '
        'glycemia, temperature, heart rate, and oxygen measurements. Uses atomic transactions.',
        color=(214, 158, 46))

    # 5.1 Create Measurement
    pdf.endpoint_card(
        'POST', '/measurements/MeasurementService/create_measurement/',
        'Record a new health measurement. Automatically triggers ML risk assessment using all latest '
        'measurements. Sends email alert if risk is MEDIUM or HIGH. Wrapped in atomic transaction.',
        request_body=[
            {'name': 'patient_id', 'type': 'integer', 'required': 'Yes', 'desc': 'Patient ID'},
            {'name': 'type', 'type': 'string', 'required': 'Yes', 'desc': 'WEIGHT, BLOOD_PRESSURE, GLYCEMIA, TEMPERATURE, HEART_RATE, OXYGEN'},
            {'name': 'value1', 'type': 'decimal', 'required': 'Yes', 'desc': 'Primary value (e.g., systolic BP, weight)'},
            {'name': 'value2', 'type': 'decimal', 'required': 'No', 'desc': 'Secondary value (diastolic BP only)'},
            {'name': 'unit', 'type': 'string', 'required': 'Yes', 'desc': 'KG, MMHG, G_L, C, BPM'},
            {'name': 'context', 'type': 'string', 'required': 'No', 'desc': 'Additional context (default: "")'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "risk_level": "LOW", "risk_percentage": 15.2, "message": "Measurement created and risk assessed"}'},
        error_responses=[
            {'status': 200, 'desc': 'Measurement created but insufficient data for risk assessment (risk_level: null)'},
            {'status': 400, 'desc': 'Invalid data or constraint violated'},
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='Uses transaction.atomic() - both Measurement and RiskAssessment are rolled back on failure.'
    )

    # 5.2 Get Latest Measurements  
    pdf.endpoint_card(
        'GET', '/measurements/MeasurementService/{id}/get_latest_measurements/',
        'Get the latest measurement of each type for a patient, plus computed BMI and pregnancy week.',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Patient ID (URL parameter)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "height": 170, "weight": 65, "bmi": 22.5, "glycemia_informations": {...}, "blood_pressure": {...}, "heart_rate": {...}, "pregnancy_week": 12}'},
        error_responses=[
            {'status': 404, 'desc': 'Patient not found'},
            {'status': 400, 'desc': 'Patient has incomplete information (missing height/weight)'},
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='pregnancy_week is null for male patients or if no active pregnancy exists.'
    )

    # 5.3 Get Patient Measurements
    pdf.endpoint_card(
        'GET', '/measurements/MeasurementService/{id}/get_patient_measurements/',
        'Get all measurements for a patient, ordered by date (newest first).',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Patient ID (URL parameter)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "measurements": [{...}, {...}]}'},
        error_responses=[
            {'status': 404, 'desc': 'Patient not found'},
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # 5.4 Get Risk Assessment
    pdf.endpoint_card(
        'GET', '/measurements/MeasurementService/{id}/get_risk_assessment/',
        'Get the latest risk assessment for a patient (ML-predicted risk level and contributing factors).',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Patient ID (URL parameter)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "risk_assessment": {"global_risk_level": "LOW", "global_risk_percentage": 15.2, ...}}'},
        error_responses=[
            {'status': 404, 'desc': 'Patient not found / No risk assessment found'},
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # ══════════════════════════════════════════════
    #  6. PREGNANCIES
    # ══════════════════════════════════════════════
    pdf.section_header(6, 'Pregnancies',
        'Pregnancy tracking for female patients. Manages pregnancy test results, due dates, '
        'and linked functionality with measurements (pregnancy week) and alerts.',
        color=(213, 63, 140))

    # 6.1 Create Pregnancy
    pdf.endpoint_card(
        'POST', '/pregnancies/PregnancyService/create_pregnancy/',
        'Record a new pregnancy entry for a patient.',
        request_body=[
            {'name': 'patient', 'type': 'integer', 'required': 'Yes', 'desc': 'Patient ID'},
            {'name': 'test_date', 'type': 'date', 'required': 'Yes', 'desc': 'Date of pregnancy test (YYYY-MM-DD)'},
            {'name': 'test_result', 'type': 'boolean', 'required': 'Yes', 'desc': 'Pregnancy test result (true/false)'},
            {'name': 'start_date', 'type': 'date', 'required': 'No', 'desc': 'Pregnancy start date'},
            {'name': 'due_date', 'type': 'date', 'required': 'No', 'desc': 'Expected due date'},
            {'name': 'end_date', 'type': 'date', 'required': 'No', 'desc': 'Pregnancy end date (null = ongoing)'},
        ],
        success_response={'status': 201, 'body': '{"success": true, "message": "Pregnancy created successfully", "pregnancy_id": 1}'},
        error_responses=[
            {'status': 400, 'desc': 'Invalid data or constraint violated'},
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # 6.2 Get Current Pregnancy
    pdf.endpoint_card(
        'GET', '/pregnancies/PregnancyService/{id}/get_current_pregnancy/',
        'Get the current active pregnancy for a patient (where end_date is null).',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Patient ID (URL parameter)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "pregnancy": {"test_date": "...", "start_date": "...", "due_date": "...", ...}}'},
        error_responses=[
            {'status': 404, 'desc': 'Patient not found / No active pregnancy found'},
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # 6.3 Update Pregnancy
    pdf.endpoint_card(
        'PATCH', '/pregnancies/PregnancyService/{id}/update_pregnancy/',
        'Partially update pregnancy details (e.g., set end_date, update due_date).',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Pregnancy ID (URL parameter)'},
        ],
        request_body=[
            {'name': 'start_date', 'type': 'date', 'required': 'No', 'desc': 'Pregnancy start date'},
            {'name': 'due_date', 'type': 'date', 'required': 'No', 'desc': 'Expected due date'},
            {'name': 'end_date', 'type': 'date', 'required': 'No', 'desc': 'Set to close pregnancy'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Pregnancy updated successfully"}'},
        error_responses=[
            {'status': 404, 'desc': 'Pregnancy not found'},
            {'status': 400, 'desc': 'Validation error'},
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # 6.4 Delete Pregnancy
    pdf.endpoint_card(
        'DELETE', '/pregnancies/PregnancyService/{id}/delete_pregnancy/',
        'Permanently delete a pregnancy record.',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Pregnancy ID (URL parameter)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Pregnancy deleted successfully"}'},
        error_responses=[
            {'status': 404, 'desc': 'Pregnancy not found'},
            {'status': 500, 'desc': 'Database error'},
        ]
    )

    # ══════════════════════════════════════════════
    #  7. ALERTS
    # ══════════════════════════════════════════════
    pdf.section_header(7, 'Alerts',
        'Alert system for health notifications, medication reminders, appointment reminders, and system alerts. '
        'Most endpoints are triggered automatically by the APScheduler cron jobs. '
        'Frontend uses get_alerts_by_user and mark_as_read.',
        color=(229, 62, 62))

    # 7.1 Send Risk Alert
    pdf.endpoint_card(
        'POST', '/alerts/AlertService/send_risk_alert/',
        'Send a health risk alert email and create an Alert record. Called automatically by the measurement service when risk is MEDIUM or HIGH.',
        request_body=[
            {'name': 'email', 'type': 'email', 'required': 'Yes', 'desc': 'Patient email address'},
            {'name': 'alert_message', 'type': 'string', 'required': 'Yes', 'desc': 'Alert message content'},
            {'name': 'alert_level', 'type': 'string', 'required': 'Yes', 'desc': 'WARNING or CRITICAL'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Alert sent successfully"}'},
        error_responses=[
            {'status': 400, 'desc': 'Missing required fields (email, alert_message, alert_level)'},
            {'status': 404, 'desc': 'User not found'},
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='Automatic: Called by MeasurementService.createMeasurement() when risk detected.'
    )

    # 7.2 Send Medication Reminders
    pdf.endpoint_card(
        'POST', '/alerts/AlertService/send_medication_reminders/',
        'Send medication reminder emails to all patients with active treatments due within the next hour. Creates Alert records.',
        success_response={'status': 200, 'body': '{"success": true, "message": "Medication reminders sent successfully"}'},
        error_responses=[
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='Automatic: Scheduled every hour at :00 via APScheduler.'
    )

    # 7.3 Send Appointment Reminders
    pdf.endpoint_card(
        'POST', '/alerts/AlertService/send_appointment_reminders/',
        'Send appointment reminder emails to patients with confirmed appointments tomorrow.',
        success_response={'status': 200, 'body': '{"success": true, "message": "Appointment reminders sent successfully"}'},
        error_responses=[
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='Automatic: Scheduled daily at 18:00 via APScheduler.'
    )

    # 7.4 Send Missing Measurements Alerts
    pdf.endpoint_card(
        'POST', '/alerts/AlertService/send_missing_measurements_alerts/',
        'Alert patients who haven\'t recorded any measurements in the last 3 days.',
        success_response={'status': 200, 'body': '{"success": true, "message": "Missing measurements alerts sent successfully"}'},
        error_responses=[
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='Automatic: Scheduled daily at 09:00 via APScheduler.'
    )

    # 7.5 Send Unconfirmed Appointment Alerts
    pdf.endpoint_card(
        'POST', '/alerts/AlertService/send_unconfirmed_appointment_alerts/',
        'Alert patients and doctors about appointments in the next 2 days that are still PENDING.',
        success_response={'status': 200, 'body': '{"success": true, "message": "Unconfirmed appointment alerts sent"}'},
        error_responses=[
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='Automatic: Scheduled daily at 09:15 via APScheduler. Sends to BOTH patient and doctor.'
    )

    # 7.6 Send Pregnancy No Appointment Alerts
    pdf.endpoint_card(
        'POST', '/alerts/AlertService/send_pregnancy_no_appointment_alerts/',
        'Alert pregnant patients who have no upcoming appointments scheduled.',
        success_response={'status': 200, 'body': '{"success": true, "message": "Pregnancy no appointment alerts sent"}'},
        error_responses=[
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='Automatic: Scheduled daily at 09:30 via APScheduler.'
    )

    # 7.7 Get Alerts By User
    pdf.endpoint_card(
        'GET', '/alerts/AlertService/{id}/get_alerts_by_user/',
        'Get all alerts for a specific user, ordered by creation date (newest first). For frontend use.',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'User ID (URL parameter)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "alerts": [{"type": "HEALTH", "message": "...", "level": "...", "status": "NEW", ...}]}'},
        error_responses=[
            {'status': 404, 'desc': 'User not found'},
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='Frontend endpoint: Use this to display alerts in the app.'
    )

    # 7.8 Mark As Read
    pdf.endpoint_card(
        'PATCH', '/alerts/AlertService/{id}/mark_as_read/',
        'Mark a specific alert as read by changing its status from NEW to READ.',
        params=[
            {'name': 'id', 'type': 'integer', 'required': 'Yes', 'desc': 'Alert ID (URL parameter)'},
        ],
        success_response={'status': 200, 'body': '{"success": true, "message": "Alert marked as read"}'},
        error_responses=[
            {'status': 404, 'desc': 'Alert not found'},
            {'status': 500, 'desc': 'Database error'},
        ],
        notes='Frontend endpoint: Call when user opens/views an alert.'
    )

    # ══════════════════════════════════════════════
    #  TOKEN REFRESH (Extra)
    # ══════════════════════════════════════════════
    # Add a small note about token refresh at the end
    if pdf.get_y() > 230:
        pdf.add_page()
    
    pdf.ln(5)
    pdf.set_fill_color(*pdf.SECTION_BG)
    pdf.set_draw_color(*pdf.INFO)
    pdf.set_line_width(0.5)
    box_y = pdf.get_y()
    pdf.rect(10, box_y, 190, 30, 'DF')
    
    pdf.set_xy(14, box_y + 3)
    pdf.set_font('Helvetica', 'B', 11)
    pdf.set_text_color(*pdf.INFO)
    pdf.cell(0, 7, 'Additional Endpoint: Token Refresh', new_x="LMARGIN", new_y="NEXT")
    
    pdf.set_x(14)
    pdf.set_font('Courier', 'B', 9)
    pdf.set_text_color(*pdf.DARK_TEXT)
    pdf.cell(0, 6, 'POST  /users/refresh/', new_x="LMARGIN", new_y="NEXT")
    
    pdf.set_x(14)
    pdf.set_font('Helvetica', '', 8)
    pdf.set_text_color(*pdf.MEDIUM_TEXT)
    pdf.cell(0, 6, 'Body: {"refresh": "<refresh_token>"}  ->  Returns: {"access": "<new_access_token>"}  |  SimpleJWT built-in view')

    # ══════════════════════════════════════════════
    #  SAVE
    # ══════════════════════════════════════════════
    output_path = r'c:\sahty\Sahty_API_Documentation.pdf'
    pdf.output(output_path)
    print(f'\n  PDF generated successfully!')
    print(f'  Location: {output_path}')
    print(f'  Total pages: {pdf.pages_count}')


if __name__ == '__main__':
    build_pdf()
