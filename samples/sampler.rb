# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 sampler application
###

require 'rbconfig'
require 'fileutils'
require 'wx'

require_relative 'sampler/ext'
require_relative 'sampler/sample'
require_relative 'sampler/editor'

module WxRuby

  module ID
    TB_RESTORE = Wx::ID_HIGHEST + 2000
    TB_CLOSE = Wx::ID_HIGHEST + 2001
    TB_CHANGE = Wx::ID_HIGHEST + 2002
    TB_REMOVE = Wx::ID_HIGHEST + 2003

    CATEGORY_ID_MIN = Wx::ID_HIGHEST+4000

    SAMPLE_ID_MIN = Wx::ID_HIGHEST+6000
    RUN = 1
    EDIT = 2

    def self.index_to_sample_id(sample_ix)
      SAMPLE_ID_MIN+(sample_ix*10)
    end

    def self.id_to_sample_index(sample_id)
      (sample_id - SAMPLE_ID_MIN)/10
    end

    def self.index_to_run_id(sample_ix)
      SAMPLE_ID_MIN+(sample_ix*10)+RUN
    end

    def self.index_to_edit_id(sample_ix)
      SAMPLE_ID_MIN+(sample_ix*10)+EDIT
    end

    def self.id_is_run_button?(id)
      ((id - SAMPLE_ID_MIN) % 10) == RUN
    end

    def self.id_is_edit_button?(id)
      ((id - SAMPLE_ID_MIN) % 10) == EDIT
    end

    def self.run_id_to_sample_index(run_id)
      (run_id - (SAMPLE_ID_MIN + RUN))/10
    end

    def self.edit_id_to_sample_index(run_id)
      (run_id - (SAMPLE_ID_MIN + EDIT))/10
    end
  end

  class SampleTaskBarIcon < Wx::TaskBarIcon

    def initialize(frame)
      super()

      @frame = frame

      # starting image
      icon = make_icon('wxruby-128x128.png')
      set_icon(icon, 'wxRuby Sampler')

      # events
      evt_taskbar_left_dclick { |evt| on_taskbar_activate(evt) }

      evt_menu(ID::TB_RESTORE) { |evt| on_taskbar_activate(evt) }
      evt_menu(ID::TB_CLOSE) { @frame.close }
    end

    def create_popup_menu
      # Called by the base class when it needs to popup the menu
      #  (the default evt_right_down event).  Create and return
      #  the menu to display.
      menu = Wx::Menu.new
      menu.append(ID::TB_RESTORE, "Restore wxRuby Sampler")
      menu.append(ID::TB_CLOSE, "Close wxRuby Sampler")
      return menu
    end

    def make_icon(imgname)
      # Different platforms have different requirements for the
      #  taskbar icon size
      filename = File.join(__dir__, 'art', imgname)
      img = Wx::Image.new(filename)
      if Wx::PLATFORM == "WXMSW"
        img = img.scale(16, 16)
      elsif Wx::PLATFORM == "WXGTK"
        img = img.scale(22, 22)
      end
      # WXMAC can be any size up to 128x128, so don't scale
      icon = Wx::Icon.new
      icon.copy_from_bitmap(Wx::Bitmap.new(img))
      return icon
    end

    def on_taskbar_activate(evt)
      @frame.iconize(false)
      @frame.show(true)
      @frame.raise_window
    end
  end

  class SamplerFrame < Wx::Frame

    def initialize(title)
      frameSize = Wx::Size.new([850, (Wx::SystemSettings.get_metric(Wx::SYS_SCREEN_X) / 4)].max,
                               (Wx::SystemSettings.get_metric(Wx::SYS_SCREEN_Y) / 2))
      framePos = Wx::Point.new(Wx::SystemSettings.get_metric(Wx::SYS_SCREEN_X) / 20,
                               Wx::SystemSettings.get_metric(Wx::SYS_SCREEN_Y) / 4)
      # The main application frame has no parent (nil)
      super(nil, :title => title, :size => frameSize, pos: framePos)

      @closing = false

      # Give the frame an icon. PNG is a good choice of format for
      # cross-platform images. Note that OS X doesn't have "Frame" icons.
      icon_file = File.join(__dir__, 'art', "wxruby.png")
      self.icon = Wx::Icon.new(icon_file)

      @tbicon = SampleTaskBarIcon.new(self)

      @main_panel = Wx::Panel.new(self, Wx::ID_ANY)
      main_sizer = Wx::VBoxSizer.new
      @scroll_panel = Wx::ScrolledWindow.new(@main_panel, Wx::ID_ANY, :size => [ 600, 400 ], style: Wx::VSCROLL)
      @scroll_panel.set_scroll_rate(15, 15)
      scroll_sizer = Wx::VBoxSizer.new
      @category_panes = []
      @category_thumbnails = []
      @sample_thumbnails = []
      @sample_panes = []
      @scroll_panel.set_sizer(scroll_sizer)
      @scroll_panel.hide

      @startup_panel = Wx::Panel.new(@main_panel)
      @startup_panel.background_colour = Wx::LIGHT_GREY
      startup_sizer = Wx::VBoxSizer.new
      startup_sizer.add(Wx::StaticBitmap.new(@startup_panel,Wx::ID_ANY, Wx::Bitmap.new(icon_file)),
                        0, Wx::TOP|Wx::ALIGN_CENTER, 100)
      txt = Wx::StaticText.new(@startup_panel, Wx::ID_ANY, 'wxRuby Sampler Starting')
      txt.own_font = Wx::Font.new(20, Wx::FontFamily::FONTFAMILY_ROMAN, Wx::FONTSTYLE_NORMAL, Wx::FONTWEIGHT_BOLD)
      txt.font.set_weight(Wx::FontWeight::FONTWEIGHT_BOLD)
      startup_sizer.add(txt,  0, Wx::ALL|Wx::ALIGN_CENTER, 30)
      txt = Wx::StaticText.new(@startup_panel, Wx::ID_ANY, 'Loading samples, please wait...')
      startup_sizer.add(txt,  0, Wx::ALL|Wx::ALIGN_CENTER, 10)
      @gauge = Wx::Gauge.new(@startup_panel, Wx::ID_ANY, Sample.max_collection)
      startup_sizer.add(@gauge, 0, Wx::ALIGN_CENTER|Wx::ALL, 5)
      @startup_panel.sizer = startup_sizer
      main_sizer.add(@startup_panel, 1, Wx::EXPAND, 0)

      # main_sizer.add(@scroll_panel, 1, Wx::GROW|Wx::ALL, 4)
      @main_panel.sizer = main_sizer

      @expanded_sample = nil
      @expanded_category = nil
      @running_sample = nil
      @sample_editor = nil

      menu_bar = Wx::MenuBar.new
      unless Wx::PLATFORM == 'WXOSX'
        # The "file" menu
        menu_file = Wx::Menu.new
        # Don't add a File menu with only Exit item on OSX as on OSX
        # the Exit item there will be hidden and a standard one added to
        # the Apple Application menu leaving an empty File menu
        menu_file.append(Wx::ID_EXIT, "E&xit\tAlt-X", "Quit wxRuby Sampler")
        menu_bar.append(menu_file, "&File")
      end

      # The "help" menu
      menu_help = Wx::Menu.new
      menu_help.append(Wx::ID_ABOUT, "&About...\tF1", "Show about dialog")
      menu_bar.append(menu_help, "&Help")

      # Assign the menubar to this frame
      self.menu_bar = menu_bar

      # Create a status bar at the bottom of the frame
      create_status_bar(2)
      self.status_text = "Welcome to wxRuby Sampler!"

      # Set it up to handle menu events using the relevant methods.
      evt_close :on_close
      evt_iconize :on_iconize

      evt_menu Wx::ID_EXIT, :on_quit
      evt_menu Wx::ID_ABOUT, :on_about

      evt_collapsiblepane_changed Wx::ID_ANY, :on_sample_pane_changed

      evt_button Wx::ID_ANY, :on_sample_button

      @main_panel.layout
    end

    attr_reader :closing
    attr_reader :running_sample
    attr_accessor :sample_editor

    def load_samples
      read_count = 0
      WxRuby::Sample.collect_samples do |count|
        read_count = count
        @gauge.value = read_count
        Wx.get_app.yield
        return false if @closing
        sleep 0.05
      end

      WxRuby::Sample.categories.size.times do |ix|
        add_category(read_count+1, ix)
        Wx.get_app.yield
        return false if @closing
      end
      show_samples
      true
    end

    def add_category(offset, cat)
      @gauge.value = offset + cat
      @main_panel.update
      cat_id = Sample.categories.keys[cat]
      create_category_pane(@scroll_panel.sizer, cat_id, cat)
    end
    private :add_category

    def show_samples
      @main_panel.sizer.remove(0)
      @startup_panel.destroy
      @startup_panel = nil
      @gauge = nil
      @scroll_panel.show
      @main_panel.sizer.add(@scroll_panel, 1, Wx::GROW|Wx::ALL, 4)
      @main_panel.layout
    end
    private :show_samples

    def create_category_pane(scroll_sizer, cat, cat_ix)
      category_panel = Wx::Panel.new(@scroll_panel, Wx::ID_ANY, style: Wx::RAISED_BORDER)
      @category_panes << (category_pane = Wx::CollapsiblePane.new(category_panel, ID::CATEGORY_ID_MIN+cat_ix, "#{cat} samples"))
      category_pane_win = category_pane.pane
      category_pane_sizer = Wx::VBoxSizer.new

      Sample.category_samples(cat).each do |sample_ix|
        sample = Sample.samples[sample_ix]
        sample_desc = sample.description

        sample_panel = Wx::Panel.new(category_pane_win, Wx::ID_ANY, style: Wx::SUNKEN_BORDER)
        @sample_panes << (sample_pane = Wx::CollapsiblePane.new(sample_panel, ID.index_to_sample_id(sample_ix), sample_desc.summary))
        pane = sample_pane.pane

        sample_pane_sizer = Wx::HBoxSizer.new
        sample_pane_sizer.add(Wx::StaticBitmap.new(pane, Wx::ID_ANY, sample_desc.image), 0, Wx::ALIGN_TOP)
        sample_pane_ctrl_sizer = Wx::VBoxSizer.new
        sample_buttons_sizer = Wx::HBoxSizer.new
        sample_buttons_sizer.add(Wx::Button.new(pane, ID.index_to_run_id(sample_ix), 'Run sample'), 0, Wx::ALL, 2)
        sample_buttons_sizer.add(Wx::Button.new(pane, ID.index_to_edit_id(sample_ix), 'Inspect sample'), 0, Wx::ALL, 2)
        sample_pane_ctrl_sizer.add(sample_buttons_sizer, 0, Wx::ALL, 0)
        sample_pane_ctrl_sizer.add(Wx::StaticLine.new(pane, Wx::ID_ANY, size: [2, 2], style: Wx::LI_HORIZONTAL|Wx::RAISED_BORDER), 0, Wx::EXPAND|Wx::ALL, 2)
        desc = Wx::TextCtrl.new(pane, Wx::ID_ANY, sample_desc.description, style: Wx::TE_MULTILINE|Wx::TE_READONLY|Wx::BORDER_NONE)
        desc.background_colour = sample_panel.background_colour
        sample_pane_ctrl_sizer.add(desc, 1, Wx::EXPAND|Wx::ALL, 2)
        sample_pane_sizer.add(sample_pane_ctrl_sizer, 1, Wx::EXPAND, 2)
        pane.sizer = sample_pane_sizer
        sample_pane_sizer.set_size_hints(pane)

        sample_sizer = Wx::HBoxSizer.new
        sample_sizer.add(sample_pane, 1, Wx::EXPAND|Wx::ALL, 4)
        @sample_thumbnails << Wx::StaticBitmap.new(sample_panel, Wx::ID_ANY, sample_desc.thumbnail)
        sample_sizer.add(@sample_thumbnails.last, 0, Wx::ALIGN_TOP)
        sample_panel.sizer = sample_sizer
        category_pane_sizer.add(sample_panel, 0, Wx::EXPAND|Wx::ALL, 3)
      end

      category_pane_win.sizer = category_pane_sizer
      category_pane_sizer.set_size_hints(category_pane_win)

      category_sizer = Wx::HBoxSizer.new
      @category_thumbnails << Wx::StaticBitmap.new(category_panel, Wx::ID_ANY, Wx::ArtProvider::get_bitmap(Wx::ART_FOLDER, Wx::ART_OTHER, [32,32]))
      category_sizer.add(category_pane, 1, Wx::EXPAND|Wx::ALL, 2)
      category_sizer.add(@category_thumbnails.last, 0, Wx::ALIGN_TOP)
      category_panel.sizer = category_sizer

      scroll_sizer.add(category_panel, 0, Wx::EXPAND|Wx::ALL, 3)
    end
    private :create_category_pane

    def run_sample(sample)
      @running_sample.close if @running_sample
      @running_sample = sample
      @running_sample.run
    end

    def on_sample_button(_evt)
      if ID.id_is_run_button?(_evt.id)
        run_sample(Sample.samples[ID.run_id_to_sample_index(_evt.id)])
      elsif ID.id_is_edit_button?(_evt.id)
        @sample_editor.destroy if @sample_editor
        sample_ix = ID.edit_id_to_sample_index(_evt.id)
        sample = Sample.samples[sample_ix]
        @sample_editor = SampleEditor.new(self, sample)
        @sample_editor.show
      end
    end

    def on_sample_pane_changed(_evt)
      if _evt.id < ID::SAMPLE_ID_MIN
        cat_ix = _evt.id - ID::CATEGORY_ID_MIN
        if @expanded_sample
          @sample_thumbnails[@expanded_sample].show
          @sample_panes[@expanded_sample].collapse
          @expanded_sample = nil
        end
        if _evt.collapsed
          @category_thumbnails[cat_ix].show
          @expanded_category = nil
        else
          @category_thumbnails[cat_ix].hide
          if @expanded_category
            @category_thumbnails[@expanded_category].show
            @category_panes[@expanded_category].collapse
          end
          @expanded_category = cat_ix
        end
      else
        sample_ix = ID.id_to_sample_index(_evt.id)
        if _evt.collapsed
          @sample_thumbnails[sample_ix].show
          @expanded_sample = nil
        else
          @sample_thumbnails[sample_ix].hide
          if @expanded_sample
            @sample_thumbnails[@expanded_sample].show
            @sample_panes[@expanded_sample].collapse
          end
          @expanded_sample = sample_ix
        end
      end
      @main_panel.layout
    end

    def on_close(_evt)
      @closing = true
      @running_sample.close if @running_sample
      @sample_editor.destroy if @sample_editor
      @tbicon.remove_icon
      @tbicon.destroy
      destroy
    end

    def on_iconize(_evt)
      hide
      _evt.skip
    end

    # End the application; it should finish automatically when the last
    # window is closed.
    def on_quit(_evt)
      close
    end

    # show an 'About' dialog - WxRuby's about_box function will show a
    # platform-native 'About' dialog, but you could also use an ordinary
    # Wx::MessageDialog here.
    def on_about
      Wx::about_box(:name => 'wxRuby Sampler',
                    :version     => Wx::WXRUBY_VERSION,
                    :description => "wxRuby Samples inspection application.",
                    :developers  => ['Martin Corino'] )
    end
  end
end

Wx::App.run do
  self.set_app_name('wxRuby Sampler')

  @frame = nil

  evt_window_destroy do |evt|
    unless @frame.nil? || @frame == evt.window
      if evt.window == @frame.sample_editor
        @frame.sample_editor = nil
      else
        @frame.running_sample.close_window(evt.window) if @frame.running_sample
      end
    end
  end

  @frame = WxRuby::SamplerFrame.new('wxRuby Sampler Application')
  @frame.show

  @frame.load_samples
end
