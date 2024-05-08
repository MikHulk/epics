from django import template
from ..flags.epic import key, EpicFlags

register = template.Library()


@register.inclusion_tag("djelm/program.html", takes_context=True)
def render_epic(context):
    return {"key": key, "flags": EpicFlags.parse(context['model'])}


@register.inclusion_tag("djelm/include.html")
def include_epic():
    # Generates the script tag for the Epic.elm program
    return {"djelm_program": "dist/Epic.js"}
