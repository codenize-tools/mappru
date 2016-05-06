class Mappru::Driver
  include Mappru::Logger::Helper
  include Mappru::Utils::Helper

  def initialize(client, options = {})
    @client = client
    @resource = Aws::EC2::Resource.new(client: @client)
    @options = options
  end

  def create_route_table(vpc_id, name, attrs)
    log(:info, "Create Route Table `#{vpc_id}` > `#{name}`", color: :cyan)

    unless @options[:dry_run]
      vpc = @resource.vpc(vpc_id)
      rt = vpc.create_route_table
      name_tag = {key: 'Name', value: name}
      rt.create_tags(tags: [name_tag])
      rt_id_by_vpc_rt_name[vpc_id][name] = rt.id
    end

    {routes: [], subnets: []}
  end

  def associate_subnets(vpc_id, rt_name, subnet_ids)
    log(:info, "Associate Subnets `#{vpc_id}` > `#{rt_name}`: #{subnet_ids.join(', ')}", color: :green)

    unless @options[:dry_run]
      subnet_ids.each do |sbnt_id|
        rt_id = rt_id_by_vpc_rt_name.fetch(vpc_id).fetch(rt_name)
        params = {route_table_id: rt_id, subnet_id: sbnt_id}
        @client.associate_route_table(params)
      end
    end
  end

  def disassociate_subnets(vpc_id, rt_name, subnet_ids)
    log(:info, "Disassociate Subnets `#{vpc_id}` > `#{rt_name}`: #{subnet_ids.join(', ')}", color: :red)

    unless @options[:dry_run]
      subnet_ids.each do |sbnt_id|
        assoc_id = assoc_id_by_subnet.fetch(sbnt_id)
        params = {association_id: assoc_id}
        @client.disassociate_route_table(params)
      end
    end
  end

  def create_route(vpc_id, rt_name, dest_cidr, attrs)
    log(:info, "Create Route `#{vpc_id}` > `#{rt_name}` > `#{dest_cidr}`", color: :cyan)

    unless @options[:dry_run]
      rt_id = rt_id_by_vpc_rt_name.fetch(vpc_id).fetch(rt_name)
      params = attrs.merge(route_table_id: rt_id, destination_cidr_block: dest_cidr)
      @client.create_route(params)
    end
  end

  def delete_route(vpc_id, rt_name, dest_cidr)
    log(:info, "Delete Route `#{vpc_id}` > `#{rt_name}` > `#{dest_cidr}`", color: :red)

    unless @options[:dry_run]
      rt_id = rt_id_by_vpc_rt_name.fetch(vpc_id).fetch(rt_name)
      params = {route_table_id: rt_id, destination_cidr_block: dest_cidr}
      @client.delete_route(params)
    end
  end

  def update_route(vpc_id, rt_name, dest_cidr, route, old_route)
    log(:info, "Update Route `#{vpc_id}` > `#{rt_name}` > `#{dest_cidr}`", color: :green)
    log(:info, diff(old_route, route, color: @options[:color]), color: false)

    unless @options[:dry_run]
      rt_id = rt_id_by_vpc_rt_name.fetch(vpc_id).fetch(rt_name)
      params = route.merge(route_table_id: rt_id, destination_cidr_block: dest_cidr)
      @client.replace_route(params)
    end
  end

  private

  def rt_id_by_vpc_rt_name
    return @rt_ids if @rt_ids

    @rt_ids = {}
    route_tables = @resource.route_tables

    route_tables.each do |rt|
      vpc_id = rt.vpc_id
      name_tag = rt.tags.find {|i| i.key == 'Name' } || {}
      name = name_tag[:value]

      next unless name

      @rt_ids[vpc_id] ||= {}
      @rt_ids[vpc_id][name] = rt.id
    end

    @rt_ids
  end

  def assoc_id_by_subnet
    return @assoc_ids if @assoc_ids

    @assoc_ids = {}
    associations = @resource.route_tables.map(&:associations).flat_map(&:to_a)

    associations.each do |assoc|
      if assoc.subnet_id
        @assoc_ids[assoc.subnet_id] = assoc.id
      end
    end

    @assoc_ids
  end
end
