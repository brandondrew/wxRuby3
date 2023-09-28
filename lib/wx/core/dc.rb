# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.
# 
# Some parts are
# Copyright 2004-2007, wxRuby development team
# released under the MIT-like wxRuby2 license

module Wx
  # Class for drawing primitives and bitmaps on various outputs (screen, paper)
  class DC
    # provide Ruby-style convenience methods supporting wxDCxxxChanger-like functionality

    def with_brush(brush)
      begin
        old_brush = self.brush
        self.brush = brush
        yield(self) if block_given?
      ensure
        self.brush = old_brush
      end
    end

    def with_pen(pen)
      begin
        old_pen = self.pen
        self.pen = pen
        yield(self) if block_given?
      ensure
        self.pen = old_pen
      end
    end

    def with_font(font)
      begin
        old_font = self.font
        self.font = font
        yield(self) if block_given?
      ensure
        self.font = old_font
      end
    end

    def with_text_foreground(clr)
      begin
        old = self.get_text_foreground
        self.text_foreground = clr
        yield(self) if block_given?
      ensure
        self.text_foreground = old
      end
    end
    alias :with_text_fg :with_text_foreground

    def with_text_background(clr)
      begin
        old = self.get_text_background
        self.text_background = clr
        yield(self) if block_given?
      ensure
        self.text_background = old
      end
    end
    alias :with_text_bg :with_text_background

    def with_background_mode(mode)
      begin
        old = self.get_background_mode
        self.background_mode = mode
        yield(self) if block_given?
      ensure
        self.background_mode = old
      end
    end
    alias :with_bg_mode :with_background_mode

  end

end
