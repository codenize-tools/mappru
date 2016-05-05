class Mappru::Exporter
  include Mappru::Logger::Helper
  include Mappru::Utils::Helper

  def self.export(client, options = {})
    self.new(client, options).export
  end

  def initialize(client, options = {})
    @client = client
    @resource = Aws::EC2::Resource.new(client: @client)
    @options = options
  end

  def export
    result = {}
    @resource

    route_tables = @resource.route_tables

    route_tables.each do |rt|
      vpc_id = rt.vpc_id
      name_tag = rt.tags.find {|i| i.key == 'Name' } || {}
      name = name_tag[:value]

      next unless matched?(vpc_id, @options[:vpc_id])

      unless name
        log(:warn, "Cannot manage the nameless Route Table: #{vpc_id}", color: :yellow)
        next
      end

      next unless matched?(name, @options[:rt_name])

      result[vpc_id] ||= {}

      if result[vpc_id][name]
        raise "Duplication Subnet found: #{vpc_id}: #{name}"
      end

      result[vpc_id][name] = export_route_table(rt)
    end

    result
  end

  private

  def export_route_table(rt)
    result = {
      route_table_id: rt.id,
      routes: [],
      subnets: export_subnets(rt.associations),
    }

    # route -> (Array<Route>, nil)
    # http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/RouteTable.html#routes-instance_method
    rt.routes.reject(&:nil?).each {|route|
      # Skip "local"
      next if route.gateway_id == 'local'

      hash = {}

      [
        :destination_cidr_block,
        # TODO: Support Endpoint
        #:destination_prefix_list_id,
        :gateway_id,
        :network_interface_id,
        :vpc_peering_connection_id,
        :nat_gateway_id,
      ].each {|k| hash[k] = route.send(k) }

      result[:routes] << hash
    }

    result
  end

  def export_subnets(associations)
    associations.map(&:subnet_id).reject(&:nil?)
  end
end
