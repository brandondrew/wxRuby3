###
# wxRuby3 wxWidgets interface director
# Copyright (c) M.J.N. Corino, The Netherlands
###

module WXRuby3

  class Director

    class HelpController < Director

      include Typemap::ConfigBase

      def setup
        super
        spec.items << 'wxHelpControllerBase'
        spec.fold_bases(spec.module_name => 'wxHelpControllerBase')
        spec.rename_for_ruby('Init' => "#{spec.module_name}::Initialize")
        # ignore these (pure virtual) decls
        spec.ignore %w[
          wxHelpControllerBase::DisplayBlock
          wxHelpControllerBase::DisplaySection
          wxHelpControllerBase::LoadFile
          wxHelpControllerBase::Quit
          ]
        # and add them as the implemented overrides they are
        spec.extend_interface spec.module_name,
                              'virtual bool DisplayBlock(long blockNo)',
                              'virtual bool DisplaySection(int sectionNo)',
                              'virtual bool LoadFile(const wxString &file=wxEmptyString)',
                              'virtual bool Quit()'
        # ignore this problematic method
        spec.ignore 'wxHelpControllerBase::GetFrameParameters'
        # and add a customized version
        spec.add_extend_code spec.module_name, <<~__HEREDOC
          VALUE GetFrameParameters()
          {
            wxFrame *result = 0;
            wxSize size;
		        wxPoint pos;
		        bool newFrameEachTime;
            result = $self->GetFrameParameters(&size, &pos, &newFrameEachTime);
            VALUE rc = Qnil;
            if (result)
            {
              rc = rb_ary_new();
              rb_ary_push(rc, wxRuby_WrapWxObjectInRuby(result));
              rb_ary_push(rc, SWIG_NewPointerObj(new wxSize(size), SWIGTYPE_p_wxSize, 1));
              rb_ary_push(rc, SWIG_NewPointerObj(new wxPoint(pos), SWIGTYPE_p_wxPoint, 1));
              rb_ary_push(rc, newFrameEachTime ? Qtrue : Qfalse);
            }
            return rc;
          }
          __HEREDOC
        spec.suppress_warning(473, "#{spec.module_name}::GetParentWindow")
        if spec.module_name == 'wxHtmlHelpController'
          # prevent having to expose HtmlHelpFrame & HtmlHelpDialog
          # I do not see real use in supporting custom HtmlHelpController derivatives
          spec.ignore 'wxHtmlHelpController::CreateHelpFrame',
                      'wxHtmlHelpController::CreateHelpDialog',
                      'wxHtmlHelpController::GetFrame',
                      'wxHtmlHelpController::GetDialog'
        elsif spec.module_name == 'wxExtHelpController'
          spec.ignore %w[
            wxExtHelpController::DisplayBlock
            wxExtHelpController::DisplaySection
            wxExtHelpController::LoadFile
            wxExtHelpController::Quit
            wxExtHelpController::GetFrameParameters
          ]
          # already generated with HelpController
          spec.do_not_generate :variables, :enums, :defines, :functions
        end
      end
    end # class HelpController

  end # class Director

end # module WXRuby3
