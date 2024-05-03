from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.middleware.csrf import get_token
from django.shortcuts import render, redirect


@login_required
def landing_view(request):
    csrf_token = get_token(request)
    context = {
        "user_info": {
            "fullname": request.user.contributor.fullname,
            "firstName": request.user.first_name or None,
            "lastName": request.user.last_name or None,
            "email": request.user.email or None,
            "isStaff": request.user.is_staff,
            "csrfToken": csrf_token,
            "logoutUrl": f"{settings.LOGOUT_URL}/?next=/",
        }
    }
    return render(request, "main.html", context)
