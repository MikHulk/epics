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
        fields = ['url', 'id', 'fullname', 'user']

    user = UserSerializer()

    def create(self, validated_data):
        user_data = validated_data.pop('user')
        user = User.objects.create(**user_data)
        return Contributor.objects.create(user=user)


class EpicSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Epic
        fields = ['id', 'url', 'pub_date', 'title', 'description', 'owner']
        read_only_fields = ['id', 'url', 'pub_date', 'owner']


class UserStorySerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = UserStory
        fields = ['id', 'pub_date', 'title', 'description', 'epic']
        read_only_fields = ['id', 'pub_date', 'epic']
