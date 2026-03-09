import logging
from django import db

logger = logging.getLogger(__name__)


def sendMissingMeasurementsAlert():
    from alerts.services import AlertService
    db.close_old_connections()
    try:
        logger.info("Running task: sendMissingMeasurementsAlert")
        AlertService.sendMissingMeasurementsAlert()
        logger.info("Completed task: sendMissingMeasurementsAlert")
    except Exception as e:
        logger.error(f"Task sendMissingMeasurementsAlert failed: {e}", exc_info=True)
    finally:
        db.close_old_connections()


def sendUnconfirmedAppointmentAlert():
    from alerts.services import AlertService
    db.close_old_connections()
    try:
        logger.info("Running task: sendUnconfirmedAppointmentAlert")
        AlertService.sendUnconfirmedAppointmentAlert()
        logger.info("Completed task: sendUnconfirmedAppointmentAlert")
    except Exception as e:
        logger.error(f"Task sendUnconfirmedAppointmentAlert failed: {e}", exc_info=True)
    finally:
        db.close_old_connections()


def sendPregnancyNoAppointmentAlert():
    from alerts.services import AlertService
    db.close_old_connections()
    try:
        logger.info("Running task: sendPregnancyNoAppointmentAlert")
        AlertService.sendPregnancyNoAppointmentAlert()
        logger.info("Completed task: sendPregnancyNoAppointmentAlert")
    except Exception as e:
        logger.error(f"Task sendPregnancyNoAppointmentAlert failed: {e}", exc_info=True)
    finally:
        db.close_old_connections()
