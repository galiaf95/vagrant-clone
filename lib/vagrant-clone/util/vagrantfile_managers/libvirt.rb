require 'parser/current'
require 'unparser'
require 'pathname'

module VagrantClone
  class VagrantfileManager

    VAGRANTFILE_NAME = 'Vagrantfile'

    def initialize(clone_config, new_env_path, vagrant_env)
      @clone_config = clone_config
      @new_env_path = new_env_path
      @vagrant_env = vagrant_env
    end

    def rewrite
      buffer = Parser::Source::Buffer.new(VAGRANTFILE_NAME)
      buffer.source = File.read(Pathname.new(@vagrant_env.cwd).join(VAGRANTFILE_NAME))
      parser = Parser::CurrentRuby.new
      ast = parser.parse(buffer)
      rewriter = VagrantfileRewriter.new(@clone_config, @vagrant_env)
      File.open(Pathname.new(@new_env_path).join(VAGRANTFILE_NAME), 'w') do |vagrantfile|
        vagrantfile.write rewriter.rewrite(buffer, ast)
      end
    end

    class VagrantfileRewriter < Parser::Rewriter
      def initialize(clone_config, vagrant_env)
        @vagrant_env = vagrant_env
        @blocks = {}
        @vms = {}
        @clone_config = clone_config
        @checked_nodes = []
      end

      def on_block(node)
        super
        get_vm_block(node)
      end

      def change_image(vm_name, node, image_path_or_id)
        if node.class == Parser::AST::Node
          node.children.each do |vm_block_child|
            if vm_block_child.class == Parser::AST::Node and vm_block_child.type == :send
              if vm_block_child.children.size >= 2 and vm_block_child.children[1] == :box=
                if @vms[vm_name].nil? or !@vms[vm_name].include? vm_block_child
                  @vagrant_env.ui.info "Replacing image for '#{vm_name}' with '#{image_path_or_id}'..."
                  replace(
                      vm_block_child.children[2].loc.expression,
                      "\"#{image_path_or_id}\""
                  )
                  @vagrant_env.ui.info "Done replacing image for '#{vm_name}' with '#{image_path_or_id}'..."
                  if @vms[vm_name].nil?
                    @vms[vm_name] = [vm_block_child]
                  else
                    @vms[vm_name] << vm_block_child
                  end
                end
              end
            end
            change_image vm_name, vm_block_child, image_path_or_id
          end
        end
      end

      def get_vm_block(node)
        if node.class == Parser::AST::Node
          send_vm_found = false
          send_define_found = false
          node.children.each do |vm_block_child|
            if vm_block_child.class == Parser::AST::Node and vm_block_child.type == :send
              vm_block_child.children.each do |first_send_child|
                if first_send_child.class == Parser::AST::Node
                  if first_send_child.type == :send
                    first_send_child.children.each do |second_send_child|
                      send_vm_found = true if second_send_child == :vm
                    end
                  end
                  if first_send_child.type == :str or first_send_child.type == :sym and
                      send_define_found and send_vm_found
                    str_provider = first_send_child.children[0]
                    send_vm_found = false
                    send_define_found = false
                    if not @blocks.keys.include? str_provider and @clone_config.has_key? str_provider.to_sym
                      if @clone_config[str_provider.to_sym][:amount] <= 0
                        @vagrant_env.ui.info "Amount of clones for '#{str_provider}' is 0, excluding from config..."
                        insert_before node.loc.expression, "if false\n"
                      else
                        @vagrant_env.ui.info "Updating config with clones for '#{str_provider}'..."
                        var_name = "i_#{Time.new.to_i}"
                        amount = @clone_config[str_provider.to_sym][:amount]
                        machine_name = Unparser.unparse node.children[0].children[2]
                        box_name = @clone_config[str_provider.to_sym][:box_or_image]
                        insert_before node.loc.expression, "(0...#{amount}).each do |#{var_name}|\n"
                        replace node.children[0].children[2].loc.expression, %Q["\#{#{machine_name}}_\#{#{var_name}}"]
                        change_image(str_provider, node, box_name)
                      end
                      insert_after node.loc.expression, "\nend"
                      @blocks[str_provider] = node
                    end
                  end
                end
                send_define_found = true if first_send_child == :define
              end
            end
          end
        end
      end
    end
  end
end

=begin
class Dummy
  attr_accessor :ui

  def initialize
    @ui = Ui.new
  end

  def cwd
    '/home/galiaf95/bachelors/product/vagrant-clone/LibvirtTest'
  end

  def vagrantfile_name
    'Vagrantfile'
  end

  class Ui
    def info(msg)
      puts msg
    end
  end
end


timestamp = Time.new.to_i
new_env_path = Pathname.new("/home/galiaf95/bachelors/product/vagrant-clone/LibvirtTest#{timestamp}")
clone_config = {
    :node0 => {
        :box_or_image => nil,
        :amount => 0
    },
    :node1 => {
        :box_or_image => "test",
        :amount => 2
    },
    :node2 => {
        :box_or_image => nil,
        :amount => 0
    }
}
Dir.mkdir new_env_path
VagrantClone::VagrantfileManager.new(
    clone_config,
    new_env_path,
    Dummy.new
).rewrite
=end