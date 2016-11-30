begin
  require 'puppet_x/test'
rescue
  libdir = Puppet::settings.value('vardir').to_s
  require File.join(libdir, 'puppet_x/test')
end

Puppet::Type.newtype(:omd_service) do
  @doc = 'Creates a nagios service object in an OMD site'
  desc <<-EOT
    Creates a nagios service object in an OMD site

  EOT

  include Puppet_X::Test

  ensurable

  newparam(:name) do
    desc "The name of the puppet's nagios service resource"
    isnamevar
  end

  newparam(:site) do
    desc 'OMD site in which to create the nagios service object'
    validate do |value|
      unless value =~ /^.+$/
        raise ArgumentError, 'You must provide a site paramater for omd_service objects'
      end
    end
  end

  newproperty(:action_url) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:active_checks_enabled) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:business_impact) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_command) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_freshness) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_interval) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:check_period) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:contact_groups) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:contacts) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:display_name) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:event_handler) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:event_handler_enabled) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:failure_prediction_enabled) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:first_notification_delay) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:flap_detection_enabled) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:flap_detection_options) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:freshness_threshold) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:high_flap_threshold) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:host_name) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:hostgroup_name) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:icon_image) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:icon_image_alt) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:initial_state) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:is_volatile) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:low_flap_threshold) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:max_check_attempts) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:normal_check_interval) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notes) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notes_url) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notification_interval) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notification_options) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notification_period) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notifications_enabled) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:obsess_over_service) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:parallelize_check) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:passive_checks_enabled) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:poller_tag) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:process_perf_data) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:register) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retain_nonstatus_information) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retain_status_information) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retry_check_interval) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retry_interval) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:service_description) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:servicegroups) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:stalking_options) do
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

  newproperty(:use) do
    desc 'Nagios configuration file parameter.'
  end
end
