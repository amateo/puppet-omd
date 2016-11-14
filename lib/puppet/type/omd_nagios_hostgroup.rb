begin
  require 'puppet_x/omd'
rescue
  libdir = Pathname.new(__FILE__).parent.parent.parent.parent
  require File.join(libdir, 'puppet_x/omd')
end

Puppet::Type.newtype(:omd_nagios_hostgroup) do
  @doc = 'Creates a nagios hostgroup object in an OMD site'
  desc <<-EOT
    Creates a nagios hostgroup object in an OMD site

  EOT

  include Puppet_X::Omd

  ensurable

  class HostGroupParam < Puppet::Property
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
    desc "The name of the puppet's nagios hostgroup resource"
    isnamevar
  end

  newproperty(:site) do
    desc 'OMD site in which to create the nagios hostgroup object'
    validate do |value|
      unless value =~ /^.+$/
        raise ArgumentError, 'You must provide a site paramater for omd_nagios_hostgroup objects'
      end
    end
  end

  newproperty(:hostgroup_name, :parent => HostGroupParam) do
    desc 'The name of this nagios_hostgroup resource.'
    defaultto { @resource[:name] }
  end

  newproperty(:action_url, :parent => HostGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:nagios_alias, :parent => HostGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:hostgroup_members, :parent => HostGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:members, :parent => HostGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notes, :parent => HostGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notes_url, :parent => HostGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:realm, :parent => HostGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:register, :parent => HostGroupParam) do
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

  newproperty(:use, :parent => HostGroupParam) do
    desc 'Nagios configuration file parameter.'
  end
end
