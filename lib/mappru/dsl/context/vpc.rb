class Mappru::DSL::Context::VPC
  include Mappru::DSL::TemplateHelper

  def initialize(context, vpc_id, &block)
    @vpc_id = vpc_id
    @context = context.merge(vpc_id: vpc_id)
    @result = {}
    instance_eval(&block)
  end

  attr_reader :result

  private

  def route_table(name, &block)
    name = name.to_s

    if @result[name]
      raise "Route Table `#{name}` is already defined"
    end

    @result[name] = Mappru::DSL::Context::VPC::RouteTable.new(@context, @vpc_id, name, &block).result
  end
end
