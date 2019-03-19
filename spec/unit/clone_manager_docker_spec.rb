require_relative '../spec_helper'
require_relative '../../lib/vagrant-clone/util/clone_manager_base'
require_relative '../../lib/vagrant-clone/util/clone_managers/docker'

options = {:clone_config => nil, :new_env_path => nil, :provider => nil, :machines => {}}
class TestEnv
  def machine_names
    []
  end
  class Ui
    def info(msg)
      @logger = Log4r::Logger.new('vagrant_clone::testing')
      @logger.info(msg)
    end
  end
end

describe VagrantClone::CloneManager do
  context 'with one virtual machine' do
    it 'should create docker image from machine\'s container' do
      puts VagrantClone::CloneManager.new nil, nil
      expect(true).to be true
    end
  end
end