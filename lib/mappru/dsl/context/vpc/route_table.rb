class Mappru::DSL::Context::VPC::RouteTable
  include Mappru::DSL::TemplateHelper

  def initialize(context, vpc_id, name, &block)
    @vpc_id = vpc_id
    @name = name
    @context = context.merge(vpc_id: vpc_id, name: name)
    @result = {subnets: [], routes: []}
    instance_eval(&block)
  end

  attr_reader :result

  private

  def subnets(*subnet_ids)
    if subnet_ids.empty?
      raise "VPC `#{@vpc_id}` > Route Table `#{@name}`: Subnet Id is empty"
    end

    @result[:subnets].concat(subnet_ids.map(&:to_s))
  end

  def route(attributes)
    unless attributes.is_a?(Hash)
      raise "VPC `#{@vpc_id}` > Route Table `#{@name}`: Invalid route #{attributes.inspect}:#{attributes.class}"
    end

    @result[:routes] << attributes
  end
end
