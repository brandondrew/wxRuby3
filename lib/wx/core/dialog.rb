# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.
# 
# Some parts are
# Copyright 2004-2007, wxRuby development team
# released under the MIT-like wxRuby2 license

# WxRuby Extensions - Dialog functors for wxRuby3

class Wx::Dialog

  module Functor
    def self.included(klass)
      scope = klass.name.split('::')
      functor_nm = scope.pop
      code = <<~__CODE
        def #{functor_nm}(*args, &block)
          dlg = #{klass.name}.new(*args)
          begin
            if block_given?
              return block.call(dlg)
            else
              return dlg.show_modal
            end
          rescue Exception
            Wx.log_debug "\#{$!}\\n\#{$!.backtrace.join("\\n")}"
            raise
          ensure
            dlg.destroy
          end
        end
        __CODE
      if scope.empty?
        ::Kernel.module_eval code
      else
        scope.inject(::Object) { |mod, nm| mod.const_get(nm) }.singleton_class.module_eval code
      end
      klass.class_eval do
        def self.inherited(sub)
          sub.include Wx::Dialog::Functor
        end
      end
    end
  end

  include Functor

  def self.setup_dialog_functors(mod)
    # find all Dialog descendants in mod and setup the dialog Functor for them
    mod.constants.select do |c|
      ::Class === (const = mod.const_get(c)) && const < Wx::Dialog
    end.each { |c| mod.const_get(c).include Wx::Dialog::Functor }
  end

  setup_dialog_functors(Wx)
end
