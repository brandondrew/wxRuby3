# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 wxWidgets interface director
###

require_relative './window'

module WXRuby3

  class Director

    class CollapsiblePane < Window

      def setup
        super
        spec.suppress_warning(473, 'wxCollapsiblePane::GetPane')
      end
    end # class CollapsiblePane

  end # class Director

end # module WXRuby3
