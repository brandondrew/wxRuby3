# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 wxWidgets interface director
###

require_relative './window'

module WXRuby3

  class Director

    class RichTextCtrl < Window

      include Typemap::RichText
      if Config.instance.features_set?('wxUSE_DATETIME')
        include Typemap::DateTime
      end

      def setup
        super
        spec.override_inheritance_chain('wxRichTextCtrl', %w[wxControl wxWindow wxEvtHandler wxObject])
        spec.include 'wx/dc.h'
        spec.ignore [
          'wxRichTextCtrl::GetSelection(long *,long *) const',
          'wxRichTextCtrl::GetSelection() const',
          'wxRichTextCtrl::SetStyle(long,long,const wxTextAttr &)',
          'wxRichTextCtrl::SetStyle(const wxRichTextRange &,const wxTextAttr &)',
          'wxRichTextCtrl::SetStyle(wxRichTextObject *,const wxRichTextAttr &,int)',
          'wxRichTextCtrl::GetStyleForRange(const wxRichTextRange &,wxTextAttr &)',
          'wxRichTextCtrl::HitTest(const wxPoint &,long *)',
          'wxRichTextCtrl::SetListStyle(const wxRichTextRange &,wxRichTextListStyleDefinition *,int,int,int)',
          ]
        # TODO : not supported (yet)
        spec.ignore %w[
          wxRichTextCtrl::WriteTextBox
          wxRichTextCtrl::WriteField
          wxRichTextCtrl::WriteTable
          wxRichTextCtrl::PaintBackground
          wxRichTextCtrl::PaintAboveContent
          ]
        spec.no_proxy %w[
          wxRichTextCtrl::GetDefaultStyleEx
          wxRichTextCtrl::GetBasicStyle
          ]
        unless Config.instance.features_set?('wxUSE_DATETIME')
          spec.ignore %w[wxRichTextCtrl::GetDragStartTime wxRichTextCtrl::SetDragStartTime]
        end
        spec.swig_import('swig/classes/include/wxTextAttr.h',
                         'swig/classes/include/wxRichTextBuffer.h',
                         append_to_base_imports: true)
        spec.suppress_warning(402, 'wxRichTextAttr')
        # Deal with some output values from TextCtrl methods - PositionToXY
        spec.map_apply 'long * OUTPUT' => 'long *'
        spec.map_apply 'long * OUTPUT' => [ 'wxTextCoord *col', 'wxTextCoord *row' ]
        # GetViewStart
        spec.map_apply 'int * OUTPUT' => 'int *'
        spec.map_apply 'SWIGTYPE *DISOWN' => 'wxRichTextStyleSheet* styleSheet'
      end
    end # class RichTextCtrl

  end # class Director

end # module WXRuby3
