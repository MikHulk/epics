from django.contrib import admin
from django.urls import path, include, re_path
from django.views.generic import RedirectView

from epics import router as epics
import frontend

urlpatterns = [
    re_path(
        r'^favicon\.ico$',
        RedirectView.as_view(
            url='/static/favicon.ico')),
    path("", include("frontend.urls")),
    path("epics-api/", include(epics.router.urls)),
    path("admin/", admin.site.urls),
    path('api-auth/', include('rest_framework.urls')),
]
