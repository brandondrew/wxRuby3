# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

# wxruby unit test command handler
#--------------------------------------------------------------------

require 'fileutils'

module WxRuby
  module Commands
    class Test
      def self.description
        "    test\t\t\tRun wxRuby3 regression tests."
      end

      def self.run(argv)
        if argv == :describe
          description
        else
          Dir[File.join(WxRuby::ROOT, 'tests', '*.rb')].each do |test|
            exit(1) unless system(RUBY, test)
          end
        end
      end
    end

    self.register('test', Test)
  end
end
