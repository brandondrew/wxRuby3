###
# wxRuby3 wxWidgets interface director
# Copyright (c) M.J.N. Corino, The Netherlands
###

module WXRuby3

  class Director

    class Locale < Director

      def setup
        super
        spec.disable_proxies
        spec.items << 'wxLanguageInfo' << 'language.h'
        spec.gc_as_object('wxLocale')
        spec.gc_as_untracked('wxLanguageInfo')
        spec.make_concrete 'wxLanguageInfo'
        spec.regard %w[
          wxLanguageInfo::Language
          wxLanguageInfo::LocaleTag
          wxLanguageInfo::CanonicalName
          wxLanguageInfo::CanonicalRef
          wxLanguageInfo::Description
          wxLanguageInfo::DescriptionNative
          wxLanguageInfo::LayoutDirection
          ]
        if Config.instance.features_set?('__WXMSW__')
          spec.regard('wxLanguageInfo::WinLang', 'wxLanguageInfo::WinSublang')
        end
      end
    end # class Locale

  end # class Director

end # module WXRuby3
