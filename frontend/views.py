from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.http import Http404
from django.middleware.csrf import get_token
from django.shortcuts import render, redirect
from django.urls import reverse
from django.views.decorators.cache import cache_control

from django.http import HttpResponse

from epics.models import Epic, UserStory


def with_logout(f):
    def g(*args, context=None, **kwargs):
        logout_url = f"{reverse('rest_framework:logout')}?next=/"
        if context:
            context.setdefault("to_model", {})['logoutUrl'] = logout_url
        else:
            context = {'to_model': {'logoutUrl': logout_url}}
        return f(*args, context=context, **kwargs)
    return g


def with_csrf(f):
    def g(request, *args, context=None, **kwargs):
        csrf_token = get_token(request)
        if context:
            context.setdefault("to_model", {})['csrfToken'] = csrf_token
        else:
            context = {'to_model': {'csrfToken': csrf_token}}
        return f(request, *args, context=context, **kwargs)
    return g


def with_username(f):
    def g(request, *args, context=None, **kwargs):
        username = request.user.username
        if context:
            context.setdefault("to_model", {})['username'] = username
        else:
            context = {'to_model': {'username': username}}
        return f(request, *args, context=context, **kwargs)
    return g


@login_required
@cache_control(no_cache=True, must_revalidate=True, no_store=True)
@with_logout
@with_csrf
@with_username
def story_view(request, story_id, *, context):
    context['story_id'] = story_id
    try:
        story = (
            UserStory.objects
            .select_related('epic')
            .select_related('epic__owner')
            .select_related('epic__owner__user')
            .get(pk=story_id)
        )
    except userStory.DoesNotExist:
        raise Http404("Story does not exist")
    context['to_model']['story'] = {
        "id": story.pk,
        "pubDate": story.pub_date.isoformat(),
        "title": story.title,
        "description": story.description,
        "status": story.status,
        "assignedTo": story.assigned_to and story.assigned_to.user.username or None,
        "assignedToFullname": story.assigned_to and story.assigned_to.fullname or None
    }
    return render(
        request,
        "story.html",
        context=context,
    )


@login_required
@cache_control(no_cache=True, must_revalidate=True, no_store=True)
@with_logout
@with_csrf
@with_username
def epic_view(request, epic_id, *, context):
    url = f"{reverse('frontend:epic-detail', args=[epic_id])}"
    try:
        epic = (
            Epic.objects
            .select_related('owner')
            .select_related('owner__user')
            .prefetch_related('stories')
            .get(pk=epic_id)
        )
    except Epic.DoesNotExist:
        raise Http404("Epic does not exist")
    context["epic_id"] = epic_id
    context["to_model"]["epic"] = {
        "title": epic.title,
        "pubDate": epic.pub_date.isoformat(),
        "description": epic.description,
        "ownerFullname": epic.owner.fullname,
        "owner": epic.owner.user.username,
        "stories": [
            {
                "id": story.pk,
                "pubDate": story.pub_date.isoformat(),
                "title": story.title,
                "description": story.description,
                "status": story.status,
                "assignedTo": story.assigned_to and story.assigned_to.user.username or None,
                "assignedToFullname": story.assigned_to and story.assigned_to.fullname or None
            } for story in epic.stories.order_by('-pub_date').all()
        ]
    }
    return render(
        request,
        "epic.html",
        context=context,
    )


@login_required
@cache_control(no_cache=True, must_revalidate=True, no_store=True)
@with_logout
@with_csrf
def landing_view(request, *, context):
    epics = [
        {"title": epic.title,
         "pubDate": epic.pub_date.isoformat(),
         "description": epic.description,
         "ownerFullname": epic.owner.fullname,
         "owner": epic.owner.user.username,
         "url": reverse('frontend:epic-detail', args=[epic.pk]),
         } for epic in Epic.objects.select_related("owner").select_related("owner__user")
    ]
    context["to_model"]["userInfo"] = {
        "fullname": request.user.contributor.fullname,
        "name": request.user.username,
        "firstName": request.user.first_name or None,
        "lastName": request.user.last_name or None,
        "email": request.user.email or None,
        "isStaff": request.user.is_staff,
    }
    context["to_model"]["epics"] = epics
    return render(request, "main.html", context)
