require("defines")
monitors_count = {{ merged_vars.Xorg.options.init_order | length }}

font = {
  regular = {
    name = "{{ merged_vars.X.fonts.regular.name }}",
    size = {{ merged_vars.X.fonts.regular.size }}
  },
  small = {
    name = "{{ merged_vars.X.fonts.small.name }}",
    size = {{ merged_vars.X.fonts.small.size }}
  },
  mono = {
    name = "{{ merged_vars.X.fonts.mono.name }}",
    size = {{ merged_vars.X.fonts.mono.size }}
  }
}
