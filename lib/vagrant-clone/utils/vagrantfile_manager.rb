module VagrantClone
  class VagrantfileManager

    VAGRANT_TEMPLATE = <<-HEREDOC
    Vagrant.configure("2") do |config|
    %s
    end
    HEREDOC

    VAGRANT_BLOCK_DOCKER_TEMPLATE = <<-HEREDOC
      config.vm.define '%s' do |machine|
        machine.vm.provider 'docker' do |docker|
          docker.image = '%s'
        end
      end

    HEREDOC

    def initialize(options, env)
      @current_vagrant_env_path = options[:current_vagrant_env_path]
      @new_vagrant_env_path = options[:new_vagrant_env_path]
      @vagrantfile_name = options[:vagrantfile_name]
      @provider = options[:provider]
      @env = env
      generate_vagrantfile options[:vms_data]
    end

    def generate_vagrantfile_block(vm_data)
      VAGRANT_BLOCK_DOCKER_TEMPLATE % [vm_data[:cloned_name], vm_data[:cloned_image_name]]
    end

    def generate_vagrantfile(vms_data)
      @env.ui.info "generating Vagrantfile in #{@new_vagrant_env_path}"
      blocks = String.new
      vms_data.each do |vm_data|
        blocks = blocks + generate_vagrantfile_block(vm_data)
      end
      vagrantfile = VAGRANT_TEMPLATE % [blocks]
      File.open("#{@new_vagrant_env_path}/#{@vagrantfile_name}", 'w+') do |f|
        f.write vagrantfile
      end
    end

    def extract_configs
    end
  end
end