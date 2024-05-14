from django import template
from ..flags.story import key, StoryFlags

register = template.Library()


@register.inclusion_tag("djelm/program.html", takes_context=True)
def render_story(context):
    return {"key": key, "flags": StoryFlags.parse(context['to_model'])}


@register.inclusion_tag("djelm/include.html")
def include_story():
    # Generates the script tag for the Story.elm program
    return {"djelm_program": "dist/Story.js"}
