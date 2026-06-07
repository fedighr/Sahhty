from django.contrib import admin
from django.utils.safestring import mark_safe
from .models import Medication, MedicationDci
from dci.models import DCI


CATEGORY_COLORS = {
    'V': ('white', '#dc2626'),
    'E': ('white', '#d97706'),
    'I': ('white', '#3b82f6'),
    'N': ('white', '#6b7280'),
}

APPROVAL_COLORS = {
    'O': ('white', '#d97706'),
    'N': ('white', '#16a34a'),
}


def category_badge(value, label):
    text, bg = CATEGORY_COLORS.get(value, ('white', '#9ca3af'))
    return mark_safe(
        f'<span style="background:{bg};color:{text};'
        f'padding:3px 10px;border-radius:12px;'
        f'font-size:11px;font-weight:600;white-space:nowrap;">'
        f'{label}</span>'
    )


def approval_badge(value, label):
    text, bg = APPROVAL_COLORS.get(value, ('white', '#9ca3af'))
    return mark_safe(
        f'<span style="background:{bg};color:{text};'
        f'padding:3px 10px;border-radius:12px;'
        f'font-size:11px;font-weight:600;white-space:nowrap;">'
        f'{label}</span>'
    )


class MedicationDciInline(admin.TabularInline):
    model = MedicationDci
    extra = 1
    autocomplete_fields = ('dci',)
    verbose_name = 'Linked DCI'
    verbose_name_plural = 'Linked DCIs'
    fields = ('dci',)
    can_delete = True

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('dci')


@admin.register(Medication)
class MedicationAdmin(admin.ModelAdmin):

    list_display = (
        'commercial_name',
        'name',
        'code',
        'form',
        'dosage',
        'category_badge',
        'public_price',
        'prior_approval_badge',
        'linked_dcis_count',
    )

    list_filter = (
        'category',
        'form',
        'prior_approval',
    )

    search_fields = (
        'commercial_name',
        'name',
        'code',
        'dci',
    )

    ordering = ('commercial_name',)

    inlines = (MedicationDciInline,)

    fieldsets = (
        ('Identification', {
            'fields': (
                'code',
                'name',
                'commercial_name',
            )
        }),
        ('Pharmaceutical Details', {
            'fields': (
                'form',
                'dosage',
                'package',
                'dci',
            )
        }),
        ('Pricing', {
            'fields': (
                'public_price',
                'tarif_reference',
            )
        }),
        ('Classification', {
            'fields': (
                'category',
                'prior_approval',
            )
        }),
    )

    def get_queryset(self, request):
        return super().get_queryset(request).prefetch_related('medication_dcis__dci')

    @admin.display(description='Category')
    def category_badge(self, obj):
        if obj.category:
            return category_badge(obj.category, obj.get_category_display())
        return mark_safe('<span style="color:#9ca3af;">—</span>')

    @admin.display(description='Prior Approval')
    def prior_approval_badge(self, obj):
        if obj.prior_approval:
            return approval_badge(obj.prior_approval, obj.get_prior_approval_display())
        return mark_safe('<span style="color:#9ca3af;">—</span>')

    @admin.display(description='Linked DCIs')
    def linked_dcis_count(self, obj):
        count = obj.medication_dcis.count()
        if count == 0:
            return mark_safe('<span style="color:#dc2626;font-weight:600;">0</span>')
        return mark_safe(
            f'<span style="background:#dbeafe;color:#1d4ed8;'
            f'padding:2px 10px;border-radius:12px;'
            f'font-size:11px;font-weight:600;">'
            f'{count}</span>'
        )


@admin.register(MedicationDci)
class MedicationDciAdmin(admin.ModelAdmin):

    list_display = (
        'medication',
        'dci',
    )

    search_fields = (
        'medication__commercial_name',
        'medication__name',
        'dci__name',
    )

    autocomplete_fields = ('medication', 'dci')

    ordering = ('medication__commercial_name',)

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('medication', 'dci')