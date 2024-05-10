from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.middleware.csrf import get_token
from django.shortcuts import render, redirect
from django.urls import reverse
from django.views.decorators.cache import cache_control

from django.http import HttpResponse

from epics.models import Epic


def with_logout(f):
    def g(*args, context=None, **kwargs):
        logout_url = f"{reverse('rest_framework:logout')}?next=/"
        if context:
            context.setdefault("to_model", {})['logoutUrl'] = logout_url
        else:
            context = { 'to_model': { 'logoutUrl':  logout_url }}
        return f(*args, context=context, **kwargs)
    return g


def with_csrf(f):
    def g(request, *args, context=None, **kwargs):
        csrf_token = get_token(request)
        if context:
            context.setdefault("to_model", {})['csrfToken'] = csrf_token
        else:
            context = {'to_model': { 'csrfToken':  csrf_token }}
        return f(request, *args, context=context, **kwargs)
    return g


@login_required
@cache_control(no_cache=True, must_revalidate=True, no_store=True)
@with_logout
@with_csrf
def epic_view(request, epic_id, *, context):
    url =  f"{reverse('frontend:epic-detail', args=[epic_id])}"
    epic = (
        Epic.objects
        .select_related('owner')
        .prefetch_related('stories')
        .get(pk=epic_id)
    )
    context["to_model"]["epic"] = {
        "title": epic.title,
        "pubDate": epic.pub_date.isoformat(),
        "description": epic.description,
        "ownerFullname": epic.owner.fullname,
        "stories": [
            {
                "title": story.title,
                "description": story.description,
                "status": story.status,
            } for story in epic.stories.all()
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
def landing_view(request,* , context):
    epics = [
        { "title": epic.title,
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
