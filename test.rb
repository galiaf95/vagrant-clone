require 'parser/current'

class VagrantfileManager
  def initialize(path_to_vagrantfile, new_images_by_nodes)
    buffer = Parser::Source::Buffer.new('(source)')
    buffer.source = File.read(path_to_vagrantfile)
    parser = Parser::CurrentRuby.new
    ast = parser.parse(buffer)
    rewriter = VmsRewriter.new(new_images_by_nodes)
    File.open("#{path_to_vagrantfile}_test", 'w') do |vagrantfile|
      vagrantfile.write rewriter.rewrite(buffer, ast)
    end
  end

  class VmsRewriter < Parser::Rewriter

    attr_accessor :vms

    def initialize(new_images_by_nodes)
      @vms = Hash.new
      @new_images_by_nodes = new_images_by_nodes
    end

    def process_all(node)
      get_vm_block(node)
      change_images
      super
    end

    def change_images
      @vms.each do |vm_name, node|
        change_image(node, @new_images_by_nodes[vm_name])
      end
    end

    def change_image(node, new_image_path)
      image_replaced = false
      if node.class == Parser::AST::Node
        node.children.each do |vm_block_child|
          if vm_block_child.class == Parser::AST::Node and vm_block_child.type == :begin
            vm_block_child.children.each do |first_send_child|
              if first_send_child.class == Parser::AST::Node and first_send_child.type == :send
                if first_send_child.children.size > 2 and first_send_child.children[1] == :image=
                  replace first_send_child.children[2].loc.expression, "'#{new_image_path}'"
                  image_replaced = true
                end
              end
            end
          end
          change_image vm_block_child, new_image_path unless image_replaced
        end
      end
    end

    def get_vm_block(node)
      if node.class == Parser::AST::Node
        lvar_config_found = false
        send_vm_found = false
        send_define_found = false
        str_provider = nil
        node.children.each do |vm_block_child|
          if vm_block_child.class == Parser::AST::Node and vm_block_child.type == :send
            vm_block_child.children.each do |first_send_child|
              if first_send_child.class == Parser::AST::Node
                if first_send_child.type == :send
                  first_send_child.children.each do |second_send_child|
                    if second_send_child.class == Parser::AST::Node and second_send_child.type == :lvar
                      if second_send_child.children[0] == :config
                        lvar_config_found = true
                      end
                    end
                    send_vm_found = true if second_send_child == :vm
                  end

                end
                if first_send_child.type == :str
                  str_provider = first_send_child.children[0]
                end
              end
              send_define_found = true if first_send_child == :define
            end
          end
          if lvar_config_found and send_vm_found and send_define_found and !str_provider.nil?
            @vms[str_provider] = node unless @vms.has_key? str_provider
          end
        end
      end
    end
  end
end

VagrantfileManager.new('/home/galiaf95/mdbci/DOCKER_TEST/Vagrantfile', {'galera_000'=>'test1', 'node_000'=>'test2'})