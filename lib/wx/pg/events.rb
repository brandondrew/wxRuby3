# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

# Wx::PG sub package for wxRuby3

require_relative './events/evt_list'

# add event handler missing from XML docs
class Wx::EvtHandler
  # from wxPropertyGridEvent
  self.register_event_type EventType[
     'evt_pg_page_changed', 1,
     Wx::PG::EVT_PG_PAGE_CHANGED,
     Wx::PG::PropertyGridEvent
   ] if Wx::PG.const_defined?(:EVT_PG_PAGE_CHANGED)
end
