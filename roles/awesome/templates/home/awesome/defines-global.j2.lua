require("defines")
monitors_count = {{ merged_vars.xorg.options.init_order.monitors | length }}

font = {
  regular = {
    name = "{{ merged_vars.xorg.fonts.regular.name }}",
    size = {{ merged_vars.xorg.fonts.regular.size }}
  },
  small = {
    name = "{{ merged_vars.xorg.fonts.small.name }}",
    size = {{ merged_vars.xorg.fonts.small.size }}
  },
  mono = {
    name = "{{ merged_vars.xorg.fonts.mono.name }}",
    size = {{ merged_vars.xorg.fonts.mono.size }}
  }
}
