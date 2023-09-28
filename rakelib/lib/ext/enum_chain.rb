# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 extensions for Enumerator::Chain
###

unless ::Enumerator.const_defined?(:Chain)

class ::Enumerator

  # Simple implementation of Enumerator::Chain for Ruby versions < 2.6
  # or JRuby < 9.3
  class Chain < ::Enumerator

    def initialize(*enums)
      super() { |y| enums.each { |enum| enum.each { |o| y<< o } } }
    end

  end

end

end
