# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 wxWidgets interface director
###

module WXRuby3

  class Director

    class Sizer < Director

      def setup
        # Any nested sizers passed to Add() in are owned by C++, not GC'd by Ruby
        spec.disown 'wxSizer* sizer'
        case spec.module_name
        when 'wxSizer'
          spec.items << 'wxSizerFlags'
          spec.gc_as_untracked('wxSizerFlags')
          spec.make_abstract('wxSizer')
          spec.ignore %w[wxSizer::IsShown wxSizer::SetVirtualSizeHints]
          # cannot use these with wxRuby
          spec.ignore 'wxSizer::Add(wxSizerItem *)',
                      'wxSizer::Insert(size_t, wxSizerItem *)',
                      'wxSizer::Prepend(wxSizerItem *)'
          spec.ignore 'wxSizer::Remove(wxWindow *)' # long time deprecated
          # Typemap for GetChildren - convert to array of Sizer items
          spec.map 'wxSizerItemList&' => 'Array<Wx::SizerItem>' do
            map_out code: <<~__CODE
              $result = rb_ary_new();
              wxSizerItemList::compatibility_iterator node = $1->GetFirst();
              while (node)
              {
                wxSizerItem *wx_si = node->GetData();
                VALUE rb_si = SWIG_NewPointerObj(wx_si, SWIGTYPE_p_wxSizerItem, 0);
                rb_ary_push($result, rb_si);
                node = node->GetNext();
              }
              __CODE
          end
          spec.map 'wxSizerFlags&' => 'Wx::SizerFlags' do
            map_out code: '$result = self; wxUnusedVar($1);'
          end
          # get rid of unwanted SWIG warning
          spec.suppress_warning(517, 'wxSizer')
        when 'wxGridBagSizer'
          spec.items << 'wxGBSpan' << 'wxGBPosition'
          spec.gc_as_untracked 'wxGBSpan', 'wxGBPosition'
          # cannot use this with wxRuby
          spec.ignore 'wxGridBagSizer::Add(wxGBSizerItem *)'
        end
        # no real use for allowing these to be overloaded but a whole lot of grieve
        # if we do allow it
        spec.no_proxy(%W[
            #{spec.module_name}::Detach
            #{spec.module_name}::Replace
            #{spec.module_name}::Remove
            #{spec.module_name}::Clear
            #{spec.module_name}::Layout
          ])
        spec.no_proxy "#{spec.module_name}::AddSpacer"
        super
      end
    end # class Object

  end # class Director

end # module WXRuby3
