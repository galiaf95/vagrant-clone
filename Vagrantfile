Vagrant.configure(2) do |config|
  config.vm.define 'node_000' do |node_000|
    node_000.vm.provider 'docker' do |d|
      d.image = '<CONTAINER_ID>'
      d.privileged = true
      d.has_ssh = true
    end
  end
end
