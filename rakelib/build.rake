# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 rake file
###

require 'rake/clean'

namespace :wxruby do

  require_relative './build'

  #############################
  # public tasks

  task :build => ['config:bootstrap', :enum_list, *all_build_targets]

  task :compile => ['config:bootstrap', *all_compile_targets]

  task :recompile => ['config:bootstrap', :clean, :compile]

  task :swig   => ['config:bootstrap', WXRuby3.config.classes_path, :enum_list, *all_swig_targets]

  task :clean => [:clean_bin, :clean_src, *all_clean_targets] do
    rm_if(Dir[File.join(WXRuby3.config.interface_dir, '*')])
    rmdir_if(WXRuby3.config.interface_dir)
    rm_if(Dir[File.join(WXRuby3.config.common_dir, '*')])
    rmdir_if(WXRuby3.config.common_dir)
    rm_if(Dir[File.join(WXRuby3.config.classes_dir, '*')])
    rmdir_if(WXRuby3.config.classes_dir)
    rm_if(Dir[File.join(WXRuby3.config.rake_deps_dir, '.*.rake')])
    rmdir_if(WXRuby3.config.rake_deps_dir)
    rm_if(Dir[File.join(WXRuby3.config.src_gen_dir, '*')])
    rmdir_if(WXRuby3.config.src_gen_dir)
    rmdir_if(WXRuby3.config.src_dir)
  end

  task :clean_src do
    rm_if(Dir[File.join(WXRuby3.config.src_dir, '*.{cpp,h}')])
  end

  task :reswig => ['config:bootstrap', :clean_src, :swig]

  task :clean_bin do
    rm_if(Dir[File.join(WXRuby3::Config.wxruby_root, 'bin', '*')])
    rmdir_if(File.join(WXRuby3::Config.wxruby_root, 'bin'))
    rm_if(Dir[File.join(WXRuby3.config.dest_dir, "*.#{WXRuby3.config.dll_mask}")])
    rm_if(Dir[File.join(WXRuby3.config.obj_dir, '*')])
    rmdir_if(WXRuby3.config.obj_dir)
  end

  Rake::Task[:clobber].enhance(['wxruby:clean'])
  Rake::Task[:clobber].enhance do
    rm_rf(File.join(WXRuby3.config.ext_path, 'wxWidgets'))
  end if WXRuby3.config.with_wxwin?

end

desc "Create the binary Ruby library file"
task :build => 'wxruby:build'

desc "Delete SWIG interfaces, C++ sources, library and object files"
task :clean => 'wxruby:clean'
