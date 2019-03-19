require 'fileutils'
require 'pathname'
require 'libvirt'
require 'nokogiri'
require 'json'
require 'net/ssh'
require 'timeout'
require 'tmpdir'
require 'shellwords'

module VagrantClone
  class CloneManager < CloneManagerBase

    # This key will be in names ob boxes and
    # libvirt images for ease of removing
    VAGRANT_BOX_TAG = 'VAGRANTBOX'

    VAGRANT_DEFAULT_PUBLIC_KEY = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key'
    METADATA_JSON = <<EOF
{
    "provider": "libvirt",
    "format": "qcow2",
    "virtual_size": 300
}
EOF

    VAGRANTFILE = <<EOF
Vagrant.configure("2") do |config|
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.host = ""
    libvirt.connect_via_ssh = false
    libvirt.storage_pool_name = "default"
  end
end
EOF

    def add_default_vagrant_public_key(machine)
      machine.action 'up', {:destroy_on_error => false, :provision => false, :provider => :libvirt}
      host=machine.ssh_info[:host]
      port=machine.ssh_info[:port]
      user=machine.ssh_info[:username]
      private_key_paths=machine.ssh_info[:private_key_path]
      puts host, port, user, private_key_paths
      Net::SSH.start(host, user, :port => port, :keys => private_key_paths, :paranoid => Net::SSH::Verifiers::Null.new) do |ssh|
        ssh.exec! "echo '#{VAGRANT_DEFAULT_PUBLIC_KEY}' >> $HOME/.ssh/authorized_keys"
      end
    end

    def create_vagrant_box(machine, vagrant_box_name, vagrant_box_version)
      conn = Libvirt::open('qemu:///system')
      domain = conn.lookup_domain_by_uuid machine.id
      domain_xml_desc = Nokogiri::XML domain.xml_desc
      domain_image_path = domain_xml_desc.xpath('//domain//devices//disk//source//@file')[0].content
      Dir.mktmpdir do |dir|
        new_image_name = "#{vagrant_box_name}_vagrant_box_image_#{vagrant_box_version}"
        path_to_new_image = Pathname.new(dir).join "#{new_image_name}.img"
        system "sudo chmod 644 #{Shellwords.escape domain_image_path}"
        system "qemu-img create -f qcow2 -b '#{domain_image_path}' '#{path_to_new_image}'"
        system "sudo chmod 600 #{Shellwords.escape domain_image_path}"
        pool = conn.lookup_storage_pool_by_name 'default'
        pool_vol_xml = <<EOF
<volume>
  <name>#{vagrant_box_name}_vagrant_box_image_#{vagrant_box_version}.img</name>
  <allocation>0</allocation>
  <capacity unit="G">40</capacity>
</volume>
EOF
        volume = pool.create_volume_xml(pool_vol_xml)
        stream = conn.stream
        image_file = File.open(path_to_new_image, 'rb')
        volume.upload(stream, 0, image_file.size)
        stream.sendall do |_opaque, n|
          begin
            r = image_file.read(n)
            r ? [r.length, r] : [0, '']
          rescue Exception => e
            @vagrant_env.ui.error "Got exception #{e}"
            [-1, '']
          end
        end
        stream.finish
        path_to_vagrant_box = Pathname.new(dir).join "#{new_image_name}.box"
        path_to_vagrant_box_image = Pathname.new(dir).join 'box.img'
        path_to_metadata = Pathname.new(dir).join 'metadata.json'
        path_to_vagrantfile = Pathname.new(dir).join 'Vagrantfile'
        FileUtils.mv path_to_new_image, path_to_vagrant_box_image
        File.open(path_to_metadata, 'w') {|file| file.write METADATA_JSON}
        File.open(path_to_vagrantfile, 'w') {|file| file.write VAGRANTFILE}
        raise VagrantClone::Errors::TarNotInstalled unless system 'which tar'
        Dir.chdir(dir){
          system 'tar', 'cvzf', "#{path_to_vagrant_box}", '-S' ,'--totals', './metadata.json', './Vagrantfile', './box.img'
        }
        box_collection = Vagrant::BoxCollection.new(@vagrant_env.boxes_path)
        box_collection.add path_to_vagrant_box, vagrant_box_name, vagrant_box_version

      end
    end

    def create_image_or_box(machine)
      add_default_vagrant_public_key(machine)
      machine.action 'halt', {:destroy_on_error => false, :provision => false, :provider => :docker}
      box_name = "#{machine.name}_#{VAGRANT_BOX_TAG}_#{Time.new.to_i}"
      create_vagrant_box(machine, box_name, '0')
      box_name
    end
  end
end


=begin
module VagrantClone
  class CloneManager #< CloneManagerBase

    VAGRANT_DEFAULT_PUBLIC_KEY = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key'

    # Use this variable like: METADATA_JSON % [SIZE]
    METADATA_JSON = <<EOF
{
    "provider": "libvirt",
    "format": "qcow2",
    "virtual_size": %s
}
EOF

    VAGRANTFILE = <<EOF
Vagrant.configure("2") do |config|
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.host = ""
    libvirt.connect_via_ssh = false
    libvirt.storage_pool_name = "default"
  end
