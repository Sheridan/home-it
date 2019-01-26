#!/bin/bash

{% if merged_vars.Xorg.videocards | length > 1 %}
xrandr --setprovideroutputsource 1 0
{% endif %}

xrandr \
    {% for monitor_name in merged_vars.Xorg.monitors -%}
      {%- set monitor = merged_vars.Xorg.monitors[monitor_name] -%}
    --output "{{ monitor.video_out }}" --off \
    {# -#}
    {%- endfor -%}
    {% for monitor_name in merged_vars.Xorg.monitors -%}
      {%- set monitor = merged_vars.Xorg.monitors[monitor_name] -%}
    --output "{{ monitor.video_out }}" --mode {{ monitor.mode.width }}x{{ monitor.mode.height }} --rate {{ monitor.mode.rate }} {% if 'base' not in monitor.position %} --{{ monitor.position.where }} "{{ merged_vars.Xorg.monitors[monitor.position.from].video_out }}" {% endif -%} \
    {# -#}
    {%- endfor -%}
