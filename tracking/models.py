from django.utils import timezone
from django.db import models


from epics.models import UserStory, StoryStatus, Contributor


class StatusChange(models.Model):

    time = models.DateTimeField(default=timezone.now)

    story = models.ForeignKey(
        UserStory,
        on_delete=models.CASCADE,
    )

    new_status = models.CharField(
        max_length=20,
        choices=StoryStatus,
    )

    contributor = models.ForeignKey(
        Contributor,
        on_delete=models.PROTECT,
        null=True,
    )
