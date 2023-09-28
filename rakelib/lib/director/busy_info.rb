# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 wxWidgets interface director
###

module WXRuby3

  class Director

    class BusyInfo < Director

      def setup
        super
        spec.items << 'wxBusyInfoFlags'
        spec.disable_proxies
        spec.gc_as_untracked 'wxBusyInfo', 'wxBusyInfoFlags'
        # again C++ type guards do not work with Ruby
        # need to Rubify this
        spec.make_abstract 'wxBusyInfo'
        spec.ignore %w[
          wxBusyInfo::wxBusyInfo
          ]
        # BusyInfo is an exception to the general rule in typemap.i - it
        # accepts a wxWindow* parent argument which may be null - but it does
        # not inherit from TopLevelWindow - so special typemap for this class.
        spec.map 'wxWindow* parent' do
          map_check code: <<~__CODE
            if ( !wxRuby_IsAppRunning() )
            { 
              rb_raise(rb_eRuntimeError,
                   "Cannot create BusyInfo before App.main_loop has been called");
            }
            __CODE
        end
        spec.add_extend_code 'wxBusyInfo', <<~__HEREDOC
          static VALUE busy(const wxString& message, wxWindow *parent = NULL)
          {
            VALUE rc = Qnil;
            VALUE rb_busyinfo = Qnil;
            wxBusyInfo *p_busyinfo = 0 ;
            if (rb_block_given_p())
            {
              wxBusyInfo disabler(message,parent);
              p_busyinfo = &disabler;
              rb_busyinfo = SWIG_NewPointerObj(SWIG_as_voidptr(p_busyinfo), SWIGTYPE_p_wxBusyInfo, 0);
              rc = rb_yield(rb_busyinfo);
            }
            return rc;
          }
          static VALUE busy(const wxBusyInfoFlags &flags)
          {
            VALUE rc = Qnil;
            VALUE rb_busyinfo = Qnil;
            wxBusyInfo *p_busyinfo = 0 ;
            if (rb_block_given_p())
            {
              wxBusyInfo disabler(flags);
              p_busyinfo = &disabler;
              rb_busyinfo = SWIG_NewPointerObj(SWIG_as_voidptr(p_busyinfo), SWIGTYPE_p_wxBusyInfo, 0);
              rc = rb_yield(rb_busyinfo);
            }
            return rc;
          }
          __HEREDOC
        spec.map 'wxBusyInfoFlags &' => 'Wx::BusyInfoFlags' do
          map_out code: '$result = self; wxUnusedVar($1);'
        end
      end
    end # class BusyInfo

  end # class Director

end # module WXRuby3
