# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

# Wx::HTML sub package loader for wxRuby3


require 'wx/core'
require 'wx/prt' if Wx.has_feature?(:USE_PRINTING_ARCHITECTURE)

require 'wxruby_html'

require_relative './html/require'

::Wx.include(WxRubyStyleAccessors)

::Wx.include(::Wx::HTML) if defined?(::WX_GLOBAL_CONSTANTS) && ::WX_GLOBAL_CONSTANTS
::Wx::HTML.include((defined?(::WX_GLOBAL_CONSTANTS) && ::WX_GLOBAL_CONSTANTS) ? WxGlobalConstants : WxEnumConstants)
