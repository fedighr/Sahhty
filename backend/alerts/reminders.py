import logging
from django import db

logger = logging.getLogger(__name__)


def createAppointmentReminder():
    from alerts.services import AlertService
    db.close_old_connections()
    try:
        logger.info("Running reminder: createAppointmentReminder")
        AlertService.createAppointmentReminder()
        logger.info("Completed reminder: createAppointmentReminder")
    except Exception as e:
        logger.error(f"Reminder createAppointmentReminder failed: {e}", exc_info=True)
    finally:
        db.close_old_connections()


def createMedicationReminder():
    from alerts.services import AlertService
    db.close_old_connections()
    try:
        logger.info("Running reminder: createMedicationReminder")
        AlertService.createMedicationReminder()
        logger.info("Completed reminder: createMedicationReminder")
    except Exception as e:
        logger.error(f"Reminder createMedicationReminder failed: {e}", exc_info=True)
    finally:
        db.close_old_connections()
