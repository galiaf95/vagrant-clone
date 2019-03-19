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
    class UnsupportedDockerVersion < VagrantClone::Errors::Error
      error_key('unsupported_docker_version')
    end
    class UnsupportedProvider < VagrantClone::Errors::Error
      error_key('unsupported_provider')
    end
    class NewEnvironmentDirectoryExists < VagrantClone::Errors::Error
      error_key('new_environment_exists')
      end
    class NewEnvironmentDirNotEmpty < VagrantClone::Errors::Error
      error_key('new_environment_directory_not_empty')
    end
    class InvalidCloneConfigOption < VagrantClone::Errors::Error
      error_key('invalid_clone_config_option')
    end
    class MultipleProvidersNotSupported < VagrantClone::Errors::Error
      error_key('multiple_providers_not_supported')
    end
    class VirtCloneCommandNotFound < VagrantClone::Errors::Error
      error_key('virt_clone_command_not_found')
    end
    class VirtCloneCommandFailed < VagrantClone::Errors::Error
      error_key('virt_clone_command_failed')
    end
    class SSHNotAccessible < VagrantClone::Errors::Error
      error_key('ssh_not_accessible')
    end
    class VagrantBoxAlreadyExists < VagrantClone::Errors::Error
      error_key('vagrant_box_already_exists')
    end
    class QemuImgCommandNotFound < VagrantClone::Errors::Error
      error_key('qemu_img_command_not_found')
    end
    class QemuImgCommandFailed < VagrantClone::Errors::Error
      error_key('qemu_img_command_failed')
    end
    class MachineStateNotAchieved < VagrantClone::Errors::Error
      error_key('machine_state_not_achieved')
      end
    class FailedToCreateNewImagesOrBoxes < VagrantClone::Errors::Error
      error_key('failed_to_create_new_images_or_boxes')
      end
    class TarNotInstalled < VagrantClone::Errors::Error
      error_key('tar_not_installed')
    end
  end
end