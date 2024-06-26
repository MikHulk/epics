# Generated by Django 5.0.4 on 2024-04-26 20:04

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("epics", "0002_add_contributors"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AlterField(
            model_name="contributor",
            name="user",
            field=models.OneToOneField(
                on_delete=django.db.models.deletion.PROTECT, to=settings.AUTH_USER_MODEL
            ),
        ),
        migrations.AlterField(
            model_name="epic",
            name="owner",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.PROTECT,
                related_name="epics",
                related_query_name="epic",
                to="epics.contributor",
            ),
        ),
        migrations.AddField(
            model_name="userstory",
            name="assigned_to",
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="stories",
                related_query_name="story",
                to="epics.contributor",
            ),
        ),
    ]
