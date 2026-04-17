import logging
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from alerts.reminders import createMedicationReminder
from django_apscheduler.jobstores import DjangoJobStore
from utils.firebase import send_push_notification_to_user
from django_apscheduler.models import DjangoJobExecution

logger = logging.getLogger(__name__)

_scheduler_started = False


def delete_old_job_executions(max_age=604_800):
    """Deletes job execution entries older than max_age seconds (default: 1 week)."""
    from django import db
    db.close_old_connections()
    try:
        DjangoJobExecution.objects.delete_old_job_executions(max_age)
    finally:
        db.close_old_connections()

def start():
    global _scheduler_started
    if _scheduler_started:
        return
    _scheduler_started = True

    from alerts.tasks import (
        sendMissingMeasurementsAlert,
        sendUnconfirmedAppointmentAlert,
        sendPregnancyNoAppointmentAlert,
    )
    from alerts.reminders import (
        createAppointmentReminder,
        createMedicationReminder,
    )

    scheduler = BackgroundScheduler(
        timezone="Africa/Tunis",
        job_defaults={
            'misfire_grace_time': 300,  # allow up to 5 min late
            'coalesce': True,           # if multiple misfires, run once
            'max_instances': 1,
        },
    )
    scheduler.add_jobstore(DjangoJobStore(), "default")

    # --- SYSTEM alerts ---

    scheduler.add_job(
        sendMissingMeasurementsAlert,       #WORKING!
        trigger=CronTrigger(hour=9, minute=0),
        id="sendMissingMeasurementsAlert",
        name="Send Missing Measurements Alert",
        jobstore="default",
        replace_existing=True,
    )
    

    scheduler.add_job(
        sendUnconfirmedAppointmentAlert,    #WORKING!
        trigger=CronTrigger(hour=9, minute=15),
        id="sendUnconfirmedAppointmentAlert",
        name="Send Unconfirmed Appointment Alert",
        jobstore="default",
        replace_existing=True,
    )

    scheduler.add_job(
        sendPregnancyNoAppointmentAlert,        #WORKING!
        trigger=CronTrigger(hour=9, minute=30),
        id="sendPregnancyNoAppointmentAlert",
        name="Send Pregnancy No Appointment Alert",
        jobstore="default",
        replace_existing=True,
    )

    # --- REMINDER alerts ---

    scheduler.add_job(
        createAppointmentReminder,      #WORKING!
        trigger=CronTrigger(hour=18, minute=00),
        id="createAppointmentReminder",
        name="Create Appointment Reminders",
        jobstore="default",
        replace_existing=True,
    )

    scheduler.add_job(
        createMedicationReminder, #WORKING! but still some fixes needed to avoid duplicate reminders
        trigger=CronTrigger(hour=11,minute=15),
        id="createMedicationReminder",
        name="Create Medication Reminders",
        jobstore="default",
        replace_existing=True,
    )

    # --- Cleanup old job execution logs (runs weekly) ---

    scheduler.add_job(
        delete_old_job_executions,
        trigger=CronTrigger(day_of_week="mon", hour=0, minute=0),
        id="delete_old_job_executions",
        name="Delete Old Job Executions",
        jobstore="default",
        replace_existing=True,
        misfire_grace_time=None,
        
    )
    

    logger.info("Starting scheduler...")
    scheduler.start()
    logger.info("Scheduler started.")