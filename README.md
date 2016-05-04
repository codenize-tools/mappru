# Mappru

Mappru is a tool to manage VPC Route Table.

It defines the state of VPC Route Table using DSL, and updates VPC Route Table according to DSL.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mappru'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mappru

## Usage

```sh
export AWS_ACCESS_KEY_ID='...'
export AWS_SECRET_ACCESS_KEY='...'
mappru -e -o RouteTable  # export VPC Route Table
vi PolicyFile
mappru -a --dry-run
mappru -a                # apply `RouteTable`
```

## Help

```
Usage: mappru [options]
    -k, --access-key ACCESS_KEY
    -s, --secret-key SECRET_KEY
    -r, --region REGION
        --profile PROFILE
        --credentials-path PATH
    -a, --apply
    -f, --file FILE
        --dry-run
    -e, --export
    -o, --output FILE
        --split
        --vpc-id REGEXP
        --rt-name REGEXP
        --no-color
        --debug
```

## RouteTable example

```ruby
require 'other/tablefile'

vpc "vpc-12345678" do
  route_table "foo-rt" do
    subnets "subnet-12345678"
    route destination_cidr_block: "0.0.0.0/0", gateway_id: "igw-12345678"
    route destination_cidr_block: "192.168.100.101/32", network_interface_id: "eni-12345678"
  end

  route_table "bar-rt" do
    subnets "subnet-87654321"
    route destination_cidr_block: "192.168.100.102/32", network_interface_id: "eni-87654321"
  end

  # Undefined Route Table will be ignored
end

# Undefined VPC will be ignored
```
