from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required


@login_required
def landing_view(request):
    context = {
        "username": request.user.contributor.fullname
    }
    return render(request, "main.html", context)
