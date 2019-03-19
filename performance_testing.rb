#! /home/galiaf95/.rvm/rubies/ruby-2.0.0-p648/bin/ruby

require 'fileutils'


def single_tests
  results = {
	  :docker => {
	  	1 => {
	  	  :scratch => 1.8833333333333333, 
	  	  :clone => 0.48333333333333334
	  	}, 
	  	2 => {
	  	  :scratch=>1.9333333333333333, 
	  	  :clone=>0.6666666666666666
	  	}, 
	  	3 => {
	  	  :scratch=>2.2, 
	  	  :clone=>0.9166666666666667
	  	}, 
	  	4 => {
	  	  :scratch=>2.683333333333333, 
	  	  :clone=>1.2166666666666668
	  	}, 
	  	5 => {
	  	  :scratch=>3.183333333333333, 
	  	  :clone=>1.5666666666666669
	  	}
	  },
	  :libvirt => {
	  	1 => {
	  	  :scratch => 6.7, 
	  	  :clone=>1.76666666666667
	  	}, 
	  	2 => {
	  	  :scratch=>12.3, 
	  	  :clone=>1.9
	  	}, 
	  	3 => {
	  	  :scratch=>18.2, 
	  	  :clone=>2.15
	  	},
	  	4 => {
	  	  :scratch=>28.2166666667, 
	  	  :clone=>3.35
	  	}, 
	  	5 => {
	  	  :scratch=>34.61666666666667, 
	  	  :clone=>3.583333333333333
	  	},
	  	6 => {
	  	  :scratch => 41.416666666666664, 
	  	  :clone => 3.5166666666666666
	  	}
	  }
  }
  results_file = '/home/galiaf95/bachelors/product/vagrant-clone/results.txt'
  libvirt_results = '/home/galiaf95/bachelors/product/vagrant-clone/libvirt.txt'
#:libvirt => 'LibvirtTest',
  {:docker => 'DockerTest'}.each do |provider, dir|
    (5..14).each do |step|
      results[provider][step + 1] = {}
      Dir.chdir File.expand_path dir do
        #system 'vagrant', 'destroy', '-f'
        up_arguments = []
        (0..step).each do |i|
          up_arguments << "node#{i}"
        end
        start_time = Time.now.to_i
        system 'vagrant', 'up', '--no-parallel', '--provider', "#{provider}", *up_arguments
        diff_time = (Time.now.to_i - start_time).to_f/60.to_f
	    File.open libvirt_results, 'a' do |file|
	      file.puts "#{step + 1} => #{diff_time}"
	    end
        results[provider][step + 1][:scratch] = diff_time + results[provider][step][:scratch]
        clone_config = []
        (0..step).each do |i|
          clone_config << %Q("node#{i}":1)
        end
        clone_config = clone_config.join ','
        clone_config = "{#{clone_config}}"
        start_time = Time.now.to_i
        begin
          system 'vagrant', 'clone', '-c', clone_config, '-n', "../#{dir}_#{step}"
          diff_time = (Time.now.to_i - start_time).to_f/60.to_f
          results[provider][step + 1][:clone] = diff_time
          Dir.chdir File.expand_path "../#{dir}_#{step}" do |dir|
            up_arguments = []
            (0..step).each do |i|
              up_arguments << "node#{i}_0"
            end
            start_time = Time.now.to_i
            begin
              system 'vagrant', 'up', '--no-parallel', '--provider', "#{provider}", *up_arguments
              diff_time = (Time.now.to_i - start_time).to_f/60.to_f
              results[provider][step + 1][:clone] += diff_time
            ensure
              system 'vagrant', 'destroy', '-f'
            end
          end
        ensure
          File.open results_file, 'a' do |file|
            file.puts results
          end
          system "for i in `docker images | grep none | awk '{print $3}'`; do docker rmi $i; done"
          system "for i in `vagrant box list | grep VAGRANTBOX | awk '{print $1}'`; do vagrant box remove $i; done"
          system "for i in `virsh vol-list --pool default | grep VAGRANTBOX | awk '{print $1}'`; do virsh vol-delete $i --pool default; done"
          FileUtils.rm_r File.expand_path "../#{dir}_#{step}" if Dir.exist? File.expand_path "../#{dir}_#{step}"
        end
      end
    end
  end
  puts results
end

def scale_tests
  results = {
      :docker => {},
      :libvirt => {}
  }
  results_file = '/home/galiaf95/bachelors/product/vagrant-clone/results.txt'
#, :libvirt => 'LibvirtTest'
  {:docker => 'DockerTest'}.each do |provider, dir|
    10.times.each do |step|
      results[provider][step + 1] = {}
      Dir.chdir File.expand_path dir do
        #system 'vagrant', 'destroy', '-f'
        up_arguments = ['node0']
        up_arguments << '--no-parallel' if provider == :libvirt
        start_time = Time.now.to_i
        system 'vagrant', 'up', '--provider', "#{provider}", *up_arguments
        clone_config = %Q({"node0":#{step+1}})
        begin
          system 'vagrant', 'clone', '-c', clone_config, '-n', "../#{dir}_#{step}"
          Dir.chdir File.expand_path "../#{dir}_#{step}" do |dir|
            up_arguments = []
            (0..step).each do |i|
              up_arguments << "node0_#{i}"
            end
            begin
              up_arguments << '--no-parallel' if provider == :libvirt
              system 'vagrant', 'up', '--provider', "#{provider}", *up_arguments
              diff_time = (Time.now.to_i - start_time).to_f/60.to_f
              #orig_time = provider == :docker ? 1.88333333333333 : 6.7
              results[provider][step + 1]["#{step+1}_clones"] = diff_time
            ensure
              system 'vagrant', 'destroy', '-f'
            end
          end
        ensure
          File.open results_file, 'a' do |file|
            file.puts results
          end
          system "for i in `docker images | grep none | awk '{print $3}'`; do docker rmi $i; done"
          system "for i in `vagrant box list | grep VAGRANTBOX | awk '{print $1}'`; do vagrant box remove $i; done"
          system "for i in `virsh vol-list --pool default | grep VAGRANTBOX | awk '{print $1}'`; do virsh vol-delete $i --pool default; done"
          FileUtils.rm_r File.expand_path "../#{dir}_#{step}" if Dir.exist? File.expand_path "../#{dir}_#{step}"
        end
      end
    end
  end
  puts results
end

scale_tests