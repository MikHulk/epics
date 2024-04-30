from rest_framework import routers

from .views import ContributorViewSet, EpicViewSet, UserStoryViewSet

router = routers.DefaultRouter()
router.register(r'contributors', ContributorViewSet)
router.register(r'epics', EpicViewSet)
router.register(r'stories', UserStoryViewSet)
