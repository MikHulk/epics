from django.contrib.auth.models import User
from rest_framework import serializers

from .models import Contributor, Epic, UserStory


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'email', 'first_name', 'last_name', 'is_active']


class ContributorSerializer(serializers.HyperlinkedModelSerializer):

    class Meta:
        model = Contributor
        fields = ['url', 'id', 'fullname', 'user', 'stories', 'epics']
        read_only_fields = ['id', 'stories', 'epics']

    user = UserSerializer()


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
            'stories']
        read_only_fields = ['id', 'url', 'pub_date', 'owner', 'stories']


class UserStorySerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = UserStory
        fields = ['id', 'pub_date', 'title', 'description', 'epic']
        read_only_fields = ['id', 'pub_date', 'epic']
