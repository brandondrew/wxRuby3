# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.
# 
# Some parts are
# Copyright 2004-2007, wxRuby development team
# released under the MIT-like wxRuby2 license

# encoding: UTF-8
# Adapted for wxRuby3
###


# The 'encoding:' comment above tells ruby this script is written in UTF-8
# encoded text (which is actually the default currently).

require 'wx'

$utf8_file = File.join( File.dirname(__FILE__), 'utf8.txt')

class UnicodeDemoTextCtrl < Wx::TextCtrl
  NEWLINE_CORRECTION_FACTOR = 0
  
  DEFAULT_TEXT = "If you have a unicode version of wxruby, you should be able to see a range of characters from different languages displayed, and be able to type multilingual strings in the text area. Note that some scripts may only be displayed if you are using a suitable font; otherwise characters will appear as blank boxes.

" << File.read( $utf8_file )

  def initialize(parent, text = DEFAULT_TEXT)
    super(parent, -1, text, 
          Wx::DEFAULT_POSITION, Wx::DEFAULT_SIZE, Wx::TE_MULTILINE)
  end

  # run through a few useful methods of textctrl and report the results
  # as a string
  def report
    report = ''
    sel = get_string_selection
    report << 'Selected string byte length: ' << sel.bytesize.to_s << "\n"
    report << 'Selected string character length: ' << sel.size.to_s << "\n"
    report << 'Selected string:: ' << sel.inspect << "\n"
    return report
  end
end

# A read-only text ctrl useful for displaying output
class LogTextCtrl < Wx::TextCtrl
  STYLE = Wx::TE_READONLY|Wx::TE_MULTILINE
  def initialize(parent)
    super(parent, -1, '', Wx::DEFAULT_POSITION, Wx::DEFAULT_SIZE, STYLE)
  end
end

