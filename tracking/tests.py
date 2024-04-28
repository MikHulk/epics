from django.contrib.auth.models import User
from django.test import TestCase


from epics.models import Epic, UserStory, StoryStatus, Contributor

from .models import StatusChange


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

    def test_new_us_triger_new_status_change_creation(self):
        self.assertEqual(StatusChange.objects.count(), 0)
        self.product_owner.new_story(
            epic=self.epic,
            title="a new story",
            description="a test story",
        )
        self.assertEqual(
            StatusChange.objects.count(),
            1,
        )
        new_status_change = StatusChange.objects.first()
        self.assertEqual(
            new_status_change.contributor,
            self.product_owner,
        )
        self.assertEqual(
            new_status_change.new_status,
            StoryStatus.CREATED,
        )

    def test_take_us_triger_new_status_change_creation(self):
        self.assertEqual(StatusChange.objects.count(), 0)
        us = self.product_owner.new_story(
            epic=self.epic,
            title="a new story",
            description="a test story",
        )
        self.dev1.take(us)
        self.assertEqual(
            StatusChange.objects.count(),
            2,
        )
        new_status_change = StatusChange.objects.order_by("-time").first()
        self.assertEqual(
            new_status_change.contributor,
            self.dev1,
        )
        self.assertEqual(
            new_status_change.new_status,
            StoryStatus.IN_PROGRESS,
        )

    def test_transfert_us_triger_new_status_change_creation(self):
        self.assertEqual(StatusChange.objects.count(), 0)
        us = self.product_owner.new_story(
            epic=self.epic,
            title="a new story",
            description="a test story",
        )
        self.dev1.take(us)
        self.dev2.take(us)
        self.assertEqual(
            StatusChange.objects.count(),
            3,
        )
        new_status_change = StatusChange.objects.order_by("-time").first()
        self.assertEqual(
            new_status_change.contributor,
            self.dev2,
        )
        self.assertEqual(
            new_status_change.new_status,
            StoryStatus.IN_PROGRESS,
        )

    def test_cancel_us_triger_new_status_change_creation(self):
        self.assertEqual(StatusChange.objects.count(), 0)
        us = self.product_owner.new_story(
            epic=self.epic,
            title="a new story",
            description="a test story",
        )
        self.dev1.take(us)
        self.dev2.take(us)
        self.product_owner.cancel(us)
        self.assertEqual(
            StatusChange.objects.count(),
            4,
        )
        new_status_change = StatusChange.objects.order_by("-time").first()
        self.assertEqual(
            new_status_change.contributor,
            self.product_owner,
        )
        self.assertEqual(
            new_status_change.new_status,
            StoryStatus.CANCELED,
        )

    def test_suspend_us_triger_new_status_change_creation(self):
        self.assertEqual(StatusChange.objects.count(), 0)
        us = self.product_owner.new_story(
            epic=self.epic,
            title="a new story",
            description="a test story",
        )

        self.product_owner.suspend(us)
        self.assertEqual(
            StatusChange.objects.count(),
            2,
        )
        new_status_change = StatusChange.objects.order_by("-time").first()
        self.assertEqual(
            new_status_change.contributor,
            self.product_owner,
        )
        self.assertEqual(
            new_status_change.new_status,
            StoryStatus.SUSPENDED,
        )

        self.product_owner.resume(us)
        self.assertEqual(
            StatusChange.objects.count(),
            3,
        )
        new_status_change = StatusChange.objects.order_by("-time").first()
        self.assertEqual(
            new_status_change.contributor,
            self.product_owner,
        )
        self.assertEqual(
            new_status_change.new_status,
            StoryStatus.CREATED,
        )

        self.dev1.take(us)
        self.product_owner.suspend(us)
        self.assertEqual(
            StatusChange.objects.count(),
            5,
        )
        new_status_change = StatusChange.objects.order_by("-time").first()
        self.assertEqual(
            new_status_change.contributor,
            self.product_owner,
        )
        self.assertEqual(
            new_status_change.new_status,
            StoryStatus.SUSPENDED,
        )

        self.product_owner.resume(us)
        self.assertEqual(
            StatusChange.objects.count(),
            6,
        )
        new_status_change = StatusChange.objects.order_by("-time").first()
        self.assertEqual(
            new_status_change.contributor,
            self.product_owner,
        )
        self.assertEqual(
            new_status_change.new_status,
            StoryStatus.IN_PROGRESS,
        )
