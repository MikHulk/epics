from datetime import datetime, timezone, timedelta

from django.contrib.auth.models import User
from django.test import TestCase


from epics.models import Epic, UserStory, StoryStatus, Contributor

from tracking.models import StatusChange


class StatusChangeTestCase(TestCase):

    def setUp(self):
        self.po_user = User.objects.create(username="po_test")
        self.product_owner = Contributor.objects.create(user=self.po_user)
        self.dev1_user = User.objects.create(username="dev1_test")
        self.dev1 = Contributor.objects.create(user=self.dev1_user)
        self.dev2_user = User.objects.create(username="dev2_test")
        self.dev2 = Contributor.objects.create(user=self.dev2_user)
        self.epic = Epic.objects.create(
            title="Test epic",
            description="test epic",
            owner=self.product_owner,
        )

        # Happy path
        us1 = UserStory.objects.create(
            epic=self.epic,
            title="story 1",
            description="a test story",
            status=StoryStatus.FINISHED,
        )
        StatusChange.objects.create(
            story=us1,
            time=datetime(2012, 3, 3, 14, 0, tzinfo=timezone.utc),
            new_status=StoryStatus.CREATED,
            contributor=self.product_owner,
            duration=timedelta(days=1),
        )
        StatusChange.objects.create(
            story=us1,
            time=datetime(2012, 3, 4, 14, 0, tzinfo=timezone.utc),
            new_status=StoryStatus.IN_PROGRESS,
            contributor=self.dev1,
            duration=timedelta(days=1),
        )
        StatusChange.objects.create(
            story=us1,
            time=datetime(2012, 3, 5, 14, 0, tzinfo=timezone.utc),
            new_status=StoryStatus.FINISHED,
            contributor=self.product_owner,
        )

        # Canceled from the begining
        us2 = UserStory.objects.create(
            epic=self.epic,
            title="story 2",
            description="a test story",
            status=StoryStatus.CANCELED,
        )
        StatusChange.objects.create(
            story=us2,
            time=datetime(2012, 3, 3, 14, 30, tzinfo=timezone.utc),
            new_status=StoryStatus.CREATED,
            contributor=self.product_owner,
            duration=timedelta(days=1),
        )
        StatusChange.objects.create(
            story=us2,
            time=datetime(2012, 3, 4, 14, 30, tzinfo=timezone.utc),
            new_status=StoryStatus.CANCELED,
            contributor=self.product_owner,
        )

        # Suspended then taken
        us3 = UserStory.objects.create(
            epic=self.epic,
            title="story 3",
            description="a test story",
            status=StoryStatus.FINISHED,
        )
        StatusChange.objects.create(
            story=us3,
            time=datetime(2012, 3, 3, 15, 0, tzinfo=timezone.utc),
            new_status=StoryStatus.CREATED,
            contributor=self.product_owner,
            duration=timedelta(days=1),
        )
        StatusChange.objects.create(
            story=us3,
            time=datetime(2012, 3, 4, 15, 0, tzinfo=timezone.utc),
            new_status=StoryStatus.SUSPENDED,
            contributor=self.product_owner,
            duration=timedelta(days=1),
        )
        StatusChange.objects.create(
            story=us3,
            time=datetime(2012, 3, 5, 15, 0, tzinfo=timezone.utc),
            new_status=StoryStatus.CREATED,
            contributor=self.product_owner,
            duration=timedelta(days=1),
        )
        StatusChange.objects.create(
            story=us3,
            time=datetime(2012, 3, 6, 15, 0, tzinfo=timezone.utc),
            new_status=StoryStatus.IN_PROGRESS,
            contributor=self.dev2,
            duration=timedelta(days=1),
        )
        StatusChange.objects.create(
            story=us3,
            time=datetime(2012, 3, 7, 15, 0, tzinfo=timezone.utc),
            new_status=StoryStatus.FINISHED,
            contributor=self.product_owner,
        )

        # taken suspended then transfered
        us4 = UserStory.objects.create(
            epic=self.epic,
            title="story 4",
            description="a test story",
            status=StoryStatus.FINISHED,
        )
        StatusChange.objects.create(
            story=us4,
            time=datetime(2012, 3, 3, 15, 30, tzinfo=timezone.utc),
            new_status=StoryStatus.CREATED,
            contributor=self.product_owner,
            duration=timedelta(days=1),
        )
        StatusChange.objects.create(
            story=us4,
            time=datetime(2012, 3, 4, 15, 30, tzinfo=timezone.utc),
            new_status=StoryStatus.IN_PROGRESS,
            contributor=self.dev2,
            duration=timedelta(days=1),
        )
        StatusChange.objects.create(
            story=us4,
            time=datetime(2012, 3, 5, 15, 30, tzinfo=timezone.utc),
            new_status=StoryStatus.SUSPENDED,
            contributor=self.product_owner,
            duration=timedelta(days=1),
        )
        StatusChange.objects.create(
            story=us4,
            time=datetime(2012, 3, 6, 15, 30, tzinfo=timezone.utc),
            new_status=StoryStatus.IN_PROGRESS,
            contributor=self.product_owner,
            duration=timedelta(hours=1),
        )
        StatusChange.objects.create(
            story=us4,
            time=datetime(2012, 3, 6, 16, 30, tzinfo=timezone.utc),
            new_status=StoryStatus.IN_PROGRESS,
            contributor=self.dev1,
            duration=timedelta(hours=23),
        )
        StatusChange.objects.create(
            story=us4,
            time=datetime(2012, 3, 7, 15, 30, tzinfo=timezone.utc),
            new_status=StoryStatus.FINISHED,
            contributor=self.product_owner,
        )

        # never started
        us5 = UserStory.objects.create(
            epic=self.epic,
            title="story 5",
            description="a test story",
        )
        StatusChange.objects.create(
            story=us5,
            time=datetime(2012, 3, 3, 16, 0, tzinfo=timezone.utc),
            new_status=StoryStatus.CREATED,
            contributor=self.product_owner,
        )

    def test_total_epic_stats(self):
        stats = StatusChange.epic_stats(
            self.epic,
            time=datetime(2012, 3, 7, 16, 0, tzinfo=timezone.utc),
        )
        self.assertEqual(
            stats.total_time,
            timedelta(days=15),
        )
