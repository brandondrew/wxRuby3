# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.

###
# wxRuby3 buildtools platform pkg manager for SuSE type systems
###

module WXRuby3

  module Config

    module Platform

      module PkgManager

        PLATFORM_DEPS = %w[gtk3-devel webkit2gtk3-devel gspell-devel gstreamer-devel gstreamer-plugins-base-devel libcurl-devel libsecret-devel libnotify-devel libSDL-devel zlib-devel libjpeg-devel libpng-devel]

        class << self

          private

          def do_install(distro, pkgs)
            run_zypper(make_install_cmd(pkgs))
          end

          def add_platform_pkgs(pkgs)
            # add build tools
            if pkgs.include?('g++')
              pkgs.delete('g++')
              pkgs << 'gcc-c++'
            end
            # find pkgs we need
            pkgs.concat PLATFORM_DEPS.select { |pkg| !system("rpm -q --whatprovides #{pkg} >/dev/null 2>&1") }.to_a
          end

          def run_zypper(cmd)
            run("zypper -t -i #{cmd}")
          end

          def make_install_cmd(pkgs)
            # create install command
            "install -y #{ pkgs.join(' ') }"
          end

        end

      end

    end

  end

end
