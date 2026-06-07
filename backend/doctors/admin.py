from django.contrib import admin
from django.utils.safestring import mark_safe
from django.urls import path
from django.shortcuts import redirect
from django.contrib import messages
from .models import Doctor


def action_btn(label, url, color):
    return (
        f'<a href="{url}" style="'
        f'display:inline-block;'
        f'padding:4px 12px;'
        f'border-radius:12px;'
        f'font-size:11px;'
        f'font-weight:600;'
        f'color:white;'
        f'background:{color};'
        f'text-decoration:none;'
        f'white-space:nowrap;'
        f'margin:2px 2px;">'
        f'{label}</a>'
    )


def status_pill(label, bg):
    return mark_safe(
        f'<span style="'
        f'display:inline-block;'
        f'padding:3px 10px;'
        f'border-radius:12px;'
        f'font-size:11px;'
        f'font-weight:600;'
        f'color:white;'
        f'background:{bg};'
        f'white-space:nowrap;">'
        f'{label}</span>'
    )


@admin.register(Doctor)
class DoctorAdmin(admin.ModelAdmin):
    list_display = (
        "full_name",
        "email",
        "speciality",
        "ville",
        "experience",
        "consultation_price",
        "verification_status",
        "joined_date",
        "action_buttons",
    )
    list_filter = ("is_doctor_verified", "speciality", "ville")
    search_fields = (
        "user__first_name",
        "user__last_name",
        "user__email",
        "speciality__name",
        "ville",
    )
    ordering = ("is_doctor_verified", "-user__joined_date")
    actions = ("bulk_verify", "bulk_reject")

    fieldsets = (
        (
            "Account Information",
            {
                "fields": (
                    "full_name",
                    "email",
                    "joined_date",
                )
            },
        ),
        (
            "Professional Profile",
            {
                "fields": (
                    "speciality",
                    "ville",
                    "address",
                    "experience",
                    "consultation_price",
                    "bio",
                )
            },
        ),
        (
            "Verification",
            {
                "fields": (
                    "is_doctor_verified",
                    "verification_status",
                )
            },
        ),
    )
    add_fieldsets = (
        (
            "Account Information",
            {
                "fields": (
                    "user",
                    "speciality",
                )
            },
        ),
        (
            "Professional Profile",
            {
                "fields": (
                    "ville",
                    "address",
                    "experience",
                    "consultation_price",
                    "bio",
                )
            },
        ),
        (
            "Verification",
            {
                "fields": (
                    "is_doctor_verified",
                )
            },
        ),
    )
    readonly_fields = (
        "full_name",
        "email",
        "joined_date",
        "verification_status",
    )

    def get_queryset(self, request):
        return super().get_queryset(request).select_related("user", "speciality")

    def get_fieldsets(self, request, obj=None):
        if obj is None:
            return self.add_fieldsets
        return super().get_fieldsets(request, obj)

    @admin.display(description="Full Name")
    def full_name(self, obj):
        return f"Dr. {obj.user.first_name} {obj.user.last_name}"

    @admin.display(description="Email")
    def email(self, obj):
        return obj.user.email

    @admin.display(description="City", ordering="ville")
    def ville(self, obj):
        return obj.get_ville_display()

    @admin.display(description="Years of Experience", ordering="experience")
    def experience(self, obj):
        return obj.experience

    @admin.display(description="Joined Date", ordering="user__joined_date")
    def joined_date(self, obj):
        return obj.user.joined_date

    @admin.display(description="Verification Status")
    def verification_status(self, obj):
        if obj.is_doctor_verified:
            return status_pill("Verified", "#16a34a")
        return status_pill("Pending", "#d97706")

    @admin.display(description="Actions")
    def action_buttons(self, obj):
        verify_url   = f"/admin/doctors/doctor/{obj.pk}/verify/"
        reject_url   = f"/admin/doctors/doctor/{obj.pk}/reject/"
        unverify_url = f"/admin/doctors/doctor/{obj.pk}/unverify/"
        delete_url   = f"/admin/doctors/doctor/{obj.pk}/delete-with-user/"

        if obj.is_doctor_verified:
            buttons = (
                action_btn("Remove verification", unverify_url, "#d97706") +
                action_btn("Delete", delete_url, "#dc2626")
            )
        else:
            buttons = (
                action_btn("Verify", verify_url, "#16a34a") +
                action_btn("Reject", reject_url, "#dc2626") +
                action_btn("Delete", delete_url, "#7f1d1d")
            )

        return mark_safe(
            f'<div style="display:flex;flex-wrap:wrap;gap:4px;align-items:center;">'
            f'{buttons}</div>'
        )

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                "<int:doctor_id>/verify/",
                self.admin_site.admin_view(self.verify_doctor),
                name="doctor-verify",
            ),
            path(
                "<int:doctor_id>/reject/",
                self.admin_site.admin_view(self.reject_doctor),
                name="doctor-reject",
            ),
            path(
                "<int:doctor_id>/unverify/",
                self.admin_site.admin_view(self.unverify_doctor),
                name="doctor-unverify",
            ),
            path(
                "<int:doctor_id>/delete-with-user/",
                self.admin_site.admin_view(self.delete_doctor_with_user),
                name="doctor-delete-with-user",
            ),
        ]
        return custom_urls + urls

    def verify_doctor(self, request, doctor_id):
        doctor = self.get_object(request, str(doctor_id))
        if doctor:
            doctor.is_doctor_verified = True
            doctor.save()
            messages.success(
                request,
                f"Dr. {doctor.user.first_name} {doctor.user.last_name} has been verified.",
            )
        return redirect("admin:doctors_doctor_changelist")

    def reject_doctor(self, request, doctor_id):
        doctor = self.get_object(request, str(doctor_id))
        if doctor:
            user = doctor.user
            user.is_deleted = True
            user.email = f"{user.email}.{user.id}.deleted"
            user.phone = f"{user.phone}.{user.id}.deleted"
            user.save()
            messages.warning(
                request,
                f"Dr. {doctor.user.first_name} {doctor.user.last_name} has been rejected and removed.",
            )
        return redirect("admin:doctors_doctor_changelist")

    def unverify_doctor(self, request, doctor_id):
        doctor = self.get_object(request, str(doctor_id))
        if doctor:
            doctor.is_doctor_verified = False
            doctor.save(update_fields=["is_doctor_verified"])
            messages.warning(
                request,
                f"Dr. {doctor.user.first_name} {doctor.user.last_name} verification was removed.",
            )
        return redirect("admin:doctors_doctor_changelist")

    def delete_doctor_with_user(self, request, doctor_id):
        doctor = self.get_object(request, str(doctor_id))
        if doctor:
            first_name = doctor.user.first_name
            last_name = doctor.user.last_name
            doctor.user.delete()
            messages.warning(
                request,
                f"Dr. {first_name} {last_name} and their account have been permanently deleted.",
            )
        return redirect("admin:doctors_doctor_changelist")

    @admin.action(description="Verify selected doctors")
    def bulk_verify(self, request, queryset):
        count = queryset.update(is_doctor_verified=True)
        messages.success(request, f"{count} doctor(s) have been verified.")

    @admin.action(description="Reject selected doctors")
    def bulk_reject(self, request, queryset):
        count = 0
        for doctor in queryset.select_related("user"):
            user = doctor.user
            if not user.is_deleted:
                user.is_deleted = True
                user.email = f"{user.email}.{user.id}.deleted"
                user.phone = f"{user.phone}.{user.id}.deleted"
                user.save()
                count += 1
        messages.warning(request, f"{count} doctor(s) have been rejected and removed.")