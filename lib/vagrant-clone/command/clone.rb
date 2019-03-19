require 'json'
require 'docker'

module VagrantClone
  class Clone < Vagrant.plugin('2', 'command')
    CLONE_CON_OPT_DESC = 'Json string, that specifies how many clones of each machine to make or skip. ' +
        'Example: vagrant clone \'{"machine1":1,"machine2":3,...}\'. ' +
        'If machine exists in current config, but is not mentioned in clone config, then it will have 0 copies.'

    def self.synopsis
      'clone virtual machines into new Vagrant environment'
    end

    def parse_options
      options = {:clone_config => nil, :new_env_path => nil}
      option_parser = OptionParser.new do |o|
        o.banner = 'Usage: vagrant clone -c CLONE_CONFIG [-n NEW_VAGRANT_ENVIRONMENT_PATH] [-h]'
        o.on('-c', '--clone-config CLONE_CONFIG', CLONE_CON_OPT_DESC) do |op|
          begin
            options[:clone_config] = JSON.parse op
            options[:clone_config] = Hash[options[:clone_config].map {|k, v| [k.to_sym, v]}]
          rescue Exception => e
            @env.ui.error e.message
            raise VagrantClone::Errors::InvalidCloneConfigOption
          end
          options[:clone_config].each_key do |key|
            unless @env.machine_names.include? key
              @env.ui.error "Machine #{key} does not exists in current Vagrant environment, check clone config..."
              raise VagrantClone::Errors::InvalidCloneConfigOption
            end
          end
        end
        o.on('-n', '--new-env-path NEW_VAGRANT_ENVIRONMENT_PATH', 'Path where to clone Vagrant environment') do |op|
          raise VagrantClone::Errors::NewEnvironmentDirectoryExists if Dir.exist? op
          raise VagrantClone::Errors::NewEnvironmentDirNotEmpty unless Dir.glob(Pathname.new(op).join('**/*')).empty?
          options[:new_env_path] = op
        end
        o.on_tail('-h', '--help', 'Show this message') do
          @env.ui.info o
          exit
        end
      end
      option_parser.parse!
      if options[:clone_config].nil?
        @env.ui.error option_parser.help
        raise OptionParser::MissingArgument
      end
      @env.ui.info "Received args: #{options}"
      return options[:clone_config], options[:new_env_path]
    end

    def get_machines_and_provider(vagrant_env)
      machines = {}
      providers = []
      vagrant_env.machine_index.each do |entry|
        if vagrant_env.machine_names.include? entry.name.to_sym and vagrant_env.local_data_path == entry.local_data_path
          machine = vagrant_env.machine entry.name.to_sym, entry.provider.to_sym
          machines[entry.name.to_sym] = machine
          providers << entry.provider.to_sym
        end
      end
      raise VagrantClone::Errors::MultipleProvidersNotSupported if providers.uniq.length > 1
      return machines, providers.uniq[0]
    end

    def execute
      clone_config, new_env_path = parse_options
      machines, provider = get_machines_and_provider @env
      require_relative '../util/clone_manager_base'
      case provider
        when :docker
          require_relative '../util/clone_managers/docker'
        when :libvirt
          require_relative '../util/clone_managers/libvirt'
        else
          raise VagrantClone::Errors::UnsupportedProvider
      end
      clone_manager = VagrantClone::CloneManager.new clone_config, new_env_path, machines, provider, @env
      clone_manager.create_clones
    end
  end
end