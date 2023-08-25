# Advanced User Interface Notebook - draggable panes etc
class Wx::AUI::AuiFloatingFrame

  # Before wxWidgets 3.3 the AUI manager of this control would prevent
  # WindowDestroyEvent propagation so we 'patch' in a std event handler
  # that designates the event skipped.
  if Wx::WXWIDGETS_VERSION < '3.3'
    wx_initialize = instance_method :initialize
    define_method :initialize do |*args|
      wx_initialize.bind(self).call(*args)
      evt_window_destroy { |evt| evt.skip }
    end
  end

end
