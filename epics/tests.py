from django.test import TestCase
from django.utils import timezone

from .models import Epic, UserStory, StoryStatus


class EpicTestCase(TestCase):

    def setUp(self):
        self.start_time = timezone.now()
        self.epic = Epic.objects.create(
            title="An epic test.",
            description="This is a test.",
        )

    def tearDown(self):
        self.start_time = timezone.now()
        self.epic.delete()

    def test_epic_properties(self):
        self.assertEqual(self.epic.title, "An epic test.")
        self.assertEqual(self.epic.description, "This is a test.")
        self.assertTrue(
            self.epic.pub_date > self.start_time and self.epic.pub_date < timezone.now()
        )
        self.assertEqual(
            str(self.epic),
            f"Epic({self.epic.pk}): {self.epic.title}",
        )

    def test_us_creation(self):
        self.epic.stories.add(
            UserStory(
                title="A first story",
                description="This is a first story",
            ),
            bulk=False,
        )
        self.assertEqual(self.epic.stories.count(), 1)
        self.epic.stories.add(
            UserStory(
                title="Another story",
                description="This is a second story",
            ),
            bulk=False,
        )
        self.assertEqual(self.epic.stories.count(), 2)

    def test_epic_stats(self):
        self.epic.stories.add(
            UserStory(
                title="us1",
                description="This is a on going story",
                status=StoryStatus.IN_PROGRESS,
            ),
            bulk=False,
        )
        self.epic.stories.add(
            UserStory(
                title="us2",
                description="This is a just created story",
            ),
            bulk=False,
        )
        self.epic.stories.add(
            UserStory(
                title="us3",
                description="This is a finished story",
                status=StoryStatus.FINISHED,
            ),
            bulk=False,
        )
        self.epic.stories.add(
            UserStory(
                title="us4",
                description="This is a canceled story",
                status=StoryStatus.CANCELED,
            ),
            bulk=False,
        )
        self.epic.stories.add(
            UserStory(
                title="us5",
                description="This is a suspended story",
                status=StoryStatus.SUSPENDED,
            ),
            bulk=False,
        )
        self.assertEqual(self.epic.stories.count(), 5)
        stats = self.epic.stats
        self.assertEqual(stats.total, 5)
        self.assertEqual(stats.in_progress, 1)
        self.assertEqual(stats.created, 1)
        self.assertEqual(stats.suspended, 1)
        self.assertEqual(stats.canceled, 1)
        self.assertEqual(stats.finished, 1)
        us5 = self.epic.stories.get(title="us5")
        us5.status = StoryStatus.IN_PROGRESS
        us5.save()
        us2 = self.epic.stories.get(title="us2")
        us2.status = StoryStatus.IN_PROGRESS
        us2.save()
        self.assertEqual(self.epic.stories.count(), 5)
        stats = self.epic.stats
        self.assertEqual(stats.total, 5)
        self.assertEqual(stats.in_progress, 3)
        self.assertEqual(stats.created, 0)
        self.assertEqual(stats.suspended, 0)
        self.assertEqual(stats.canceled, 1)
        self.assertEqual(stats.finished, 1)
