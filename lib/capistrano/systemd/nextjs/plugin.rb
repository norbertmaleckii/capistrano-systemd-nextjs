# frozen_string_literal: true

module Capistrano
  module Systemd
    module Nextjs
      class Plugin < Capistrano::Plugin
        def set_defaults
          set_if_empty :nextjs_roles, -> { fetch(:nextjs_role, :app) }
          set_if_empty :nextjs_processes, ['nextjs']
          set_if_empty :nextjs_env, -> { fetch(:stage) }

          set_if_empty :nextjs_init_system, :systemd
          set_if_empty :nextjs_service_unit_user, :user
          set_if_empty :nextjs_enable_lingering, true
          set_if_empty :nextjs_lingering_user, nil

          set_if_empty :nextjs_pids_path, -> { File.join(shared_path, 'tmp', 'pids') }
          set_if_empty :nextjs_logs_path, -> { File.join(shared_path, 'log') }
          set_if_empty :nextjs_config_path, -> { File.join(shared_path, 'config') }
        end

        def define_tasks
          eval_rakefile File.expand_path('../tasks/nextjs.rake', __FILE__)
        end

        def register_hooks
          after 'deploy:check', 'nextjs:reload'
          after 'deploy:published', 'nextjs:restart'
        end
      end
    end
  end
end
