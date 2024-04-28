from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone

from epics.models import Contributor, Epic, UserStory, StoryStatus
from epics.exceptions import BadCommand


class WorkflowTestCase(TestCase):

    def setUp(self):
        self.po_user = User.objects.create(username="po_test")
        self.product_owner = Contributor.objects.create(user=self.po_user)
        self.dev1_user = User.objects.create(username="dev1_test")
        self.dev1 = Contributor.objects.create(user=self.dev1_user)
        self.dev2_user = User.objects.create(username="dev2_test")
        self.dev2 = Contributor.objects.create(user=self.dev2_user)

    def test_fullname(self):
        self.assertEqual(self.product_owner.fullname, "po_test")
        self.po_user.first_name = "Foo"
        self.po_user.save()
        self.assertEqual(self.product_owner.fullname, "Foo")
        self.po_user.last_name = "Bar"
        self.po_user.save()
        self.assertEqual(self.product_owner.fullname, "Foo Bar")

    def test_create_epic(self):
        self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        self.assertEqual(Epic.objects.count(), 1)
        self.assertEqual(self.product_owner.epics.count(), 1)
        epic = self.product_owner.epics.first()
        self.assertEqual(epic.title, "A new epic")
        self.assertEqual(epic.description, "Build a django app.")

    def test_owner_see_his_epics_only(self):
        self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        self.assertEqual(Epic.objects.count(), 1)
        self.dev1.new_epic(
            title="An epic for us.",
            description="Build a new web framework.",
        )
        self.assertEqual(Epic.objects.count(), 2)
        self.assertEqual(self.product_owner.epics.count(), 1)
        epic = self.product_owner.epics.first()
        self.assertEqual(epic.title, "A new epic")
        self.assertEqual(epic.description, "Build a django app.")

    def test_only_owner_can_create_us_for_epics(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.assertEqual(
            self.product_owner.epics.first().stories.count(),
            1,
        )
        with self.assertRaises(BadCommand):
            self.dev1.new_story(
                epic=epic,
                title="Build the model",
                description="A good app needs a good model.",
            )

    def test_everyone_can_take_us(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.assertEqual(
            self.product_owner.epics.first().stories.count(),
            1,
        )
        self.dev1.take(us)
        self.assertEqual(self.dev1.stories.count(), 1)

    def test_everyone_can_transfert_us(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.assertEqual(
            self.product_owner.epics.first().stories.count(),
            1,
        )
        self.dev1.take(us)
        self.assertEqual(self.dev1.stories.count(), 1)
        self.assertEqual(self.dev2.stories.count(), 0)
        self.dev2.take(us)
        self.assertEqual(self.dev1.stories.count(), 0)
        self.assertEqual(self.dev2.stories.count(), 1)

    def test_nobody_can_take_finished_us(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        us.status = StoryStatus.FINISHED
        us.save()
        with self.assertRaises(BadCommand):
            self.dev1.take(us)
        self.assertEqual(self.dev1.stories.count(), 0)

    def test_nobody_can_take_canceled_us(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        us.status = StoryStatus.CANCELED
        us.save()
        with self.assertRaises(BadCommand):
            self.dev1.take(us)
        self.assertEqual(self.dev1.stories.count(), 0)

    def test_nobody_can_take_suspended_us(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        us.status = StoryStatus.SUSPENDED
        us.save()
        with self.assertRaises(BadCommand):
            self.dev1.take(us)
        self.assertEqual(self.dev1.stories.count(), 0)

    def test_owner_can_suspend(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.suspend(us)
        self.assertEqual(us.status, StoryStatus.SUSPENDED)

    def test_owner_can_suspend_in_progress_us(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.dev1.take(us)
        self.assertEqual(us.status, StoryStatus.IN_PROGRESS)
        self.product_owner.suspend(us)
        self.assertEqual(us.status, StoryStatus.SUSPENDED)

    def test_only_owner_can_suspend(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        with self.assertRaises(BadCommand):
            self.dev1.suspend(us)
        self.assertEqual(us.status, StoryStatus.CREATED)

    def test_owner_can_resume(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.suspend(us)
        self.assertEqual(us.status, StoryStatus.SUSPENDED)
        self.product_owner.resume(us)
        self.assertEqual(us.status, StoryStatus.CREATED)

    def test_owner_can_resume_in_progress_us(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.dev1.take(us)
        self.assertEqual(us.status, StoryStatus.IN_PROGRESS)
        self.product_owner.suspend(us)
        self.assertEqual(us.status, StoryStatus.SUSPENDED)
        self.product_owner.resume(us)
        self.assertEqual(us.status, StoryStatus.IN_PROGRESS)
        self.assertEqual(us.assigned_to, self.dev1)

    def test_only_owner_can_resume(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.suspend(us)
        with self.assertRaises(BadCommand):
            self.dev1.resume(us)
        self.assertEqual(us.status, StoryStatus.SUSPENDED)

    def test_owner_can_cancel(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.cancel(us)
        self.assertEqual(us.status, StoryStatus.CANCELED)

    def test_only_owner_can_cancel(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        with self.assertRaises(BadCommand):
            self.dev1.cancel(us)
        self.assertEqual(us.status, StoryStatus.CREATED)

    def test_canceled_cannot_be_suspended(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.cancel(us)
        with self.assertRaises(BadCommand):
            self.product_owner.suspend(us)
        with self.assertRaises(BadCommand):
            self.dev1.suspend(us)
        self.assertEqual(us.status, StoryStatus.CANCELED)

    def test_suspended_can_be_canceled(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.suspend(us)
        self.assertEqual(us.status, StoryStatus.SUSPENDED)
        self.product_owner.cancel(us)
        self.assertEqual(us.status, StoryStatus.CANCELED)

    def test_owner_can_validate(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.validate(us)
        self.assertEqual(us.status, StoryStatus.FINISHED)

    def test_only_owner_can_validate(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        with self.assertRaises(BadCommand):
            self.dev1.validate(us)
        self.assertEqual(us.status, StoryStatus.CREATED)

    def test_canceled_cannot_be_validated(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.cancel(us)
        with self.assertRaises(BadCommand):
            self.product_owner.validate(us)
        with self.assertRaises(BadCommand):
            self.dev1.validate(us)
        self.assertEqual(us.status, StoryStatus.CANCELED)

    def test_finished_cannot_be_canceled(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.validate(us)
        with self.assertRaises(BadCommand):
            self.product_owner.cancel(us)
        with self.assertRaises(BadCommand):
            self.dev1.cancel(us)
        self.assertEqual(us.status, StoryStatus.FINISHED)

    def test_finished_cannot_be_suspended(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.validate(us)
        with self.assertRaises(BadCommand):
            self.product_owner.suspend(us)
        with self.assertRaises(BadCommand):
            self.dev1.suspend(us)
        self.assertEqual(us.status, StoryStatus.FINISHED)

    def test_finished_cannot_be_taken(self):
        epic = self.product_owner.new_epic(
            title="A new epic",
            description="Build a django app.",
        )
        us = self.product_owner.new_story(
            epic=epic,
            title="Build the model",
            description="A good app needs a good model.",
        )
        self.product_owner.validate(us)
        with self.assertRaises(BadCommand):
            self.dev1.take(us)
        self.assertEqual(us.status, StoryStatus.FINISHED)
