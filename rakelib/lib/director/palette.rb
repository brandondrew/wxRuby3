# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 wxWidgets interface director
###

module WXRuby3

  class Director

    class Palette < Director

      def setup
        super
        spec.disable_proxies
        spec.gc_as_untracked 'wxPalette'
        if Config.instance.wx_port == :wxQT
          # mismatched implementation which does nothing anyway
          spec.ignore 'wxPalette::wxPalette(int, const unsigned char *, const unsigned char *, const unsigned char *)'
          spec.ignore 'wxPalette::Create(int, const unsigned char *, const unsigned char *, const unsigned char *)'
        end
      end
    end # class Palette

  end # class Director

end # module WXRuby3
