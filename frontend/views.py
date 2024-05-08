from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.middleware.csrf import get_token
from django.shortcuts import render, redirect
from django.urls import reverse
from django.views.decorators.cache import cache_control

from django.http import HttpResponse

from epics.models import Epic


@login_required
@cache_control(no_cache=True, must_revalidate=True, no_store=True)
def epic_view(request, epic_id):
    url =  f"{reverse('frontend:epic-detail', args=[epic_id])}"
    epic = (
        Epic.objects
        .select_related('owner')
        .prefetch_related('stories')
        .get(pk=epic_id)
    )
    return render(
        request,
        "epic.html",
        {
            "model": {
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
        }
            
    )


@login_required
@cache_control(no_cache=True, must_revalidate=True, no_store=True)
def landing_view(request):
    csrf_token = get_token(request)
    epics = [
        { "title": epic.title,
          "pubDate": epic.pub_date.isoformat(),
          "description": epic.description,
          "ownerFullname": epic.owner.fullname,
          "owner": epic.owner.user.username,
          "url": reverse('frontend:epic-detail', args=[epic.pk]),
         } for epic in Epic.objects.select_related("owner").select_related("owner__user")
    ]
    context = {
        "model": {
            "userInfo": {
                "fullname": request.user.contributor.fullname,
                "name": request.user.username,
                "firstName": request.user.first_name or None,
                "lastName": request.user.last_name or None,
                "email": request.user.email or None,
                "isStaff": request.user.is_staff,
            },
            "csrfToken": csrf_token,
            "logoutUrl": f"{reverse('rest_framework:logout')}?next=/",
            "epics": epics,
        }
    }
    return render(request, "main.html", context)
