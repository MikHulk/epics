from rest_framework import routers

from .views import ContributorViewSet, EpicViewSet

router = routers.DefaultRouter()
router.register(r'contributors', ContributorViewSet)
router.register(r'epics', EpicViewSet)
