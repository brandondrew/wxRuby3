# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 wxWidgets interface director
###

module WXRuby3

  class Director

    class Menu < Director

      def setup
        spec.gc_never
        spec.ignore 'wxMenu::wxMenu(long)'
        spec.no_proxy 'wxMenu'  # do not support derived wxMenu classes
        spec.add_header_code <<~__HEREDOC
          // Custom subclass implementation. 
          // Provides proper support for Ruby GC in destructor.
          class wxRubyMenu : public wxMenu
          {
          public:
            wxRubyMenu() : wxMenu() {}
            wxRubyMenu(const wxString &title, long style=0) : wxMenu(title, style) {}
            virtual ~wxRubyMenu()
            {
              SWIG_RubyUnlinkObjects(this);
              SWIG_RubyRemoveTracking(this);
            }
          };
        __HEREDOC
        # make Ruby director and wrappers use custom implementation
        spec.use_class_implementation('wxMenu', 'wxRubyMenu')
        # ignore non-const version as that has no benefits in Ruby
        spec.ignore 'wxMenu::GetMenuItems()'
        # Fix for GetMenuItems - converts list of MenuItems to Array
        spec.map 'wxMenuItemList&' => 'Array<Wx::MenuItem>' do
          map_out code: <<~__CODE
            $result = rb_ary_new();
            wxMenuItemList::iterator iter;
            for (iter = $1->begin(); iter != $1->end(); ++iter)
            {
                wxMenuItem *wx_menu_item = *iter;
                VALUE rb_menu_item = SWIG_NewPointerObj(SWIG_as_voidptr(wx_menu_item), 
                                                        SWIGTYPE_p_wxMenuItem, 0);
                rb_ary_push($result, rb_menu_item);
            }
          __CODE
        end
        # for FindItem
        spec.map 'wxMenu **' => 'Wx::Menu' do
          map_in ignore: true, temp: 'wxMenu *tmp', code: '$1 = &tmp;'
          map_argout code: <<~__CODE
            void *ptr = tmp$argnum;
            $result = SWIG_Ruby_AppendOutput($result, SWIG_NewPointerObj(ptr, SWIGTYPE_p_wxMenu, 0));
            __CODE
        end
        # for FindChildItem
        spec.map_apply 'size_t * OUTPUT' => 'size_t * pos'
        spec.add_header_code <<~__HEREDOC
          // Mark Function
          // Need to protect MenuItems which are included in the Menu, including
          // their associated sub-menus, recursively.
          static void mark_wxMenu(void *ptr) 
          {
            if ( GC_IsWindowDeleted(ptr) )
              return;
        
            wxMenu* menu = (wxMenu*)ptr;
            wxMenuItemList menu_items = menu->GetMenuItems();
            wxMenuItemList::iterator iter;
            for (iter = menu_items.begin(); iter != menu_items.end(); ++iter)
              {
                wxMenuItem *item = *iter;
                rb_gc_mark( SWIG_RubyInstanceFor(item) ); 
                wxMenu* sub_menu = item->GetSubMenu();
                if ( sub_menu)
                  rb_gc_mark( SWIG_RubyInstanceFor(sub_menu) );
              }
            return;
          }
        __HEREDOC
        spec.add_swig_code <<~__HEREDOC
          %markfunc wxMenu "mark_wxMenu";
        __HEREDOC
        # ignore MSW specific method
        spec.ignore 'wxMenu::MSWCommand'
        # fix SWIG's problems with const& return value
        spec.ignore('wxMenu::GetTitle', ignore_doc: false) # keep doc
        spec.add_extend_code 'wxMenu', <<~__HEREDOC
          wxString* GetTitle() const {
            wxString const& title = $self->GetTitle();
            return &const_cast<wxString&> (title);
          }

          VALUE each_item()
          {
            VALUE rc = Qnil;
            for (size_t i=0; i<$self->GetMenuItemCount(); ++i)
            {
              wxMenuItem *wx_menu_item = $self->FindItemByPosition(i);
              VALUE rb_menu_item = SWIG_NewPointerObj(SWIG_as_voidptr(wx_menu_item), 
                                                      SWIGTYPE_p_wxMenuItem, 0);
              rc = rb_yield(rb_menu_item);
            }
            return rc;
          }
          __HEREDOC
        super
      end
    end # class Menu

  end # class Director

end # module WXRuby3
