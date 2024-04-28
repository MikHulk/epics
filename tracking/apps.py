from django.apps import AppConfig


class TrackingConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "tracking"

    def ready(self):
        from epics.signals import status_changed
        from epics.models import UserStory
        from .handlers import record_new_status

        status_changed.connect(record_new_status, UserStory, weak=False)
