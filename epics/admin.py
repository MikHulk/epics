from django.contrib import admin
from .models import Contributor, Epic, UserStory

admin.site.register(
    [
        Epic,
        UserStory,
        Contributor,
    ]
)
