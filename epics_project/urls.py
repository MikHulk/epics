from django.contrib import admin
from django.urls import path, include

from epics import router as epics

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include(epics.router.urls)),
    path('api-auth/', include('rest_framework.urls'))
]
