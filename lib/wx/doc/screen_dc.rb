# :stopdoc:
# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.
# :startdoc:


module Wx

  class ScreenDC < Wx::DC

    # Executes the given block providing a temporary (screen) dc as
    # it's single argument.
    # @yieldparam [Wx::ScreenDC] dc the ScreenDC instance to paint on
    # @return [Object] result of the block
    def self.draw_on; end

  end

end
