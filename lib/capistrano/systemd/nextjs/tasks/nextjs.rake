# frozen_string_literal: true

namespace :nextjs do
  desc 'Reload nextjs'
  task :reload do
    on roles fetch(:nextjs_roles) do |role|
      switch_user(role) do
        each_process do |process_name|
          if fetch(:nextjs_service_unit_user) == :system
            execute :sudo, :systemctl, "reload", process_name, raise_on_non_zero_exit: false
          else
            execute :systemctl, "--user", "reload", process_name, raise_on_non_zero_exit: false
          end
        end
      end
    end
  end

  desc 'Restart nextjs'
  task :restart do
    on roles fetch(:nextjs_roles) do |role|
      switch_user(role) do
        each_process do |process_name|
          if fetch(:nextjs_service_unit_user) == :system
            execute :sudo, :systemctl, 'restart', process_name
          else
            execute :systemctl, '--user', 'restart', process_name
          end
        end
      end
    end
  end

  desc 'Stop nextjs'
  task :stop do
    on roles fetch(:nextjs_roles) do |role|
      switch_user(role) do
        each_process do |process_name|
          if fetch(:nextjs_service_unit_user) == :system
            execute :sudo, :systemctl, "stop", process_name
          else
            execute :systemctl, "--user", "stop", process_name
          end
        end
      end
    end
  end

  desc 'Start nextjs'
  task :start do
    on roles fetch(:nextjs_roles) do |role|
      switch_user(role) do
        each_process do |process_name|
          if fetch(:nextjs_service_unit_user) == :system
            execute :sudo, :systemctl, 'start', process_name
          else
            execute :systemctl, '--user', 'start', process_name
          end
        end
      end
    end
  end

  desc 'Install nextjs service'
  task :install do
    on roles fetch(:nextjs_roles) do |role|
      switch_user(role) do
        each_process do |process_name|
          create_systemd_template(process_name)

          if fetch(:nextjs_service_unit_user) == :system
            execute :sudo, :systemctl, "enable", process_name
          else
            execute :systemctl, "--user", "enable", process_name
            execute :loginctl, "enable-linger", fetch(:nextjs_lingering_user) if fetch(:nextjs_enable_lingering)
          end
        end
      end
    end
  end

  desc 'Uninstall nextjs service'
  task :uninstall do
    on roles fetch(:nextjs_roles) do |role|
      switch_user(role) do
        each_process do |process_name|
          if fetch(:nextjs_service_unit_user) == :system
            execute :sudo, :systemctl, "disable", process_name
          else
            execute :systemctl, "--user", "disable", process_name
          end

          execute :rm, '-f', File.join(fetch(:service_unit_path, fetch_systemd_unit_path), process_name)
        end
      end
    end
  end

  desc 'Generate systemd locally'
  task :generate_systemd_locally do
    run_locally do
      each_process do |process_name|
        File.write("tmp/#{process_name}.service", compiled_systemd_template(process_name))
      end
    end
  end
end
