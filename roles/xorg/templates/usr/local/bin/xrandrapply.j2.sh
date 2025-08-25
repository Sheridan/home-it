#!/bin/bash

{% if xorg.videocards | length > 1 %}
xrandr --setprovideroutputsource 1 0
{% endif %}

{% for monitor_name in xorg_options_init_order_monitors -%}
  {%- set monitor = xorg.monitors[monitor_name] -%}
# {{ monitor_name }}: {{ monitor.vendor }} {{ monitor.model }} -> {{ monitor.mode.width }}x{{ monitor.mode.height }}@{{ monitor.mode.rate }}
{# -#}
{%- endfor %}


{#
    {% for monitor_name in xorg_options_init_order_monitors -%}
      {%- set monitor = xorg.monitors[monitor_name] -%}
xrandr  --output "{{ monitor.connector.out }}" --off
    # -#
    {%- endfor %}
#}
xrandr --verbose --dpi {{ xorg_options_dpi }} \
    {% for monitor_name in xorg_options_init_order_monitors -%}
      {%- set monitor = xorg.monitors[monitor_name] -%}
      --output "{{ monitor.connector.out }}" --mode {{ monitor.mode.width }}x{{ monitor.mode.height }} --rate {{ monitor.mode.rate }} {% if 'base' not in monitor.position %} --{{ monitor.position.where }} "{{ xorg.monitors[monitor.position.from].connector.out }}" {% else %} --primary {% endif %}{% if 'rotate' in monitor %}--rotate {{ monitor.rotate }}{% endif %} \
    {# -#}
    {%- endfor %}
