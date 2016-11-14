begin
  require 'puppet_x/omd'
rescue
  libdir = Pathname.new(__FILE__).parent.parent.parent.parent
  require File.join(libdir, 'puppet_x/omd')
end

Puppet::Type.newtype(:omd_nagios_host) do
  @doc = 'Creates a nagios host object in an OMD site'
  desc <<-EOT
    Creates a nagios host object in an OMD site

  EOT

  include Puppet_X::Omd

  ensurable

  class HostParam < Puppet::Property
    class << self
      attr_accessor :boundaries, :default
    end

    def should
      if @should and @should[0] == :absent
        :absent
      else
        @should.join(',')
      end
    end

    munge do |value|
      if value == 'absent' or value == :absent
        return :absent
      elsif value == ''
        return :absent
      else
        if value.respond_to?('force_encoding') then
          value.force_encoding('ASCII-8BIT')
        end
        return super(value)
      end
    end
  end

  newparam(:name) do
    desc "The name of the puppet's nagios host resource"
    isnamevar
  end

  newproperty(:site) do
    desc 'OMD site in which to create the nagios host object'
    validate do |value|
      unless value =~ /^.+$/
        raise ArgumentError, 'You must provide a site paramater for omd_nagios_host objects'
      end
    end
  end

  newproperty(:host_name, :parent => HostParam) do
    desc 'The name of this nagios_host resource.'
    defaultto { @resource[:name] }
  end

  newproperty(:action_url, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:active_checks_enabled, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:nagios_alias, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:business_impact, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_command, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_freshness, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_interval, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_period, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:contact_groups, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:contacts, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:display_name, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:event_handler, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:event_handler_enabled, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:failure_prediction_enabled, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:first_notification_delay, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:flap_detection_enabled, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:flap_detection_options, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:freshness_threshold, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:high_flap_threshold, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:hostgroups, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:icon_image, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:icon_image_alt, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:initial_state, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:low_flap_threshold, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:max_check_attempts, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notes, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notes_url, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notification_interval, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notification_options, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notification_period, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notifications_enabled, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:obsess_over_host, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:parents, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:passive_checks_enabled, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:poller_tag, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:process_perf_data, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:realm, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:register, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retain_nonstatus_information, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retain_status_information, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retry_interval, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:stalking_options, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:statusmap_image, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:custom) do
    desc "Custom host attributes"

    munge do |value|
      new = {}
      value.each_pair do |k, v|
        new[k.upcase] = v
      end
      new
    end

    validate do |value|
      value.each_key do |k|
        if !k.start_with?('_') then
          raise ArgumentError, 'custom keys must begin with _'
        end
      end
    end

    def insync?(is)
      is == should
    end
  end

  newproperty(:target) do
    desc 'Nagios configuration file parameter.'
    defaultto do
      if @resource[:site]
        Puppet_X::Omd::file_path_for_object(@resource.type, @resource[:site])
      else
        ''
      end
    end
  end

  newproperty(:use, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:vrml_image, :parent => HostParam) do
    desc 'Nagios configuration file parameter.'
  end
end
