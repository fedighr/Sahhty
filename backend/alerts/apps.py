from django.apps import AppConfig
import os


class AlertsConfig(AppConfig):
    name = 'alerts'

    def ready(self):
        # Under runserver, Django spawns 2 processes. RUN_MAIN is only set in the
        # reloader child. When NOT using runserver (e.g. gunicorn), RUN_MAIN is
        # never set — the _scheduler_started guard in scheduler.py handles that.
        import sys
        is_runserver = 'runserver' in sys.argv
        if not is_runserver or os.environ.get('RUN_MAIN') == 'true':
            from alerts.scheduler import start
            start()
