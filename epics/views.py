from django.contrib.auth.models import User
from rest_framework import permissions, viewsets, status, exceptions, serializers
from rest_framework.decorators import action
from rest_framework.response import Response

from .exceptions import BadCommand, APIBadCommand
from .models import Contributor, Epic, UserStory
from .serializers import ContributorSerializer, EpicSerializer, UserStorySerializer


class ContributorViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows listing and performing action for contributor.
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
    API endpoint that allows listing and performing action on epics.
    """
    queryset = Epic.objects.order_by('-pub_date')
    serializer_class = EpicSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(
        detail=True,
        methods=['post'],
        name="create new story under this epic",
        serializer_class=UserStorySerializer,
    )
    def new_story(self, request, pk=None):
        epic = self.get_object()
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            if epic.owner.user == request.user:
                us = epic.owner.new_story(epic, **serializer.validated_data)
                return Response(self.get_serializer(us).data)
            else:
                raise exceptions.PermissionDenied(
                    detail="not your epic"
                )
        else:
            return Response(serializer.errors,
                            status=status.HTTP_400_BAD_REQUEST)


class UserStoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows listing and performing action on user stories.
    """
    queryset = UserStory.objects.order_by('-pub_date')
    serializer_class = UserStorySerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(
        detail=True,
        methods=['put'],
        name="take this story",
        serializer_class=serializers.Serializer,
    )
    def take(self, request, pk=None):
        story = self.get_object()
        contributor = request.user.contributor
        try:
            contributor.take(story)
            return Response(
                UserStorySerializer(
                    instance=story,
                    context={'request': request}
                ).data
            )
        except BadCommand as e:
            raise APIBadCommand(str(e))

    @action(
        detail=True,
        methods=['put'],
        name="suspend this story",
        serializer_class=serializers.Serializer,
    )
    def suspend(self, request, pk=None):
        story = self.get_object()
        contributor = request.user.contributor
        try:
            contributor.suspend(story)
            return Response(
                UserStorySerializer(
                    instance=story,
                    context={'request': request}
                ).data
            )
        except BadCommand as e:
            raise APIBadCommand(str(e))

    @action(
        detail=True,
        methods=['put'],
        name="resume this story from suspended",
        serializer_class=serializers.Serializer,
    )
    def resume(self, request, pk=None):
        story = self.get_object()
        contributor = request.user.contributor
        try:
            contributor.resume(story)
            return Response(
                UserStorySerializer(
                    instance=story,
                    context={'request': request}
                ).data
            )
        except BadCommand as e:
            raise APIBadCommand(str(e))

    @action(
        detail=True,
        methods=['put'],
        name="cancel this story (/!\\ this is final)",
        serializer_class=serializers.Serializer,
    )
    def cancel(self, request, pk=None):
        story = self.get_object()
        contributor = request.user.contributor
        try:
            contributor.cancel(story)
            return Response(
                UserStorySerializer(
                    instance=story,
                    context={'request': request}
                ).data
            )
        except BadCommand as e:
            raise APIBadCommand(str(e))

    @action(
        detail=True,
        methods=['put'],
        name="validate this story",
        serializer_class=serializers.Serializer,
    )
    def validate(self, request, pk=None):
        story = self.get_object()
        contributor = request.user.contributor
        try:
            contributor.validate(story)
            return Response(
                UserStorySerializer(
                    instance=story,
                    context={'request': request}
                ).data
            )
        except BadCommand as e:
            raise APIBadCommand(str(e))
