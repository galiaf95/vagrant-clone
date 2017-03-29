require_relative '../../utils/vagrantfile_manager'
require 'fileutils'

module VagrantClone
  class Docker
    def initialize(options, env)
      env.ui.info "making clone of VM: #{options[:origin_id]} to image #{options[:cloned_image_name]}"
      `docker commit -p #{options[:origin_id]} #{options[:cloned_image_name]}`
      raise VagrantClone::Errors::DockerCloningError if $?.exitstatus != 0
      env.ui.info "clone of VM: #{options[:origin_id]} to image #{options[:cloned_image_name]} created successfully"
    end
  end
end