from dataclasses import dataclass

from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone


class Contributor(models.Model):
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
    )

    @property
    def fullname(self):
        if self.user.first_name:
            if self.user.last_name:
                return f"{self.user.first_name} {self.user.last_name}"
            else:
                return f"{self.user.first_name}"
        else:
            return self.user.username

    def __str__(self):
        return f"{self.fullname}"


@dataclass
class Stats:
    created: int = 0
    in_progress: int = 0
    suspended: int = 0
    canceled: int = 0
    finished: int = 0

    @property
    def total(self):
        return (
            self.created
            + self.in_progress
            + self.suspended
            + self.canceled
            + self.finished
        )


class StoryStatus(models.TextChoices):
    CREATED = "created"
    IN_PROGRESS = "in progress"
    SUSPENDED = "suspended"
    CANCELED = "canceled"
    FINISHED = "finished"


class Epic(models.Model):
    title = models.CharField(max_length=256)
    pub_date = models.DateTimeField("date published", default=timezone.now)
    description = models.TextField()

    owner = models.ForeignKey(
        Contributor,
        on_delete=models.PROTECT,
    )

    @property
    def stats(self):
        return Stats(
            **{
                StoryStatus(elem["status"]).name.lower(): elem["count"]
                for elem in self.stories.values("status")
                .annotate(count=models.Count("status"))
                .order_by()
            }
        )

    def __str__(self):
        return f"Epic({self.pk}): {self.title}"


class UserStory(models.Model):
    class Meta:
        verbose_name = "User Story"
        verbose_name_plural = "User Stories"

    epic = models.ForeignKey(
        Epic,
        on_delete=models.CASCADE,
        related_name="stories",
        related_query_name="story",
    )
    title = models.CharField(max_length=256)
    pub_date = models.DateTimeField("date published", default=timezone.now)
    description = models.TextField()
    status = models.CharField(
        max_length=20,
        choices=StoryStatus,
        default=StoryStatus.CREATED,
    )

    def __str__(self):
        return f"{self.epic.title} -> {self.title}, {self.status}"
