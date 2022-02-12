# frozen_string_literal: true

module Capistrano
  module Systemd
    module Nextjs
      module DSL
        def each_process
          fetch(:nextjs_processes).each do |nextjs_current_process|
            set(:nextjs_current_process, nextjs_current_process)

            yield nextjs_current_process
          end
        end

        def create_systemd_template(process_name)
          systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)

          if fetch(:nextjs_service_unit_user) == :user
            execute :mkdir, "-p", systemd_path
          end

          compiled_template = compiled_systemd_template(process_name)
          tmp_path = "/tmp/#{process_name}.service"

          upload!(StringIO.new(compiled_template), tmp_path)

          if fetch(:nextjs_service_unit_user) == :system
            execute :sudo, :mv, tmp_path, "#{systemd_path}/#{process_name}.service"
            execute :sudo, :systemctl, "daemon-reload"
          else
            execute :mv, tmp_path, "#{systemd_path}/#{process_name}.service"
            execute :systemctl, "--user", "daemon-reload"
          end
        end

        def compiled_systemd_template(process_name)
          args = []
          args.push "--cwd #{File.join(fetch(:deploy_to), 'current')}"

          search_paths = [
            File.expand_path(
                File.join(*%w[.. templates nextjs.service.erb]),
                __FILE__
            ),
          ]

          template_path = search_paths.detect { |path| File.file?(path) }
          template = File.read(template_path)

          ERB.new(template).result(binding)
        end

        def switch_user(role)
          su_user = nextjs_user

          if su_user != role.user
            yield
          else
            as su_user do
              yield
            end
          end
        end

        def nextjs_user
          fetch(:nextjs_user, fetch(:run_as))
        end

        def fetch_systemd_unit_path
          if fetch(:nextjs_service_unit_user) == :system
            "/etc/systemd/system/"
          else
            home_dir = capture(:pwd)

            File.join(home_dir, ".config", "systemd", "user")
          end
        end

        def fetch_nextjs_rackup
          if fetch(:nextjs_processes).length > 1
            File.join(current_path, 'apps', fetch(:nextjs_current_process), 'config.ru')
          else
            File.join(current_path, 'config.ru')
          end
        end

        def fetch_nextjs_bind
          File.join("unix://#{shared_path}", 'tmp', 'sockets', "#{fetch(:nextjs_current_process)}.sock")
        end

        def fetch_nextjs_pid
          File.join(fetch(:nextjs_pids_path), "#{fetch(:nextjs_current_process)}.pid")
        end

        def fetch_nextjs_state
          File.join(fetch(:nextjs_pids_path), "#{fetch(:nextjs_current_process)}.state")
        end

        def fetch_nextjs_access_log
          File.join(fetch(:nextjs_logs_path), "#{fetch(:nextjs_current_process)}.access.log")
        end

        def fetch_nextjs_error_log
          File.join(fetch(:nextjs_logs_path), "#{fetch(:nextjs_current_process)}.error.log")
        end

        def fetch_nextjs_config
          File.join(fetch(:nextjs_config_path), "#{fetch(:nextjs_current_process)}.rb")
        end
      end
    end
  end
end

extend Capistrano::Systemd::Nextjs::DSL

SSHKit::Backend::Local.module_eval do
  include Capistrano::Systemd::Nextjs::DSL
end

SSHKit::Backend::Netssh.module_eval do
  include Capistrano::Systemd::Nextjs::DSL
end
