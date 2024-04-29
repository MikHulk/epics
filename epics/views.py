from django.contrib.auth.models import User
from rest_framework import permissions, viewsets, status, exceptions
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Contributor, Epic
from .serializers import ContributorSerializer, EpicSerializer


class ContributorViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows managing and performing action for contributor.
    """
    queryset = Contributor.objects.all().order_by('user__username')
    serializer_class = ContributorSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(
        detail=True,
        methods=['post'],
        name="create new epic",
        serializer_class=EpicSerializer,
    )
    def new_epic(self, request, pk=None):
        contributor = self.get_object()
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            if request.user == contributor.user:
                epic = contributor.new_epic(**serializer.validated_data)
                return Response(self.get_serializer(epic).data)
            else:
                raise exceptions.PermissionDenied(
                    detail="you cannot create epics for others")

        else:
            return Response(serializer.errors,
                            status=status.HTTP_400_BAD_REQUEST)


class EpicViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Epics list view.
    """
    queryset = Epic.objects.order_by('-pub_date')
    serializer_class = EpicSerializer
