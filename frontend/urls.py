from django.urls import path

from . import views

app_name = "frontend"

urlpatterns = [
    path("", views.landing_view, name='landing'),
    path("epic/<int:epic_id>", views.epic_view, name='epic-detail'),
]
