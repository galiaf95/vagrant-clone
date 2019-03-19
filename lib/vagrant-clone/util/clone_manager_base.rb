require 'fileutils'
require 'docker'

module VagrantClone
  class CloneManagerBase

    def initialize(clone_config, new_env_path, machines, provider, vagrant_env)
      @clone_config = clone_config
      @new_env_path = new_env_path
      @machines = machines
      @provider = provider
      @vagrant_env = vagrant_env
    end

    def create_image_or_box(machine)
      raise NotImplementedError
    end

    def update_clone_config
      config = {}
      @vagrant_env.machine_names.each do |name|
        if @clone_config.keys.include? name
          amount = @clone_config[name]
          unless @machines.has_key? name
            @vagrant_env.ui.error "Virtual machine '#{name}' must be brought up at least once!"
            raise VagrantClone::Errors::VmNotCreated
          end
          config[name] = {
              :box_or_image => create_image_or_box(@machines[name]),
              :amount => amount <= 0 ? 0 : amount
          }
        else
          config[name] = {
              :box_or_image => nil,
              :amount => 0
          }
        end
      end
      @clone_config = config
      @vagrant_env.ui.info "Clone config updated: #{config}"
    end

    def create_new_env_dir
      if @new_env_path.nil?
        cur_env_path = Pathname.new File.expand_path @vagrant_env.cwd
        cur_env_name = cur_env_path.basename
        @new_env_path = cur_env_path.dirname.join "#{cur_env_name}_#{Time.new.to_i}"
      end
      @vagrant_env.ui.info "Creating new Vagrant environment in: #{@new_env_path}..."
      Dir.mkdir @new_env_path
    end

    def create_clones
      update_clone_config
      create_new_env_dir
      case @provider
        when :docker
          require_relative '../util/vagrantfile_managers/docker'
        when :libvirt
          require_relative '../util/vagrantfile_managers/libvirt'
        else
          raise VagrantClone::Errors::UnsupportedProvider
      end
      vagrantfile_manager = VagrantClone::VagrantfileManager.new @clone_config, @new_env_path, @vagrant_env
      vagrantfile_manager.rewrite
    end

  end
end