begin
  require 'puppet_x/omd'
rescue
  libdir = Pathname.new(__FILE__).parent.parent.parent.parent
  require File.join(libdir, 'puppet_x/omd')
end

Puppet::Type.newtype(:omd_nagios_contact) do
  @doc = 'Creates a nagios contact object in an OMD site'
  desc <<-EOT
    Creates a nagios contact object in an OMD site

  EOT

  include Puppet_X::Omd

  ensurable

  class ContactParam < Puppet::Property
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
    desc "The name of the puppet's nagios contact resource"
    isnamevar
  end

  newproperty(:site) do
    desc 'OMD site in which to create the nagios contact object'
    validate do |value|
      unless value =~ /^.+$/
        raise ArgumentError, 'You must provide a site paramater for omd_nagios_contact objects'
      end
    end
  end

  newproperty(:contact_name, :parent => ContactParam) do
    desc 'The name of this nagios_contact resource.'
    defaultto { @resource[:name] }
  end

  newproperty(:address1, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address2, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address3, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address4, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address5, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address6, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:nagios_alias, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:can_submit_commands, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:contactgroups, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:email, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:group, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:host_notification_commands, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:host_notification_options, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:host_notification_period, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:host_notifications_enabled, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:mode, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:owner, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:pager, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:register, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retain_nonstatus_information, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:retain_status_information, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:service_notification_commands, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:service_notification_options, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:service_notification_period, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:service_notifications_enabled, :parent => ContactParam) do
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

  newproperty(:use, :parent => ContactParam) do
    desc 'Nagios configuration file parameter.'
  end

  #autorequire(:Omd::Site) do
    #[ @resource[:site] ]
  #end
end
