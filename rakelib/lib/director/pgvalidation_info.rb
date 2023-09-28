# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 wxWidgets interface director
###

module WXRuby3

  class Director

    class PGValidationInfo < Director

      def setup
        super
        spec.items << 'propgrid/propgrid.h'
        spec.gc_as_untracked 'wxPGValidationInfo'
        if Config.instance.wx_version < '3.3.0'
          spec.ignore 'wxPGVFBFlags' # not a constant but a rather a clumsy typedef
        end
      end
    end # class PGValidationInfo

  end # class Director

end # module WXRuby3