class IConvFrame < Wx::Frame

  # The encodings we're going to make importable and exportable in this
  # application - see construct_import_export_menus below
  ENCODINGS = { 'US ASCII' => 'ASCII', 
                'UTF-8' => 'UTF-8',
                'UTF-16' => 'UTF-16',
                'Windows Latin CP1252' => 'CP1252',
                'Latin ISO-8859-1' => 'ISO-8859-1',
                'Japanese SHIFT-JIS' => 'SHIFT-JIS' }

  def initialize(title, pos, size)
    super(nil, -1, title, pos, size)
    panel = Wx::Panel.new(self)
    sizer = Wx::BoxSizer.new(Wx::VERTICAL)

    sys_lang = Wx::Locale.get_system_language_name
    text = Wx::StaticText.new(panel, -1, "System language: #{sys_lang}")
    sizer.add(text, 0, Wx::ALL, 5)

    sys_enc = Wx::Locale.get_system_encoding_name
    text = Wx::StaticText.new(panel, -1, "System default encoding: #{sys_enc}")
    sizer.add(text, 0, Wx::ALL, 5)

    # The text input and display
    @textctrl = UnicodeDemoTextCtrl.new(panel)
    sizer.add(@textctrl, 3, Wx::GROW|Wx::ALL, 2)

    # The button to show what's selected
    button = Wx::Button.new(panel, -1, 'Describe text selection')
    sizer.add(button, 0, Wx::ALL, 2 )
    evt_button(button.get_id) { | e | on_click(e) }

    @log = LogTextCtrl.new(panel)
    sizer.add(@log, 1, Wx::GROW|Wx::ALL, 2)
    sizer.add( Wx::StaticText.new(panel, -1, 'Some controls with unicode'),
               0, Wx::ALL, 2 )
    ctrl_sizer = Wx::BoxSizer.new(Wx::HORIZONTAL)

    test_button = Wx::Button.new(panel, -1, '万')
    ctrl_sizer.add(test_button, 0, Wx::ALL, 2)
    choice = Wx::Choice.new(panel, -1, Wx::DEFAULT_POSITION, 
                            Wx::DEFAULT_SIZE, [])
    File.readlines($utf8_file).each do | line |
      next if line.chomp.empty?
      choice.append(line.chomp)
    end
    choice.set_selection(0)
    ctrl_sizer.add(choice, 0, Wx::ALL, 2)

    sizer.add(ctrl_sizer, 0, Wx::ALL, 2)
    construct_menus
    panel.set_sizer_and_fit( sizer )
  end

  # Prompt the user to specify a file whose contents should be loaded
  # into the text ctrl. The file should be encoded in +encoding+
  def on_import_file(encoding)
    Wx::FileDialog(nil, 'Import file', "", "",
                   "*.*", Wx::FD_OPEN | Wx::FD_FILE_MUST_EXIST) do |fd|
      return unless fd.show_modal == Wx::ID_OK
      File.open(fd.get_path) do |file|
        import_file(file, encoding)
      end
    rescue
      message = "The file %s does not seem to be in %s encoding\n%s" %
        [fd.get_filename, encoding, $!.to_s]
      Wx::MessageDialog(self, message, 'Wrong encoding',
                        Wx::OK | Wx::ICON_EXCLAMATION)
    end
  end

  # Read +io+, which should be text file encoding in +source_encoding+,
  # and display the contents in the textctrl.
  def import_file(io, source_encoding = 'UTF-8')
    case source_encoding
    when /UTF-?8/
      @textctrl.set_value( io.read )
    else
      @textctrl.set_value(io.read.encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "?"))
    end
  end

  # Ask the user for a file path, and then export the content of the
  # textctrl to it in the encoding +encoding+
  def on_export_file(encoding)
    Wx::FileDialog(nil, 'Export file', "", "",
                   "*.*", Wx::FD_SAVE | Wx::FD_OVERWRITE_PROMPT) do |fd|
      return unless fd.show_modal == Wx::ID_OK
      File.open(fd.get_path, 'w') do |file|
        export_file(file, encoding)
      end
    rescue
      message = "The text content containts characters that " <<
        "cannot be encoded using %s.\n%s" % [encoding, $!.to_s]
      Wx::MessageDialog(self, message, 'Invalid encoding',
                        Wx::OK | Wx::ICON_EXCLAMATION)
    end
  end

  # Write the content of the textctrl to the file or io +io+, encoding
  # the text in encoding +target_encoding+
  def export_file(io, target_encoding = 'utf-8')
    case target_encoding
    when /UTF-?8/
      io.write(@textctrl.get_value)
    else
      io.write(@textctrl.get_value.encode(target_encoding, :invalid => :replace, :undef => :replace, :replace => "?"))
    end
  end

  def construct_menus
    menu_bar = Wx::MenuBar.new

    menu_file = Wx::Menu.new
    menu_file.append(Wx::ID_EXIT, "E&xit\tAlt-X", "Quit this program")
    evt_menu(Wx::ID_EXIT) { on_quit }
    menu_bar.append(menu_file, "&File")
    construct_import_export_menus(menu_bar)

    menu_help = Wx::Menu.new
    menu_help.append(Wx::ID_ABOUT, "&About...\tF1", "Show about dialog")
    evt_menu(Wx::ID_ABOUT) { on_about }
    menu_bar.append(menu_help, "&Help")

    set_menu_bar(menu_bar)
  end

  def construct_import_export_menus(menu_bar)
    id_counter = 0
    menu_import = Wx::Menu.new

    ENCODINGS.each do | desc, enc |
      id_counter += 1
      menu_import.append(id_counter, "Import (#{desc})",
                         "Import a file in #{desc} encoding")
      
      evt_menu(id_counter) { on_import_file(enc) }
    end
    menu_bar.append(menu_import, '&Import')

    menu_export = Wx::Menu.new
    ENCODINGS.each do | desc, enc |
      id_counter += 1
      menu_export.append(id_counter, "Export (#{desc})",
                         "Export a file in #{desc} encoding")
      
      evt_menu(id_counter) { on_export_file(enc) }
    end
    menu_bar.append(menu_export, '&Export')
  end

  def on_click(e)
    @log.set_value( @textctrl.report )
  end

  def on_quit
    close(true)
  end

  def on_about
    msg =  sprintf("This is the About dialog of the Unicode sample.\n" \
                    "Welcome to %s", Wx::WXWIDGETS_VERSION)
    Wx::message_box(msg, "About Minimal", Wx::OK|Wx::ICON_INFORMATION, self)
  end
end

module UnicodeSample

  include WxRuby::Sample if defined? WxRuby::Sample

  def self.describe
    { file: __FILE__,
      summary: 'wxRuby Unicode example.',
      description: 'wxRuby example showcasing unicode support.' }
  end

  def self.activate
    frame = IConvFrame.new("Unicode demonstration - ",
                           Wx::Point.new(50, 50),
                           Wx::Size.new(450, 600) )

    frame.show(true)
    frame
  end

  if $0 == __FILE__
    Wx::App.run { UnicodeSample.activate }
  end

end
