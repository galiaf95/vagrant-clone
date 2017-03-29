# -*- encoding: utf-8 -*-
# vim: set fileencoding=utf-8

require "vagrant"

module VagrantClone
  class Plugin < Vagrant.plugin("2")

    name 'vagrant-clone'

    command 'clone' do
      require_relative 'vagrant-clone/command/clone'
      Command
    end

  end
end