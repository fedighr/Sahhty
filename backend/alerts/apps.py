from django.apps import AppConfig
import os
import sys


class AlertsConfig(AppConfig):
    name = 'alerts'

    def ready(self):
        is_runserver = 'runserver' in sys.argv
        is_testing = 'pytest' in sys.modules

        if is_testing:
            return

        if not is_runserver or os.environ.get('RUN_MAIN') == 'true':
            from alerts.scheduler import start
            start()