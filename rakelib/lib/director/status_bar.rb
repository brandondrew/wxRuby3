# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 wxWidgets interface director
###

require_relative './window'

module WXRuby3

  class Director

    class StatusBar < Window

      def setup
        super
        # StatusBar has numerous methods (eg GetFieldRect, G/SetStatusText,
        # SetFieldsCount) that are marked 'virtual', but can't be
        # usefully re-implemented in Ruby.
        spec.disable_proxies
        # special type mappings
        # For GetFieldsRect
        spec.map 'wxRect& rect' => 'Wx::Rect' do
          map_in ignore: true, code: '$1 = new wxRect;'
          map_argout code: <<~__CODE
            if (result)
              $result = SWIG_NewPointerObj($1, SWIGTYPE_p_wxRect, 0);
            else 
            {
              delete $1;
              $result = Qnil;
            }
            __CODE
        end
        # For SetStatusWidths, SetStatusStyles
        spec.map 'int n, const int *widths_field', 'int n, const int *styles' do
          map_in from: {type: 'Array<Integer>', index: 1},
                 temp: 'std::unique_ptr<int[]> tmp_arr', code: <<~__CODE
            if (($input == Qnil) || (TYPE($input) != T_ARRAY) || (RARRAY_LEN($input) == 0))
            {
              $1 = 0;
              $2 = NULL;
            }
            else
            {
              tmp_arr = std::make_unique<int[]>(RARRAY_LEN($input));
              for (int i = 0; i < RARRAY_LEN($input); i++)
              {
                  tmp_arr[i] = NUM2INT(rb_ary_entry($input,i));
              }
              $1 = RARRAY_LEN($input);
              $2 = tmp_arr.get();
            }
            __CODE
        end
        # SetFieldsCount
        spec.map 'const int *widths' => 'Array<Integer>' do
          map_in temp: 'std::unique_ptr<int[]> tmp_arr', code: <<~__CODE
            if ($input == Qnil || (TYPE($input) == T_ARRAY && RARRAY_LEN($input) == 0))
            {
              $1 = NULL;
            }
            else if (TYPE($input) == T_ARRAY)
            {
              if (RARRAY_LEN($input) != arg2)
              {
                rb_raise(rb_eArgError, "the number of widths does not match the number of fields");
              }
              tmp_arr = std::make_unique<int[]>(RARRAY_LEN($input));
              for (int i = 0; i < RARRAY_LEN($input); i++)
              {
                  tmp_arr[i] = NUM2INT(rb_ary_entry($input,i));
              }
              $1 = tmp_arr.get();
            }
            else
            {
              rb_raise(rb_eArgError, "expected integer array for $argnum");
            }
          __CODE
        end
      end
    end # class StatusBar

  end # class Director

end # module WXRuby3
