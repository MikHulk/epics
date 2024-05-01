from django.shortcuts import render


def landing_view(request):
    print(request.user)
    context = {
        "username": (
            request.user.is_authenticated and
            request.user.contributor.fullname or None
        ),
    }

    return render(request, "main.html", context)