end
EOF

    def wait_domain_state(domain, state, duration)
      begin
        Timeout::timeout(duration) {
          sleep 1 until domain.state[0] == state
        }
      rescue Timeout::Error
        raise VagrantClone::Errors::MachineStateNotAchieved
      end
    end

    # Cloned image contain public key from original machine
    # Vagrant can not start ssh session because virtual machine
    # does not have default Vagrant public key
    # SSH new machine with previous private key
    # wait 10 seconds for ssh to available
    # if SSH available - add default Vagrant public key to authorized keys
    def add_default_vagrant_public_key(machine_uuid, host, port, user, private_key_path)
      conn = Libvirt::open('qemu:///system')
      domain = conn.lookup_domain_by_uuid machine_uuid
      domain.create unless domain.state[0] == Libvirt::Domain::RUNNING
      wait_domain_state domain, Libvirt::Domain::RUNNING, 10
      timeout = 10
      while timeout > 0
        begin
          Net::SSH.start(host, user, :port => port, :keys => [private_key_path]) do |ssh|
            ssh.exec! "echo '#{VAGRANT_DEFAULT_PUBLIC_KEY}' >> $HOME/.ssh/authorized_keys"
          end
          break
        rescue Exception => e
          puts e.message
          timeout -= 1
          sleep 1
        end
      end
      raise VagrantClone::Errors::SSHNotAccessible if timeout == 0
    end

    # Clone domain
    # undefine cloned domain
    # Returns path to cloned image
    def create_clone(machine_uuid, vagrant_box_name, vagrant_box_version)
      conn = Libvirt::open('qemu:///system')
      domain = conn.lookup_domain_by_uuid machine_uuid
      domain_xml_desc = Nokogiri::XML domain.xml_desc
      domain_name = domain_xml_desc.xpath('//domain//name')[0].children[0].content
      raise VagrantClone::Errors::VirtCloneCommandNotFound unless system('which virt-clone')
      domain.suspend if domain.active?
      wait_domain_state domain, Libvirt::Domain::PAUSED, 10
      clone_name = "#{vagrant_box_name}_vagrant_box_image_#{vagrant_box_version}"
      unless system('virt-clone', '-o', domain_name, '-n', clone_name, '--auto-clone', out: $stdout, err: $stderr)
        raise VagrantClone::Errors::VirtCloneCommandFailed
      end
      domain.resume
      wait_domain_state domain, Libvirt::Domain::RUNNING, 10
      cloned_domain = conn.lookup_domain_by_name clone_name
      cloned_domain_xml_desc = Nokogiri::XML cloned_domain.xml_desc
      cloned_domain_xml_desc.xpath('//domain//devices//disk//source//@file')[0].content
    end

    # Create new Vagrant box directory
    # create metadata.json in Vagrant box directory
    # create Vagrantfile in Vagrant box directory
    # copy libvirt image to Vagrant box directory
    # remove original cloned image
    # returns Vagrant box name
    def create_vagrant_box(path_to_cloned_image, vagrant_box_name, vagrant_box_version, vagrant_boxes_dir)
      new_vagrant_box_dir = Pathname.new(vagrant_boxes_dir).join(vagrant_box_name)
      VagrantClone::Errors::VagrantBoxAlreadyExists if Dir.exists? new_vagrant_box_dir
      new_vagrant_box_content_dir = new_vagrant_box_dir.join(vagrant_box_version).join('libvirt')
      FileUtils.mkdir_p new_vagrant_box_content_dir
      raise VagrantClone::Errors::QemuImgCommandNotFound unless system('which qemu-img')
      qemu_img_info = `qemu-img info --output=json '#{path_to_cloned_image}'`
      raise VagrantClone::Errors::QemuImgCommandFailed unless $?.success?
      qemu_img_info_json = JSON.parse qemu_img_info
      image_virtual_size = qemu_img_info_json['virtual-size'].to_i / (1024**3)
      File.open(new_vagrant_box_content_dir.join('metadata.json'), 'w') do |file|
        file.write METADATA_JSON % [image_virtual_size]
      end
      File.open(new_vagrant_box_content_dir.join('Vagrantfile'), 'w') do |file|
        file.write VAGRANTFILE
      end
      new_vagrant_box_image_path = new_vagrant_box_content_dir.join('box.img')
      FileUtils.ln_s File.expand_path(path_to_cloned_image), File.expand_path(new_vagrant_box_image_path)
      vagrant_box_name
    end

  end
end

def func1
  vc = VagrantClone::CloneManager.new
  puts 'HERE 1111111111111111111111'
  #vc.add_default_vagrant_public_key '5b30d071-8a8a-4855-b59d-c3ac82a7e7fb', '192.168.121.39', 22, 'vagrant', '/home/galiaf95/bachelors/product/vagrant-clone/LibvirtTest/.vagrant/machines/node0/libvirt/private_key'
  puts 'HERE 2222222222222222222222'
  path_to_cloned_image = vc.create_clone '5b30d071-8a8a-4855-b59d-c3ac82a7e7fb', 'test0', '0.0.1'
  puts 'HERE 3333333333333333333333'
  vc.create_vagrant_box path_to_cloned_image, 'test0', '0.0.1', '/home/galiaf95/.vagrant.d/boxes/'
end

def func2
  vc = VagrantClone::CloneManager.new
  puts 'HERE 1111111111111111111111'
  #vc.add_default_vagrant_public_key '6e47ca84-9ed4-45e7-aeed-be15dc3b876d', '192.168.121.142', 22, 'vagrant', '/home/galiaf95/bachelors/product/vagrant-clone/LibvirtTest/.vagrant/machines/node1/libvirt/private_key'
  puts 'HERE 2222222222222222222222'
  path_to_cloned_image = vc.create_clone '6e47ca84-9ed4-45e7-aeed-be15dc3b876d', 'test1', '0.0.1'
  puts 'HERE 3333333333333333333333'
  vc.create_vagrant_box path_to_cloned_image, 'test1', '0.0.1', '/home/galiaf95/.vagrant.d/boxes/'
end

#puts "Started At #{Time.now}"
#func1
#func2
#t1 = Thread.new{func1}
#t2 = Thread.new{func2}
#t1.join
#t2.join
#puts "End at #{Time.now}"
=end