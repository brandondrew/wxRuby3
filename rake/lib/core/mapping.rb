###
# wxRuby3 typemap mapping classes
# Copyright (c) M.J.N. Corino, The Netherlands
###

require_relative './parameter'

module WXRuby3

  module Typemap

    RubyArg = Struct.new(:type, :name)

    class Map

      class Base
        def initialize(map, temp: nil, code: nil)
          @map = map
          @temporaries = [temp].flatten.compact
          @mapping_code = code ? [code.to_s] : []
        end

        def kind
          self.class.name.split('::').last.downcase.to_sym
        end

        def modifiers
          nil
        end
        protected :modifiers

        def add_temporaries(*temps)
          @temporaries.concat temps.flatten
        end

        def add_code(code)
          @mapping_code << code.to_s
        end

        def to_swig
          tmpstr = (@temporaries && !@temporaries.empty?) ? " (#{@temporaries.join(', ')})" : ''
          mods = modifiers
          argmasks = @map.patterns.collect { |p| "(#{p.param_masks.collect { |pm| pm.to_s }.join(', ')})#{tmpstr}" }.join(', ')
          if @mapping_code.inject(0) { |lc, s| lc += (1 + s.count("\n")); lc } > 1
            <<~__SWIG
              %typemap(#{kind}) #{argmasks} {
                #{@mapping_code.collect { |s| s.split("\n") }.flatten.join("\n  ")}
              }
            __SWIG
          else
            %Q{%typemap(#{kind}) #{argmasks} "#{@mapping_code.first}";}
          end
        end
      end

      class In < Base
        def initialize(map, ignore: false, temp: nil, code: nil, &block)
          super(map, temp: temp, code: code)
          @ignore = ignore
          block.call(self) if block
        end

        def modifiers
          @ignore ? "numinputs=0" : nil
        end
      end

      class Default < Base
        def initialize(map, temp: nil, code: nil, &block)
          super(map, temp: temp, code: code)
          block.call(self) if block
        end
      end

      class Typecheck < Base
        def initialize(map, precedence: , temp: nil, code: nil, &block)
          super(map, temp: temp, code: code)
          @precedence = precedence
          block.call(self) if block
        end

        def modifiers
          @precedence ? "precedence=SWIG_TYPECHECK_#{@precendence.to_s.upcase}" : nil
        end
      end

      class Check < Base
        def initialize(map, temp: nil, code: nil, &block)
          super(map, temp: temp, code: code)
          block.call(self) if block
        end
      end

      class Out < Base
        def initialize(map, temp: nil, code: nil, &block)
          super(map, temp: temp, code: code)
          block.call(self) if block
        end
      end

      class FreeArg < Base
        def initialize(map, temp: nil, code: nil, &block)
          super(map, temp: temp, code: code)
          block.call(self) if block
        end
      end

      class ArgOut < Base
        def initialize(map, temp: nil, code: nil, &block)
          super(map, temp: nil, code: code)
          block.call(self) if block
        end
      end

      class DirectorIn < Base
        def initialize(map, temp: nil, code: nil, &block)
          super(map, temp: temp, code: code)
          block.call(self) if block
        end
      end

      class DirectorOut < Base
        def initialize(map, temp: nil, code: nil, &block)
          super(map, temp: temp, code: code)
          block.call(self) if block
        end
      end

      class DirectorArgOut < Base
        def initialize(map, temp: nil, code: nil, &block)
          super(map, temp: temp, code: code)
          block.call(self) if block
        end
      end

      class VarOut < Base
        def initialize(map, temp: nil, code: nil, &block)
          super(map, temp: nil, code: code)
          block.call(self) if block
        end
      end

      def initialize(*mappings, &block)
        @patterns = mappings.collect { |paramset| ParameterSet.new(paramset) }
        @mapped_types = {}
        @in = nil
        @default = nil
        @typecheck = nil
        @check = nil
        @argout = nil
        @out = nil
        @freearg = nil
        @directorin = nil
        @directorargout = nil
        @directorout = nil
        self.instance_eval &block if block
      end

      attr_reader :patterns, :mapped_types

      def _get_mapped_type(type)
        mapped_type = case type
                      when RubyArg
                        type
                      when ::Array
                        RubyArg[*type]
                      when ::Hash
                        RubyArg[type[:type], type[:name]]
                      else
                        RubyArg[type.to_s]
                      end
      end
      private :_get_mapped_type

      def map_type(types)
        if ::Hash === types && !types.has_key?(:type)
          types.each_pair do |argmasks, type|
            pattern = @patterns.detect { |ps| ps == argmasks }
            raise "Unknown parameter set [#{argmasks}] for [#{to_s}]" unless pattern
            mapped_type = _get_mapped_type(types)
            if ::Integer === mapped_type.name
              mapped_type.name = pattern.param_masks[mapped_type.name].name
            end
            @mapped_types[pattern] = _get_mapped_type(type)
          end
        else
          @patterns.inject(@mapped_types) do |map, pattern|
            mapped_type = _get_mapped_type(types)
            if ::Integer === mapped_type.name
              mapped_type.name = pattern.param_masks[mapped_type.name].name
            end
            map[pattern] = mapped_type
            map
          end
        end
      end

      def map_in(ignore: false, temp: nil, code: nil, &block)
        @in = In.new(self, ignore: ignore, temp: temp, code: code, &block)
      end

      def map_default(temp: nil, code: nil, &block)
        @default = Default.new(self, temp: temp, code: code, &block)
      end

      def map_typecheck(precedence: , temp: nil, code: nil, &block)
        @typecheck = Typecheck.new(self, precedence: precedence, temp: temp, code: code, &block)
      end

      def map_check(temp: nil, code: nil, &block)
        @check = Check.new(self, temp: temp, code: code, &block)
      end

      def map_out(temp: nil, code: nil, &block)
        @out = Out.new(self, temp: temp, code: code, &block)
      end

      def map_freearg(temp: nil, code: nil, &block)
        @check = FreeArg.new(self, temp: temp, code: code, &block)
      end

      def map_argout(temp: nil, code: nil, &block)
        @argout = ArgOut.new(self, temp: temp, code: code, &block)
      end

      def map_directorin(temp: nil, code: nil, &block)
        @directorin = DirectorIn.new(self, temp: temp, code: code, &block)
      end

      def map_directorout(temp: nil, code: nil, &block)
        @directorout = DirectorOut.new(self, temp: temp, code: code, &block)
      end

      def map_directorargout(temp: nil, code: nil, &block)
        @directorargout = DirectorArgOut.new(self, temp: temp, code: code, &block)
      end

      def map_varout(temp: nil, code: nil, &block)
        @argout = VarOut.new(self, temp: temp, code: code, &block)
      end

      def to_swig
        [@in,
         @default,
         @typecheck,
         @check,
         @argout,
         @out,
         @freearg,
         @directorin,
         @directorargout,
         @directorout].collect { |mapping| mapping ? mapping.to_swig : nil }.compact.join("\n")
      end

      def to_s
        "typemap #{@patterns.join(', ')}"
      end

    end # Map

    class AppliedMap
      def initialize(applied_map, src_pattern, *mappings)
        @patterns = mappings.collect { |paramset| ParameterSet.new(paramset) }
        @src_pattern = src_pattern
        @applied_map = applied_map
      end

      attr_reader :patterns

      def to_swig
        "%apply #{@src_pattern} { #{@patterns.join(', ')} };"
      end

      def to_s
        "applied typemap #{@patterns.join(', ')} (applies #{@applied_map})"
      end
    end

    class Collection
      def initialize
        @type_maps = []
      end

      def add(typemap)
        @type_maps << typemap
      end
      alias :<< :add

      def find(pattern)
        @type_maps.detect { |map| map.patterns.any? { |mp| mp == pattern } }
      end

      def to_swig
        @type_maps.collect { |map| map.to_swig }.join("\n")
      end

      def to_s
        "typemap collection"
      end
    end

    # module NoReturnMap
    #
    #   def no_return(*decls)
    #     no_return_methods.concat decls.flatten
    #   end
    #
    # end

    module Module

      module MappingMethods

        # creates a type mapping set
        def map(*mappings, &block)
          type_maps << Map.new(*mappings, &block)
        end

        # creates type mapping applications sets for different parameter sets
        def map_apply(application)
          application.each_pair do |src_mapping, tgt_mappings|
            src_pattern = ParameterSet.new(src_mapping)
            type_maps << AppliedMap.new(type_maps.find(src_pattern), src_pattern, *tgt_mappings)
          end
        end

        protected def create_typemaps
          # noop
        end

      end

      def self.included(base)
        base.singleton_class.class_eval do
          def define(&block)
            @typemap_setup = block
          end

          def create(typemap_user)
            typemap_user.instance_eval &@typemap_setup
          end
        end

        this_typemap_module = base.name

        # define an include handler for the typemap module which sets up the module/class
        # using the typemap module (most likely a Director class).
        base.module_eval <<~__HEREDOC
          def self.included(map_user_mod)
            # provide the map creation methods
            map_user_mod.include Typemap::Module::MappingMethods unless map_user_mod.include?(Typemap::Module::MappingMethods)
            # provide an overload to add the typemap definitions from typemap module
            map_user_mod.module_eval %Q{
                protected def create_typemaps
                  super
                  #{this_typemap_module}.create(self)
                end
              }
          end
          __HEREDOC
      end

    end

  end # Typemap

end # WXRuby3
