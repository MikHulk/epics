from django.contrib import admin
from django.urls import path, include, re_path
from django.views.generic import RedirectView

from epics import router as epics
from frontend import views

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", views.landing_view),
    path("epics-api/", include(epics.router.urls)),
    path('api-auth/', include('rest_framework.urls')),
    re_path(r'^favicon\.ico$', RedirectView.as_view(url='/static/favicon.ico')),
]
