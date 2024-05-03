from django import template
from ..flags.landing import key, LandingFlags

register = template.Library()


@register.inclusion_tag("djelm/program.html", takes_context=True)
def render_landing(context):
    return {
        "key": key,
        "flags": LandingFlags.parse(context['user_info'])
    }


@register.inclusion_tag("djelm/include.html")
def include_landing():
    # Generates the script tag for the Landing.elm program
    return {"djelm_program": "dist/Landing.js"}
