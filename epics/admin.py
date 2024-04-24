from django.contrib import admin
from .models import Epic, UserStory

admin.site.register(
    [
        Epic,
        UserStory,
    ]
)
