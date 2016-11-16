module VagrantClone
  class Plugin < Vagrant.plugin("2")
    name 'vagrant-clone'
    command 'clone' do
        require_relative 'vagrant-clone/command'
        Command
    end
  end
end