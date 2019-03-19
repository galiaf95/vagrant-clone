require 'docker'
require 'net/ssh'

module VagrantClone
  class CloneManager < CloneManagerBase

    VAGRANT_DEFAULT_PUBLIC_KEY = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key'

    def add_default_vagrant_public_key(machine)
      machine.action 'up', {:destroy_on_error => false, :provision => false, :provider => :docker}
      host=machine.ssh_info[:host]
      port=machine.ssh_info[:port]
      user=machine.ssh_info[:username]
      private_key_paths=machine.ssh_info[:private_key_path]
      @vagrant_env.ui.info "Inserting default vagrant key via ssh to: #{machine.name}..."
      Net::SSH.start(host, user, :port => port, :keys => private_key_paths, :paranoid => Net::SSH::Verifiers::Null.new) do |ssh|
        ssh.exec! "echo '#{VAGRANT_DEFAULT_PUBLIC_KEY}' >> $HOME/.ssh/authorized_keys"
      end
    end

    def create_image_or_box(machine)
      add_default_vagrant_public_key(machine)
      machine.action 'halt', {:destroy_on_error => false, :provision => false, :provider => :docker}
      container = Docker::Container.get machine.id
      @vagrant_env.ui.info "Creating machine image from container via commit from: #{machine.name}..."
      image = container.commit
      @vagrant_env.ui.info "Created image id is: #{image.id}..."
      image.id
    end
  end
end