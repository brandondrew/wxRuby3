# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

# wxRuby Sample Code.

require 'wx'

require_relative './sample_props'

module PropGridMinimal

  class MyStringProperty < Wx::PG::StringProperty

  end

  class MyBoolProperty < Wx::PG::BoolProperty

  end

  class MyFrame < Wx::Frame

    ID_ACTION = Wx::ID_HIGHEST+1

    def initialize(parent = nil)
      super(parent, Wx::ID_ANY, title: "PropertyGrid Test")

      self.icon = Wx.Icon(:sample, Wx::BITMAP_TYPE_XPM, art_path: File.join(__dir__, '..'))

      menu = Wx::Menu.new
      menu.append(ID_ACTION, "Action");
      self.menu_bar = Wx::MenuBar.new
      self.menu_bar.append(menu, "Action");

      @pg = Wx::PG::PropertyGrid.new(self, Wx::ID_ANY, Wx::DEFAULT_POSITION, [400,400],
                                     Wx::PG::PG_SPLITTER_AUTO_CENTER | Wx::PG::PG_BOLD_MODIFIED)

      @pg.append(MyStringProperty.new("String Property", Wx::PG::PG_LABEL))
      @pg.append(ip = Wx::PG::IntProperty.new("Int Property", Wx::PG::PG_LABEL))
      ip.editor = 'SpinCtrl'
      @pg.append(Wx::PG::BoolProperty.new("Bool Property", Wx::PG::PG_LABEL))
      @pg.append(WxSizeProperty.new("Size Property", Wx::PG::PG_LABEL, self.size))
      @pg.append(WxArrayDoubleProperty.new('Double[] Property', Wx::PG::PG_LABEL, [1.23, 3.14]))
      @pg.append(WxFontDataProperty.new('FontData Property', Wx::PG::PG_LABEL))
      @pg.append(WxDirsProperty.new('Directory list Property', Wx::PG::PG_LABEL))
      @pg.set_property_attribute('Double[] Property', Wx::PG::PG_FLOAT_PRECISION, 4)
      @pg.set_property_help_string('Double[] Property',
                                 'This demonstrates wxArrayDoubleProperty class defined in this sample app. '+
                                 'It is an example of a custom list editor property.')

      size = [400, 600]

      evt_menu ID_ACTION,:on_action

      evt_pg_changed Wx::ID_ANY, :on_property_grid_change
      evt_pg_changing Wx::ID_ANY, :on_property_grid_changing
    end

    def on_action(evt)

    end

    def on_property_grid_change(evt)
      p = evt.property

      if p
        Wx::log_message("OnPropertyGridChange(%s, value=%s)",
                     p.name, p.value_as_string)
      else
        Wx::log_message("OnPropertyGridChange(NULL)")
      end
    end

    def on_property_grid_changing(evt)
      p = evt.property

      Wx::log_message("OnPropertyGridChanging(%s)", p.name)
    end

  end

  def self.display_minimal_frame(parent = nil)
    frame = MyFrame.new(parent)
    frame.show
  end

end unless defined? PropGridMinimal

if (!defined? WxRuby::Sample) || (WxRuby::Sample.loading_sample && WxRuby::Sample.loading_sample != __FILE__)

  module MinimalSample

    include WxRuby::Sample if defined? WxRuby::Sample

    def self.describe
      { file: __FILE__,
        summary: 'Minimal wxRuby PropGrid example.',
        description: 'Minimal wxRuby example displaying frame window with a property grid.' }
    end

    def self.run
      execute(__FILE__)
    end

    if $0 == __FILE__
      Wx::App.run do
        self.app_name = 'Minimal PropertyGrid'
        Wx::Log::set_active_target(Wx::LogStderr.new)
        gc_stress
        PropGridMinimal.display_minimal_frame
        true
      end
    end

  end
end
