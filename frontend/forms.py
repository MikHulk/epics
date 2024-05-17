from django import forms

from epics.models import Epic


EpicForm = forms.modelform_factory(Epic, fields=["title", "description"])
