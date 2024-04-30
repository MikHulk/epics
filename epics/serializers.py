from django.contrib.auth.models import User
from rest_framework import serializers

from .models import Contributor, Epic, UserStory


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'email', 'first_name', 'last_name', 'is_active']


class LightContributorSerializer(serializers.HyperlinkedModelSerializer):

    class Meta:
        model = Contributor
        fields = ['url', 'id', 'fullname', 'user']

    user = UserSerializer()


class StatsSerializer(serializers.Serializer):
    created = serializers.IntegerField()
    in_progress = serializers.IntegerField()
    suspended = serializers.IntegerField()
    finished = serializers.IntegerField()
    total = serializers.IntegerField()


class EpicSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Epic
        fields = [
            'id',
            'url',
            'pub_date',
            'title',
            'description',
            'owner',
            'stories',
            'stats',
        ]
        read_only_fields = ['pub_date', 'stories']
    owner = LightContributorSerializer(read_only=True)
    stats = StatsSerializer()


class UserStorySerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = UserStory
        fields = [
            'id',
            'url',
            'pub_date',
            'title',
            'description',
            'epic',
            'assigned_to',
            'status',
        ]
        read_only_fields = [
            'id',
            'url',
            'pub_date',
            'epic',
            'status',
        ]

    assigned_to = LightContributorSerializer(read_only=True)


class ContributorSerializer(serializers.HyperlinkedModelSerializer):

    class Meta:
        model = Contributor
        fields = [
            'url',
            'id',
            'fullname',
            'user',
            'epics',
            'stories',
            'stories_in_progress',
            'stories_suspended',
        ]
        read_only_fields = ['id', 'epics', 'stories']

    user = UserSerializer()
    stories_in_progress = UserStorySerializer(many=True)
    stories_suspended = UserStorySerializer(many=True)
