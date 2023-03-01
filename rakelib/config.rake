###
# wxRuby3 rake file
# Copyright (c) M.J.N. Corino, The Netherlands
###

require_relative './configure'

namespace :wxruby do

  namespace :config do

    task :configure  do |task, args|
      WXRuby3::Config.define(task, args)
      WXRuby3::Config.check
      WXRuby3::Config.save
      exit(0) # do not allow other tasks to be run after wxruby:configure
    end

    task :show do
      WXRuby3::CFG_KEYS.each do |ck|
        puts "%20s => %s" % [ck, WXRuby3.config.get_config(ck)]
      end
    end

    # Bootstrap the wxRuby3 build environment
    bootstrap_task = task :bootstrap => [WXRuby3.build_cfg]

    if WXRuby3.is_configured?
      bootstrap_task.enhance([WXRuby3.config.wx_xml_path])

      directory WXRuby3.config.wx_xml_path do
        WXRuby3.config.do_bootstrap
      end
    end
  end

  desc 'Configure wxRuby build settings (calling with "-- --help" provides usage information).'
  task :configure => 'config:configure'

  desc 'Show current wxRuby build settings'
  task :show => 'config:show'

end

file WXRuby3::BUILD_CFG do
  unless File.file?(WXRuby3::BUILD_CFG)
    STDERR.puts "ERROR: Build configuration missing! First run 'rake wxruby::configure'."
    exit(1)
  end
end
