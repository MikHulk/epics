from django.test import TestCase
from django.utils import timezone

from .models import Epic, UserStory, StoryStatus


class EpicTestCase(TestCase):

    def setUp(self):
        self.start_time = timezone.now()

    def test_epic_properties(self):
        epic = Epic.objects.create(
            title="An epic test.",
            description="This is a test.",
        )
        self.assertEqual(epic.title, "An epic test.")
        self.assertEqual(epic.description, "This is a test.")
        self.assertTrue(
            epic.pub_date > self.start_time and epic.pub_date < timezone.now()
        )
        self.assertEqual(
            str(epic),
            f"Epic({epic.pk}): {epic.title}",
        )

    def test_us_creation(self):
        epic = Epic.objects.create(
            title="An epic test.",
            description="This is a test.",
        )
        epic.stories.add(
            UserStory(
                title="A first story",
                description="This is a first story",
            ),
            bulk=False,
        )
        self.assertEqual(epic.stories.count(), 1)
        epic.stories.add(
            UserStory(
                title="Another story",
                description="This is a second story",
            ),
            bulk=False,
        )
        self.assertEqual(epic.stories.count(), 2)

    def test_epic_stats(self):
        epic = Epic.objects.create(
            title="An epic test.",
            description="This is a test.",
        )
        epic.stories.add(
            UserStory(
                title="us1",
                description="This is a on going story",
                status=StoryStatus.IN_PROGRESS,
            ),
            bulk=False,
        )
        epic.stories.add(
            UserStory(
                title="us2",
                description="This is a just created story",
            ),
            bulk=False,
        )
        epic.stories.add(
            UserStory(
                title="us3",
                description="This is a finished story",
                status=StoryStatus.FINISHED,
            ),
            bulk=False,
        )
        epic.stories.add(
            UserStory(
                title="us4",
                description="This is a canceled story",
                status=StoryStatus.CANCELED,
            ),
            bulk=False,
        )
        epic.stories.add(
            UserStory(
                title="us5",
                description="This is a suspended story",
                status=StoryStatus.SUSPENDED,
            ),
            bulk=False,
        )
        self.assertEqual(epic.stories.count(), 5)
        stats = epic.stats
        self.assertEqual(stats.total, 5)
        self.assertEqual(stats.in_progress, 1)
        self.assertEqual(stats.created, 1)
        self.assertEqual(stats.suspended, 1)
        self.assertEqual(stats.canceled, 1)
        self.assertEqual(stats.finished, 1)
        us5 = epic.stories.get(title="us5")
        us5.status = StoryStatus.IN_PROGRESS
        us5.save()
        us2 = epic.stories.get(title="us2")
        us2.status = StoryStatus.IN_PROGRESS
        us2.save()
        self.assertEqual(epic.stories.count(), 5)
        stats = epic.stats
        self.assertEqual(stats.total, 5)
        self.assertEqual(stats.in_progress, 3)
        self.assertEqual(stats.created, 0)
        self.assertEqual(stats.suspended, 0)
        self.assertEqual(stats.canceled, 1)
        self.assertEqual(stats.finished, 1)
