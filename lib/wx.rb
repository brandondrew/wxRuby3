# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

# Wx all-in-one loader for wxRuby3

WX_GLOBAL_CONSTANTS=true unless defined? WX_GLOBAL_CONSTANTS

require 'wx/core'
require 'wx/prt' if Wx.has_feature?(:USE_PRINTING_ARCHITECTURE)
require 'wx/rtc' if Wx.has_feature?(:USE_RICHTEXT)
require 'wx/stc' if Wx.has_feature?(:USE_STC)
require 'wx/grid' if Wx.has_feature?(:USE_GRID)
require 'wx/html' if Wx.has_feature?(:USE_HTML)
require 'wx/aui' if Wx.has_feature?(:USE_AUI)
require 'wx/pg' if Wx.has_feature?(:USE_PROPGRID)
require 'wx/rbn' if Wx.has_feature?(:USE_RIBBON)
