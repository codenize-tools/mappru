class Mappru::Client
  include Mappru::Logger::Helper
  include Mappru::Utils::Helper

  def initialize(options = {})
    @options = options
    @client = @options[:client] || Aws::EC2::Client.new
    @resource = Aws::EC2::Resource.new(client: @client)
    @driver = Mappru::Driver.new(@client, @options)
  end

  def export
    Mappru::Exporter.export(@client, @options)
  end

  def vpc_name_by_id(vpc_id)
    name_tag = @resource.vpc(vpc_id).tags.find {|i| i.key == 'Name' } || {}
    name_tag[:value]
  end

  def apply(file)
    walk(file)
  end

  private

  def walk(file)
    expected = load_file(file)
    actual = Mappru::Exporter.export(@client, @options)

    updated = walk_vpcs(expected, actual)

    if @options[:dry_run]
      false
    else
      updated
    end
  end

  def walk_vpcs(expected, actual)
    updated = false

    expected.each do |vpc_id, expected_rts|
      next unless matched?(vpc_id, @options[:vpc_id])

      actual_rts = actual.delete(vpc_id)

      if actual_rts
        updated = walk_vpc(vpc_id, expected_rts, actual_rts) || updated
      else
        log(:warn, "No such VPC: #{vpc_id}")
      end
    end

    # Undefined VPC will be ignored

    updated
  end

  def walk_vpc(vpc_id, expected, actual)
    updated = false

    expected.each do |rt_name, expected_rt|
      next unless matched?(rt_name, @options[:rt_name])

      actual_rt = actual.delete(rt_name)

      unless actual_rt
        actual_rt = @driver.create_route_table(vpc_id, rt_name, expected_rt)
        updated = true
      end

      updated = walk_route_table(vpc_id, rt_name, expected_rt, actual_rt) || updated
    end

    # Undefined Route Table will be ignored

    updated
  end

  def walk_route_table(vpc_id, name, expected, actual)
    updated = false
    updated = walk_subnets(vpc_id, name, expected[:subnets], actual[:subnets]) || updated
    updated = walk_routes(vpc_id, name, expected[:routes], actual[:routes]) || updated
    updated
  end

  def walk_subnets(vpc_id, name, expected, actual)
    updated = false
    assoc_subnets = expected - actual
    disassoc_subnets = actual - expected

    unless assoc_subnets.empty?
      @driver.associate_subnets(vpc_id, name, assoc_subnets)
      updated = true
    end

    unless disassoc_subnets.empty?
      @driver.disassociate_subnets(vpc_id, name, disassoc_subnets)
      updated = true
    end

    updated
  end

  def walk_routes(vpc_id, rt_name, expected, actual)
    expected = routes_to_hash(expected)
    actual = routes_to_hash(actual)
    updated = false

    expected.each do |dest_cidr, expected_route|
      if expected_route[:gateway_id] == 'local'
        log(:warn, %!Cannot configure "local" target: #{vpc_id}: #{rt_name}!, color: :yellow)
        next
      end

      actual_route = actual.delete(dest_cidr)

      if actual_route
        updated = walk_route(vpc_id, rt_name, dest_cidr, expected_route, actual_route) || updated
      else
        @driver.create_route(vpc_id, rt_name, dest_cidr, expected_route)
        updated = true
      end
    end

    actual.each do |dest_cidr, actual_route|
      @driver.delete_route(vpc_id, rt_name, dest_cidr)
      updated = true
    end
  end

  def walk_route(vpc_id, rt_name, dest_cidr, expected, actual)
    expected = expected.without_nil.sort_pair
    actual = actual.without_nil.sort_pair
    updated = false

    if expected != actual
      @driver.update_route(vpc_id, rt_name, dest_cidr, expected, actual)
      updated = true
    end

    updated
  end

  def load_file(file)
    if file.kind_of?(String)
      open(file) do |f|
        Mappru::DSL.parse(f.read, file)
      end
    elsif file.respond_to?(:read)
      Mappru::DSL.parse(file.read, file.path)
    else
      raise TypeError, "can't convert #{file} into File"
    end
  end

  def routes_to_hash(routes)
    hash = {}

    routes.map(&:dup).each do |r|
      dest_cidr = r.delete(:destination_cidr_block)
      hash[dest_cidr] = r
    end

    hash
  end
end
