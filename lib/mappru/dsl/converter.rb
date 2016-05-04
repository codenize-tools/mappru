class Mappru::DSL::Converter
  include Mappru::Utils::Helper

  def self.convert(exported, options = {})
    self.new(exported, options).convert
  end

  def initialize(exported, options = {})
    @exported = exported
    @options = options
  end

  def convert
    output_vpcs(@exported)
  end

  private

  def output_vpcs(rts_by_vpc)
    vpcs = []

    rts_by_vpc.sort_by(&:first).each do |vpc_id, rt_by_name|
      next unless matched?(vpc_id, @options[:vpc_id])

      vpcs << output_vpc(vpc_id, rt_by_name)
    end

    vpcs.join("\n")
  end

  def output_vpc(vpc_id, rt_by_name)
    route_tables = output_route_tables(rt_by_name).strip

    <<-EOS
vpc #{vpc_id.inspect} do
  #{route_tables}
end
    EOS
  end

  def output_route_tables(rt_by_name)
    route_tables = []

    rt_by_name.each do |name, rt|
      route_tables << output_route_table(name, rt)
    end

    route_tables.join("\n")
  end

  def output_route_table(name, rt)
    subnets = output_subnets(rt[:subnets]).strip
    routes = output_routes(rt[:routes]).strip

    <<-EOS
  route_table #{name.inspect} do
    #{subnets}
    #{routes}
  end
    EOS
  end

  def output_subnets(subnets)
    if subnets.empty?
      '#subnets ...'
    else
      args = subnets.map(&:inspect).join(', ')
      "subnets #{args}"
    end
  end

  def output_routes(routes)
    if routes.empty?
      '#routes destination_cidr_block: ...'
    else
      routes.map {|r|
        <<-EOS
    route #{r.without_nil.modern_inspect_without_brace}
        EOS
      }.join
    end
  end
end
