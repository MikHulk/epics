from django.urls import path

from . import views

app_name = "frontend"

urlpatterns = [
    path("", views.landing_view, name='landing'),
    path("epic/<int:epic_id>", views.epic_view, name='epic-detail'),
    path("new-epic/", views.new_epic, name='new-epic'),
    path("story/<int:story_id>", views.story_view, name='story-detail'),
]
