require("defines")
monitors_count = {{ xorg_options_init_order_monitors | length }}

font = {
  regular = {
    name = "{{ xorg_fonts_regular_name }}",
    size = {{ xorg_fonts_regular_size }}
  },
  small = {
    name = "{{ xorg_fonts_small_name }}",
    size = {{ xorg_fonts_small_size }}
  },
  mono = {
    name = "{{ xorg_fonts_mono_name }}",
    size = {{ xorg_fonts_mono_size }}
  }
}
