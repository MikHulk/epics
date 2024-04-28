from datetime import timedelta

from django.db import IntegrityError, transaction
from django.utils import timezone

from epics.signals import status_changed
from .models import StatusChange


@transaction.atomic
def record_new_status(sender, contributor, new_status, story, **kwargs):
    last_change = StatusChange.objects.filter(story=story).order_by("-time").first()
    StatusChange.objects.create(
        story=story,
        new_status=new_status,
        contributor=contributor,
    )
    if last_change:
        last_change.duration = timezone.now() - last_change.time
        last_change.save()
