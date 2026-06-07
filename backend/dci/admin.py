from django.contrib import admin
from django.utils.safestring import mark_safe
from django.contrib import messages
from .models import DCI, DciInteraction


STATUS_COLORS = {
    'SAFE':           ('white', '#16a34a'),
    'UNSAFE':         ('white', '#dc2626'),
    'CAUTION':        ('white', '#d97706'),
    'NOT_APPLICABLE': ('white', '#6b7280'),
    'UNKNOWN':        ('white', '#9ca3af'),
}

SEVERITY_COLORS = {
    'CONTRE_INDICATION':   ('white', '#dc2626'),
    'PRECAUTION_EMPLOI':   ('white', '#d97706'),
    'DECONSEILLEE':        ('white', '#f59e0b'),
    'A_PRENDRE_EN_COMPTE': ('white', '#3b82f6'),
    'NON_SIGNIFICATIVE':   ('white', '#6b7280'),
}


def status_badge(value, label=None):
    text, bg = STATUS_COLORS.get(value, ('white', '#9ca3af'))
    display = label or value.replace('_', ' ').title()
    return mark_safe(
        f'<span style="background:{bg};color:{text};'
        f'padding:3px 10px;border-radius:12px;'
        f'font-size:11px;font-weight:600;white-space:nowrap;">'
        f'{display}</span>'
    )


def severity_badge(value, label=None):
    text, bg = SEVERITY_COLORS.get(value, ('white', '#9ca3af'))
    display = label or value.replace('_', ' ').title()
    return mark_safe(
        f'<span style="background:{bg};color:{text};'
        f'padding:3px 10px;border-radius:12px;'
        f'font-size:11px;font-weight:600;white-space:nowrap;">'
        f'{display}</span>'
    )


class DciInteractionInline(admin.TabularInline):
    model = DciInteraction
    fk_name = 'dci1'
    extra = 0
    autocomplete_fields = ('dci2',)
    fields = ('dci2', 'severity', 'description')
    verbose_name = 'Interaction'
    verbose_name_plural = 'Interactions (as DCI 1)'

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('dci1', 'dci2')


@admin.register(DCI)
class DCIAdmin(admin.ModelAdmin):

    list_display = (
        'name',
        'overall_badge',
        't1_badge',
        't2_badge',
        't3_badge',
        'delivery_badge',
    )

    list_filter = (
        'overall_status',
        'first_trimester_status',
        'delivery_status',
    )

    search_fields = ('name',)

    ordering = ('name',)

    inlines = (DciInteractionInline,)

    fieldsets = (
        ('Identity', {
            'fields': ('name',)
        }),
        ('Pregnancy Safety Classification', {
            'fields': (
                'overall_status',
                'first_trimester_status',
                'second_trimester_status',
                'third_trimester_status',
                'delivery_status',
            )
        }),
        ('Documentation', {
            'fields': ('summary', 'source_url'),
        }),
    )

    def get_queryset(self, request):
        return super().get_queryset(request)

    @admin.display(description='Overall')
    def overall_badge(self, obj):
        return status_badge(obj.overall_status, obj.get_overall_status_display())

    @admin.display(description='Trimester 1')
    def t1_badge(self, obj):
        return status_badge(obj.first_trimester_status, obj.get_first_trimester_status_display())

    @admin.display(description='Trimester 2')
    def t2_badge(self, obj):
        return status_badge(obj.second_trimester_status, obj.get_second_trimester_status_display())

    @admin.display(description='Trimester 3')
    def t3_badge(self, obj):
        return status_badge(obj.third_trimester_status, obj.get_third_trimester_status_display())

    @admin.display(description='Delivery')
    def delivery_badge(self, obj):
        return status_badge(obj.delivery_status, obj.get_delivery_status_display())


@admin.register(DciInteraction)
class DciInteractionAdmin(admin.ModelAdmin):

    list_display = (
        'dci1',
        'dci2',
        'severity_badge',
        'description_preview',
    )

    list_filter = ('severity',)

    search_fields = (
        'dci1__name',
        'dci2__name',
        'description',
    )

    ordering = ('severity', 'dci1__name')

    autocomplete_fields = ('dci1', 'dci2')

    fieldsets = (
        ('Interacting DCIs', {
            'fields': ('dci1', 'dci2')
        }),
        ('Interaction Details', {
            'fields': ('severity', 'description')
        }),
    )

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('dci1', 'dci2')

    @admin.display(description='Severity')
    def severity_badge(self, obj):
        return severity_badge(obj.severity, obj.get_severity_display())

    @admin.display(description='Description')
    def description_preview(self, obj):
        if obj.description:
            preview = obj.description[:90]
            if len(obj.description) > 90:
                preview += '...'
            return preview
        return mark_safe('<span style="color:#9ca3af;">—</span>')

    def save_model(self, request, obj, form, change):
        if not change:
            duplicate = DciInteraction.objects.filter(
                dci1=obj.dci2,
                dci2=obj.dci1
            ).exists()
            if duplicate:
                messages.error(
                    request,
                    f'An interaction between {obj.dci2.name} and {obj.dci1.name} '
                    f'already exists. Reverse duplicate not allowed.'
                )
                return
        super().save_model(request, obj, form, change)