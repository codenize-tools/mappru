class Mappru::DSL::Context
  include Mappru::DSL::TemplateHelper

  def self.eval(dsl, path, options = {})
    self.new(path, options) {
      eval(dsl, binding, path)
    }
  end

  attr_reader :result

  def initialize(path, options = {}, &block)
    @path = path
    @options = options
    @result = {}

    @context = Hashie::Mash.new(
      :path => path,
      :options => options,
      :templates => {}
    )

    instance_eval(&block)
  end

  def template(name, &block)
    @context.templates[name.to_s] = block
  end

  private

  def require(file)
    rt = (file =~ %r|\A/|) ? file : File.expand_path(File.join(File.dirname(@path), file))

    if File.exist?(rt)
      instance_eval(File.read(rt), rt)
    elsif File.exist?(rt + '.rb')
      instance_eval(File.read(rt + '.rb'), rt + '.rb')
    else
      Kernel.require(file)
    end
  end

  def vpc(vpc_id, &block)
    vpc_id = vpc_id.to_s
    @result[vpc_id] ||= {}
    @result[vpc_id].update(Mappru::DSL::Context::VPC.new(@context, vpc_id, &block).result)
  end
end
