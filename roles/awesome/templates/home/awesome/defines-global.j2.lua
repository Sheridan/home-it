require("defines")
monitors_count = {{ merged_vars.Xorg.options.init_order.monitors | length }}

font = {
  regular = {
    name = "{{ merged_vars.Xorg.fonts.regular.name }}",
    size = {{ merged_vars.Xorg.fonts.regular.size }}
  },
  small = {
    name = "{{ merged_vars.Xorg.fonts.small.name }}",
    size = {{ merged_vars.Xorg.fonts.small.size }}
  },
  mono = {
    name = "{{ merged_vars.Xorg.fonts.mono.name }}",
    size = {{ merged_vars.Xorg.fonts.mono.size }}
  }
}
