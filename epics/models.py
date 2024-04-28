from dataclasses import dataclass

from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone

from .signals import status_changed
from .exceptions import BadCommand


class Contributor(models.Model):
    user = models.OneToOneField(
        User,
        on_delete=models.PROTECT,
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

    def new_epic(self, title, description):
        return Epic.objects.create(
            title=title,
            description=description,
            owner=self,
        )

    def new_story(self, epic, title, description):
        if epic.owner != self:
            raise BadCommand(f"{self} is not the owner")
        story = UserStory.objects.create(
            title=title,
            description=description,
            epic=epic,
        )
        story.status_changed(self)
        return story

    def take(self, story):
        if story.status not in (StoryStatus.CREATED, StoryStatus.IN_PROGRESS):
            raise BadCommand(f"Cannot assign {story}")
        story.assigned_to = self
        story.status = StoryStatus.IN_PROGRESS
        story.save()
        story.status_changed(self)

    @property
    def in_progress(self):
        return self.stories.filter(status=StoryStatus.IN_PROGRESS)

    def suspend(self, story):
        if story.status not in (StoryStatus.CREATED, StoryStatus.IN_PROGRESS):
            raise BadCommand(f"Cannot suspend {story}")
        if story.epic.owner != self:
            raise BadCommand(f"{self} is not allowed to suspend {story}")
        story.status = StoryStatus.SUSPENDED
        story.save()
        story.status_changed(self)

    def resume(self, story):
        if not story.status == StoryStatus.SUSPENDED:
            raise BadCommand(f"Cannot suspend {story}")
        if story.epic.owner != self:
            raise BadCommand(f"{self} is not allowed to resume {story}")
        story.status = (
            story.assigned_to and StoryStatus.IN_PROGRESS or StoryStatus.CREATED
        )
        story.save()
        story.status_changed(self)

    @property
    def suspended(self):
        return self.stories.filter(status=StoryStatus.SUSPENDED)

    def cancel(self, story):
        if story.status not in (
            StoryStatus.CREATED,
            StoryStatus.IN_PROGRESS,
            StoryStatus.SUSPENDED,
        ):
            raise BadCommand(f"Cannot cancel {story}")
        if story.epic.owner != self:
            raise BadCommand(f"{self} is not allowed to cancel {story}")
        story.status = StoryStatus.CANCELED
        story.assigned_to = None
        story.save()
        story.status_changed(self)

    def validate(self, story):
        if story.status not in (
            StoryStatus.CREATED,
            StoryStatus.IN_PROGRESS,
            StoryStatus.SUSPENDED,
        ):
            raise BadCommand(f"Cannot cancel {story}")
        if story.epic.owner != self:
            raise BadCommand(f"{self} is not allowed to cancel {story}")
        story.status = StoryStatus.FINISHED
        story.assigned_to = None
        story.save()
        story.status_changed(self)

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
        related_name="epics",
        related_query_name="epic",
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
    assigned_to = models.ForeignKey(
        Contributor,
        on_delete=models.PROTECT,
        null=True,
        related_name="stories",
        related_query_name="story",
    )

    def status_changed(self, contributor=None):
        status_changed.send(
            sender=self.__class__,
            contributor=contributor,
            new_status=self.status,
            story=self,
        )

    def __str__(self):
        return f"{self.epic.title} -> {self.title}, {self.status}"
