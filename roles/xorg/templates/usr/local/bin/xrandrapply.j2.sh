#!/bin/bash

{% if merged_vars.Xorg.videocards | length > 1 %}
xrandr --setprovideroutputsource 1 0
{% endif %}

{% for monitor_name in merged_vars.Xorg.options.init_order.monitors -%}
  {%- set monitor = merged_vars.Xorg.monitors[monitor_name] -%}
# {{ monitor_name }}: {{ monitor.vendor }} {{ monitor.model }} -> {{ monitor.mode.width }}x{{ monitor.mode.height }}@{{ monitor.mode.rate }}
{# -#}
{%- endfor %}

{#
xrandr \
    {% for monitor_name in merged_vars.Xorg.options.init_order.monitors -%}
      {%- set monitor = merged_vars.Xorg.monitors[monitor_name] -%}
    --output "{{ monitor.connector.out }}" --off \
    # -#
    {%- endfor %}
#}

xrandr --verbose \
    --dpi {{ merged_vars.Xorg.options.dpi }} \
    {% for monitor_name in merged_vars.Xorg.options.init_order.monitors -%}
      {%- set monitor = merged_vars.Xorg.monitors[monitor_name] -%}
    --output "{{ monitor.connector.out }}" --mode {{ monitor.mode.width }}x{{ monitor.mode.height }} --rate {{ monitor.mode.rate }} {% if 'base' not in monitor.position %} --{{ monitor.position.where }} "{{ merged_vars.Xorg.monitors[monitor.position.from].connector.out }}" {% else %} --primary {% endif %}{% if 'rotate' in monitor %}--rotate {{ monitor.rotate }}{% endif %} \
    {# -#}
    {%- endfor %}
