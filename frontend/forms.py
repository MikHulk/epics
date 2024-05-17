from django import forms

from epics.models import Epic, UserStory


EpicForm = forms.modelform_factory(Epic, fields=["title", "description"])
UserStoryForm = forms.modelform_factory(
    UserStory, fields=["title", "description"])
