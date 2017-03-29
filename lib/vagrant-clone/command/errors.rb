module VagrantClone
  module Errors
    class Error < Vagrant::Errors::VagrantError
      error_namespace('vagrant-clone.errors')
    end
    class VmNotCreated < VagrantClone::Errors::Error
      error_key('vm_not_created')
    end
    class DockerCloningError < VagrantClone::Errors::Error
      error_key('docker_cloning_error')
    end
    class NotVagrantEnvironment < VagrantClone::Errors::Error
      error_key('not_vagrant_environment')
    end
  end
end