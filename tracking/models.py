from dataclasses import dataclass

from django.utils import timezone
from django.db import models


from epics.models import UserStory, StoryStatus, Contributor


@dataclass
class Stats:
    total_time: int = 0


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

    duration = models.DurationField(null=True, blank=True)

    def __str__(self):
        return f"{self.time.isoformat()}: {self.story} {self.new_status}"

    @staticmethod
    def epic_stats(epic, time=None):
        if not time:
            time = timezone.now()
        qs = (
            StatusChange.objects.select_related("story")
            .select_related("story__epic")
            .filter(story__epic=epic)
        )
        unfinished_stories_events = (
            qs.exclude(story__status=StoryStatus.CANCELED)
            .exclude(story__status=StoryStatus.FINISHED)
        )
        unfinished_stories_last_events = (
            unfinished_stories_events.annotate(
                last_event=models.Window(
                    models.Max("time"),
                    partition_by="story"
                ))
            .filter(time=models.F("last_event"))
        )
        return Stats(
            total_time=(
                qs.aggregate(total=models.Sum("duration"))["total"]
                + (
                    unfinished_stories_last_events
                    .annotate(current_duration=time - models.F("time"))
                    .aggregate(total=models.Sum(models.F("current_duration")))
                )["total"]
            )
        )
