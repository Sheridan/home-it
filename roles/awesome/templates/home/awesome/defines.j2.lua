monitors_count = {{ merged_vars.Xorg.monitors | length }}

{% if inventory_hostname == 'spc' %}
screen_layout = { left=3, center=1, right=2, top=4 }
{% endif %}

{% if inventory_hostname == 'eee-linux' %}
screen_layout = { left=1, center=1, right=1, top=1 }
{% endif %}
