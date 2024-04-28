from epics.signals import status_changed
from .models import StatusChange


def record_new_status(sender, contributor, new_status, story, **kwargs):
    StatusChange.objects.create(
        story=story,
        new_status=new_status,
        contributor=contributor,
    )
