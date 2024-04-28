from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone

from epics.models import Contributor, Epic, UserStory, StoryStatus
from epics.exceptions import BadCommand


class UsTestCase(TestCase):

    def setUp(self):
        self.po_user = User.objects.create(username="po_test")
        self.product_owner = Contributor.objects.create(user=self.po_user)
        self.dev1_user = User.objects.create(username="dev1_test")
        self.dev1 = Contributor.objects.create(user=self.dev1_user)
        self.dev2_user = User.objects.create(username="dev2_test")
        self.dev2 = Contributor.objects.create(user=self.dev2_user)
        epic = Epic.objects.create(
            title="Test epic",
            description="test epic",
            owner=self.product_owner,
        )
        UserStory.objects.create(
            title="US 1",
            description="test us",
            assigned_to=self.dev1,
            epic=epic,
            status=StoryStatus.IN_PROGRESS,
        )
        UserStory.objects.create(
            title="US 2",
            description="test us",
            assigned_to=self.dev2,
            epic=epic,
            status=StoryStatus.IN_PROGRESS,
        )
        UserStory.objects.create(
            title="US 3",
            description="test us",
            assigned_to=self.dev1,
            epic=epic,
            status=StoryStatus.SUSPENDED,
        )
        UserStory.objects.create(
            title="US 4",
            description="test us",
            assigned_to=self.dev2,
            epic=epic,
            status=StoryStatus.SUSPENDED,
        )
        UserStory.objects.create(
            title="US 5",
            description="test us",
            assigned_to=None,
            epic=epic,
            status=StoryStatus.CREATED,
        )

    def test_dev_see_assigned(self):
        self.assertEqual(
            self.dev1.stories.count(),
            2,
        )
        self.assertEqual(
            self.dev1.stories.get(title="US 1").title,
            "US 1",
        )
        self.assertEqual(
            self.dev1.stories.get(title="US 3").title,
            "US 3",
        )
        with self.assertRaises(UserStory.DoesNotExist):
            self.dev1.stories.get(title="US 2")
        with self.assertRaises(UserStory.DoesNotExist):
            self.dev1.stories.get(title="US 5")
        self.assertEqual(
            self.dev2.stories.count(),
            2,
        )
        self.assertEqual(
            self.dev2.stories.get(title="US 2").title,
            "US 2",
        )
        self.assertEqual(
            self.dev2.stories.get(title="US 4").title,
            "US 4",
        )
        with self.assertRaises(UserStory.DoesNotExist):
            self.dev2.stories.get(title="US 1")
        with self.assertRaises(UserStory.DoesNotExist):
            self.dev2.stories.get(title="US 5")

    def test_dev_see_in_progress(self):
        self.assertEqual(
            self.dev1.in_progress.count(),
            1,
        )
        self.assertEqual(
            self.dev1.in_progress.get(title="US 1").title,
            "US 1",
        )
        with self.assertRaises(UserStory.DoesNotExist):
            self.dev1.in_progress.get(title="US 3")

        self.assertEqual(
            self.dev2.in_progress.count(),
            1,
        )
        self.assertEqual(
            self.dev2.in_progress.get(title="US 2").title,
            "US 2",
        )
        with self.assertRaises(UserStory.DoesNotExist):
            self.dev2.in_progress.get(title="US 4")

    def test_dev_see_suspended(self):
        self.assertEqual(
            self.dev1.suspended.count(),
            1,
        )
        self.assertEqual(
            self.dev1.suspended.get(title="US 3").title,
            "US 3",
        )
        with self.assertRaises(UserStory.DoesNotExist):
            self.dev1.suspended.get(title="US 1")

        self.assertEqual(
            self.dev2.suspended.count(),
            1,
        )
        self.assertEqual(
            self.dev2.suspended.get(title="US 4").title,
            "US 4",
        )
        with self.assertRaises(UserStory.DoesNotExist):
            self.dev2.suspended.get(title="US 2")
