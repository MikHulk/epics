from django.contrib import admin
from django.urls import path, include

from epics import router as epics
from frontend import views

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", views.landing_view),
    path("epics-api/", include(epics.router.urls)),
    path('api-auth/', include('rest_framework.urls'))
]
