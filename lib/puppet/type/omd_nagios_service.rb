begin
  require 'puppet_x/omd'
rescue
  libdir = Puppet::settings.value('vardir').to_s
  require File.join(libdir, 'puppet_x/omd')
end

Puppet::Type.newtype(:omd_nagios_service) do
  @doc = 'Creates a nagios service object in an OMD site'
  desc <<-EOT
    Creates a nagios service object in an OMD site

  EOT

  include Puppet_X::Omd

  ensurable

  class ServiceParam < Puppet::Property
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
    desc "The name of the puppet's nagios service resource"
    isnamevar
  end

  newparam(:site) do
    desc 'OMD site in which to create the nagios service object'
    validate do |value|
      unless value =~ /^.+$/
        raise ArgumentError, 'You must provide a site paramater for omd_nagios_service objects'
      end
    end
  end

  newproperty(:action_url, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:active_checks_enabled, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:business_impact, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_command, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_freshness, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_interval, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_period, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:contact_groups, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:contacts, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:display_name, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:event_handler, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:event_handler_enabled, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:failure_prediction_enabled, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:first_notification_delay, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:flap_detection_enabled, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:flap_detection_options, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:freshness_threshold, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:high_flap_threshold, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:host_name, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:hostgroup_name, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:icon_image, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:icon_image_alt, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:initial_state, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:is_volatile, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:low_flap_threshold, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:max_check_attempts, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:normal_check_interval, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notes, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notes_url, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notification_interval, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notification_options, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notification_period, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notifications_enabled, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:obsess_over_service, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:parallelize_check, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:passive_checks_enabled, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:poller_tag, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:process_perf_data, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:register, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retain_nonstatus_information, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retain_status_information, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retry_check_interval, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retry_interval, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:service_description, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:servicegroups, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:stalking_options, :parent => ServiceParam) do
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

  newparam(:target) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:use, :parent => ServiceParam) do
    desc 'Nagios configuration file parameter.'
  end
end
