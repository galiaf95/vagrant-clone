require_relative '../command/errors'
require_relative '../utils/vagrantfile_manager'
require_relative 'provider/docker'

require 'optparse'

module VagrantClone
  class Command < Vagrant.plugin("2", "command")

    def initialize(argv, env)
      super
      @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
    end

    def execute
      options = {}
      opts = OptionParser.new do |o|
        o.banner = 'Usage: vagrant clone origin [options] [-h]'
        o.on('-n PATH_TO_NEW_VAGRANT_ENVIRONMENT', '--new-vagrant-env-path', 'Where to create new Vagrantfile') do |c|
          options[:new_vagrant_env_path] = c
        end
        o.on('-h', '--help', 'Help') do |c|
          @env.ui.info(opts.help, :prefix => false)
          exit
        end
      end
      argv = parse_options(opts)
      timestamp = Time.new.to_i
      options[:vagrantfile_name] = 'Vagrantfile'
      options[:current_vagrant_env_path] = Dir.pwd
      unless File.exists?("#{options[:current_vagrant_env_path]}/#{options[:vagrantfile_name]}")
        raise VagrantClone::Errors::NotVagrantEnvironment
      end
      unless options[:new_vagrant_env_path]
        options[:new_vagrant_env_path] = File.expand_path("#{Dir.pwd}/../#{File.basename options[:current_vagrant_env_path]}_#{timestamp}")
        FileUtils.mkdir options[:new_vagrant_env_path]
      end
      all_machines = Array.new
      current_vagrantfile = File.read("#{options[:current_vagrant_env_path]}/#{options[:vagrantfile_name]}")
      if argv.empty?
        if current_vagrantfile.match('config.vm.define')
          current_vagrantfile.split("\n").each do |line|
            match = line.match(/config\.vm\.define\s+([^\s]+)\s+/)
            if match
              all_machines.push match.captures[0].gsub("\"", '').gsub("'", '')
            end
          end
        else
          all_machines.push 'default'
        end
      else
        all_machines.push argv
      end
      all_machines.uniq!
      options[:vms_data] = Array.new
      # Checking all machines to be alive
      all_machines.each do |specific_machine|
        with_target_vms(specific_machine) do |machine|
          raise VagrantClone::Errors::VmNotCreated if machine.state.id == :not_created
        end
      end
      all_machines.each do |specific_machine|
        with_target_vms(specific_machine) do |machine|
          vm_data = {
              :cloned_name => "#{machine.name}",
              :cloned_image_name => "#{machine.name}_#{timestamp}",
              :origin_id => machine.id,
              :provider => machine.provider
          }
          options[:vms_data].push (vm_data)
          Docker.new(vm_data, @env) if /Docker/.match(machine.provider.to_s)
        end
      end
      VagrantfileManager.new(options, @env)
    end
  end
end