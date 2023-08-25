###
# wxRuby3 wxWidgets interface extractor
# Copyright (c) M.J.N. Corino, The Netherlands
###

module WXRuby3

  module Extractor

    class SuperDef
      def self.[](name, *supers, mod: nil)
        self.new(name, *supers, mod: mod)
      end

      def self.create_super_def(spec)
        case spec
        when SuperDef
          spec
        when ::Hash
          name, mod = spec.first
          SuperDef[name, mod: mod]
        else
          SuperDef[spec.to_s]
        end
      end

      def self.build_inheritance_chain(*supers)
        return SuperDef[nil] if supers.empty?
        base = create_super_def(supers.shift)
        base.add_super(build_inheritance_chain(*supers)) unless supers.empty?
        base
      end

      def self.build_hierarchy(*supers)
        supers.inject({}) do |h, p|
          sd = create_super_def(p)
          h[sd.name] = sd
          h
        end
      end

      def initialize(name, *supers, mod: nil)
        @name = name
        @module = mod
        @supers = SuperDef.build_hierarchy(*supers)
      end

      attr_reader :name, :supers

      def module
        @module ? @module : @name
      end

      def add_super(spr, *supers, mod: nil)
        if SuperDef === spr
          @supers[spr.name] = spr
        else
          @supers[spr.to_s] = SuperDef.new(spr.to_s, *supers, mod: mod)
        end
      end

      def get_super(name)
        @supers[name]
      end

      def to_s
        "{#{name}#{@module ? "@#{@module}" : ''} < #{@supers.values.join(', ')}}"
      end

      def inspect
        to_s
      end
    end

    # The information about a class that is needed to generate wrappers for it.
    class ClassDef < BaseDef

      include Util::StringUtil

      NAME_TAG = 'compoundname'

      IGNORED_BASES = ['wxTrackable']

      def initialize(element = nil, kind = 'class', **kwargs)
        super()
        @kind = kind
        @protection = 'public'
        @template_params = [] # class is a template
        @bases = [] # base class names
        @sub_classes = [] # sub classes
        @hierarchy = {}
        @includes = [] # .h file for this class
        @abstract = false # is it an abstract base class?
        @no_def_ctor = false # do not generate a default constructor
        @innerclasses = []
        @is_inner = false # Is this a nested class?
        @klass = nil # if so, then this is the outer class
        @event = false # if so, is wxEvent derived class
        @event_list = false # if so, class has emitted events specified
        @event_types = []
        @param_mappings = []
        @crossref_table = {}

        update_attributes(**kwargs)
        extract(element) if element
      end

      attr_accessor :kind, :protection, :template_params, :bases, :sub_classes, :hierarchy, :includes, :abstract,
                    :no_def_ctor, :innerclasses, :is_inner, :klass, :event, :event_list, :event_types, :crossref_table

      def is_template?
        !template_params.empty?
      end

      def get_hierarchy(element)
        this = nil
        index = {}
        # collect
        graph = element.at_xpath('inheritancegraph')
        if graph
          graph.xpath('node'). each do |node|
            node_name = node.at_xpath('label').text
            unless IGNORED_BASES.include?(node_name)
              node_supers = node.xpath('childnode').collect { |cn|  cn['refid'] }
              sd = SuperDef[node_name]
              index[node['id']] = [sd, node_supers]
              this = sd if @name == node_name
            end
          end
          # resolve
          index.each_value do |(sd, ns)|
            ns.each { |sid| sd.add_super(index[sid].first) if index.has_key?(sid) }
          end
        end
        this ? this.supers : {}
      end

      def find_base(bases, name)
        return bases[name] if bases.has_key?(name)
        bases.each_value do |base|
          if (base = find_base(base.supers, name))
            return base
          end
        end
        nil
      end
      private :find_base

      def is_derived_from?(classname)
        !!find_base(@hierarchy, classname)
      end

      def add_crossrefs(element)
        element.xpath('listofallmembers/member').each do |node|
          crossref_table[node['refid']] = { scope: node.at_xpath('scope').text, name: node.at_xpath('name').text }
        end
      end
      private :add_crossrefs

      def extract(element)
        super

        check_deprecated
        # @node_bases = find_hierarchy(element, {}, [], false)
        @hierarchy = get_hierarchy(element)

        element.xpath('basecompoundref').each { |node| @bases << node.text }
        element.xpath('derivedcompoundref').each { |node| @sub_classes << node.text }
        element.xpath('includes').each { |node| @includes << node.text }
        element.xpath('templateparamlist/param').each do |node|
          if node.at_xpath('declname')
            txt = node.at_xpath('declname').text
          else
            txt = node.at_xpath('type').text
            txt.sub!('class ', '')
            txt.sub!('typename ', '')
          end
          @template_params << txt
        end

        if is_derived_from?('wxEvent')
          @event = true
          if /Event macros(\s+for\s+events\s+emitted\s+by\s+this\s+class)?:/ =~ detailed_doc.text
            detailed_doc.xpath('.//listitem').each do |li|
              if li.text =~ /(EVT_\w+)\W*\((.*)\)/
                evt_handler = $1
                args = $2.split(',').collect {|a| a.strip }
                # skip event macros with event type argument
                unless args.any? { |a| a == 'event' }
                  # determine evt_type handled
                  evt_type = if li.text =~ /(Process\s+a|Respond\s+to)\s+wx(\w+)\s+/
                               $2
                             else
                               evt_handler
                             end
                  # record event handler (macro) name, event type handled and the number of event id arguments
                  evt_arity = args.inject(0) {|c, a| c += 1 if a =~ /\A(win)?id/; c }
                  @event_types << [evt_handler, evt_type, evt_arity]
                end
              end
            end
          end
        else
          evt_heading = detailed_doc.xpath('.//heading').find {|h| h.text == 'Events emitted by this class'}
          if evt_heading
            @event_list = true
            evt_paras = evt_heading.xpath('parent::para').first.xpath('following-sibling::para')
            if (evt_paras.size>1 &&
                  (evt_paras[0].text.start_with?('The following event handler macros redirect') ||
                    evt_paras[0].text.start_with?('Event macros for events emitted by this class:')))
              evt_klass = if (evt_ref = evt_paras[0].at('./ref'))
                            evt_ref.text
                          else
                            nil
                          end
              evt_paras[1].xpath('.//listitem').each do |li|
                if li.text =~ /(EVT_\w+)\((.*)\)/
                  evt_handler = $1
                  args = $2.split(',').collect {|a| a.strip }
                  # skip event macros with event type argument
                  unless args.any? { |a| a == 'event' }
                    # determine evt_type handled
                    evt_type = if li.text =~ /Process\s+a\s+wx(\w+)\s+/
                                 $1
                               else
                                 evt_handler
                               end
                    # record event handler (macro) name, event type handled and the number of event id arguments
                    evt_arity = args.inject(0) {|c, a| c += 1 if a =~ /\A(win)?id/; c }
                    @event_types << [evt_handler, evt_type, evt_arity, evt_klass, false]
                  end
                end
              end
            end
          end
        end

        element.xpath('innerclass').each do |node|
          unless node['prot'] == 'private'
            ref = node['refid']
            fname = File.join(Extractor.xml_dir, ref + '.xml')
            root = File.open(fname) { |f| Nokogiri::XML(f).root }
            innerclass = root.elements.first
            kind = innerclass['kind']
            unless %w[class struct].include?(kind)
              raise ExtractorError.new("Invalid innerclass kind [#{kind}]")
            end
            item = ClassDef.new(innerclass, kind, gendoc: self.gendoc)
            item.protection = node['prot']
            item.is_inner = true
            item.klass = self # This makes a reference cycle but it's okay
            item.ignore if item.protection == 'protected' # ignore by default
            @innerclasses << item
          end
        end

        # TODO: Is it possible for there to be memberdef's w/o a sectiondef?
        member = nil
        element.xpath('sectiondef/memberdef').each do |node|
          # skip any private items
          unless node['prot'] == 'private'
            case _kind = node['kind']
            when 'function'
              Extractor.extracting_msg(_kind, node)
              member = MethodDef.new(node, self.name, klass: self, gendoc: self.gendoc)
              #@abstract = true if m.is_pure_virtual
              unless member.check_for_overload(self.items)
                self.items << member
              end
            when 'variable'
              Extractor.extracting_msg(_kind, node)
              member = MemberVarDef.new(node, gendoc: self.gendoc)
              self.items << member
            when 'enum'
              Extractor.extracting_msg(_kind, node)
              member = EnumDef.new(node, scope: self.name, gendoc: self.gendoc)
              self.items << member
            when 'typedef'
              Extractor.extracting_msg(_kind, node)
              member = TypedefDef.new(node, gendoc: self.gendoc)
              self.items << member
            when 'friend'
              # noop
            else
              raise ExtractorError.new('Unknown memberdef kind: %s' % _kind)
            end
            # ignore protected members by default
            member.ignore if member.protection == 'protected'
          end
        end

        add_crossrefs(element) if self.gendoc

        # make abstract unless the class has at least 1 public ctor
        ctor = self.items.find {|m| MethodDef === m && m.is_ctor }
        unless ctor && (ctor.protection == 'public' || ctor.overloads.any? {|ovl| ovl.protection == 'public' })
          @abstract = true
        end
      end

      def regards_protected_members?
        self.items.any? {|item| !item.ignored && item.protection == 'protected' }
      end

      def add_param_mapping(from, to)
        @param_mappings << FunctionDef::ParamMapping.new(from, to)
      end

      def find_param_mapping(paramdefs)
        @param_mappings.detect { |pm| pm.matches?(paramdefs) }
      end

      def methods
        ::Enumerator.new { |y| items.each {|i|  y << i if MethodDef === i }}
      end

      def aliases
        methods.select do |mtd|
          # exclude ctor/dtor and static and methods
          rc = false
          unless mtd.is_ctor || mtd.is_dtor || mtd.is_static
            mtd_ovls = mtd.all.select { |ovl| !ovl.ignored } # only consider non-ignored
            # only consider methods without overloads or where all overloads have either
            # not been renamed or have all been renamed identically
            # (SWIG %rename does not work well with %alias in these cases so leave those
            # for WxRubyStyleAccessors to handle at runtime)
            last_nm = nil
            rc = !mtd_ovls.empty? &&
              (mtd_ovls.size==1 ||
                mtd_ovls.all? { |ovl| !ovl.rb_name } ||
                mtd_ovls.inject(::Set.new) { |set, ovl| set << ovl.rb_name }.size==1)
            if rc
              mtd = mtd_ovls.first
              mtd_name = mtd.rb_name || mtd.name
              unless (rc = (/\A(Is|Has|Can)[A-Z]/ =~ mtd_name))
                unless (rc = (/\A(is|has|can)_\w+\Z/ =~ mtd_name))
                  if /\A(Get[A-Z]|get_\w)/ =~ mtd_name
                    # since getters have no decoration ('=' or '?') a C++ method with the same
                    # name could exist already; check this and exclude if so
                    alias_name = mtd_name.sub(/\A(Get|get_)/, '')
                    rc = !methods.any? { |m| !m.ignored && rb_method_name(alias_name) == m.rb_decl_name }
                  elsif /\A(Set[A-Z]|set_\w)/ =~ mtd_name
                    # only consider setter aliases (xxx=) in case at least one method overload
                    # accepts only a single argument
                    rc = mtd_ovls.any? { |ovl| ovl.parameter_count>0 && ovl.required_param_count<2 }
                  end
                end
              end
              if rc
                # check there is not a static method with the same name; SWIG alias handling chokes on that
                rc = !methods.any? { |m| !m.ignored && m.is_static && m.name == mtd_name}
              end
            end
          end
          rc
        end.collect do |mtd|
          mtd = mtd.all.select { |ovl| !ovl.ignored }.shift
          mtd_name = mtd.rb_name || mtd.name
          case mtd_name
          when /\A(Get|get_)/
            [mtd.name, rb_method_name(mtd_name.sub(/\A(Get|get_)/, ''), keep_wx_prefix: true)]
          when /\A(Set|set_)/
            [mtd.name, rb_method_name(mtd_name.sub(/\A(Set|set_)/, ''), keep_wx_prefix: true)+'=']
          when /\A(Is|is_)/
            [mtd.name, rb_method_name(mtd_name.sub(/\A(Is|is_)/, ''), keep_wx_prefix: true)+'?']
          else # when /\A(Has|Can|has_|can_)/
            [mtd.name, rb_method_name(mtd_name)+'?']
          end
        end.to_h
      end

      def all_methods
        ::Enumerator::Chain.new(*methods.collect {|m| m.all })
      end

      def _find_items
        self.items + self.innerclasses
      end

    end # class ClassDef

  end # module Extractor

end # module WXRuby3
