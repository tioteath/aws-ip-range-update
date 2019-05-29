#!/usr/bin/env ruby
# AWS Lambda function to request AWS IP ranges from https://ip-ranges.amazonaws.com
# for a region and update security groups from SECURITY_GROUP
# with IP range of lenght security_group_limit.
#
# Environment:
#
#   REGION (Default: us-east-1) - AWS region to operate in.
#   SECURITY_GROUP (Default: none) - Coma-separated list of target security groups.
#     Example: SECURITY_GROUP='sg-3g2ghd78,sg-mn2948s8,sg-123456b7'
#   SECURITY_GROUP_LIMIT (Default: 40) - maximum amount of IP rules to be
#       placed into an each security group from the list.
#   DEBUG (Default: none) - Print warn message to STDERR

require 'net/http'
require 'json'
require 'aws-sdk-ec2'

def debug(message)
  warn message.to_s unless ['false', 'False', 'no', 'No'].include? ENV['DEBUG']
end

def handler(event:, context:)
  region = ENV.fetch('REGION', 'us-east-1')
  debug "region: #{region}"
  abort "Security group list is not set" if ENV['SECURITY_GROUP'].nil?
  security_group = ENV['SECURITY_GROUP'].split(',').compact.each do |entry|
    entry.strip!
  end
  debug "security_group: #{security_group}"
  security_group_limit = ENV.fetch('SECURITY_GROUP_LIMIT', 40)
  debug "security_group_limit: #{security_group_limit}"

  time = Time.new.utc

  # Obtain IP range
  data = JSON.parse Net::HTTP.
      get URI 'https://ip-ranges.amazonaws.com/ip-ranges.json'
  range_list = data["prefixes"].collect do |entry|
    entry["ip_prefix"] if region.include? entry["region"]
  end.compact.sort.uniq
  debug "range_list: #{range_list}"

  range_list.each_slice(security_group_limit.to_i).with_index do |range, index|
    abort "Cannot fit IP ranges into available groups. Add more groups." if
        security_group.length <= index

    # Requesting IP ranges of active permission for security group from the list
    group = Aws::EC2::SecurityGroup.new security_group[index]
    cidr_current = []
    unless group.ip_permissions.empty?
      cidr_current = group.ip_permissions.first.ip_ranges.
          collect { |entry| entry.cidr_ip }.sort.uniq
    end
    debug "group_id: #{security_group[index]}"
    debug "cidr_current: #{cidr_current}"

    # binding.pry
    # Diff between the currently active and the new IPs
    cidr_new = range - cidr_current
    debug "cidr_new: #{cidr_new}"
    cidr_old = cidr_current - range
    debug "cidr_old: #{cidr_old}"

    # Remove obsolete ranges
    unless cidr_old.empty?
      permission = { ip_permissions: [{ ip_protocol: "-1", ip_ranges: [] }] }
      cidr_old.each do |cidr|
        permission[:ip_permissions].first[:ip_ranges] << { cidr_ip: cidr }
      end
      debug "permission: #{permission}"
      group.revoke_ingress permission
    end

    # Add new ranges
    unless cidr_new.empty?
      permission = { ip_permissions: [{ ip_protocol: "-1", ip_ranges: [] }] }
      cidr_new.each do |cidr|
        permission[:ip_permissions].first[:ip_ranges] << {
            cidr_ip: cidr,
            description: "Modified: #{time}"
          }
      end
      debug "permission: #{permission}"
      group.authorize_ingress permission
    end
  end
end
