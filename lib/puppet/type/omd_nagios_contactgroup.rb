Puppet::Type.newtype(:omd_nagios_contactgroup) do
  @doc = 'Creates a nagios contactgroup object in an OMD site'
  desc <<-EOT
    Creates a nagios contactgroup object in an OMD site

  EOT

  ensurable

  class ContactGroupParam < Puppet::Property
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
        return value
      end
    end
  end

  newparam(:name) do
    desc "The name of the puppet's nagios contactgroup resource"
    isnamevar
  end

  newproperty(:site) do
    desc 'OMD site in which to create the nagios contactgroup object'
    validate do |value|
      unless value =~ /^.+$/
        raise ArgumentError, 'You must provide a site paramater for omd_nagios_contactgroup objects'
      end
    end
  end

  newproperty(:contactgroup_name, :parent => ContactGroupParam) do
    desc 'The name of this nagios_contactgroup resource.'
    defaultto { @resource[:name] }
  end

  newproperty(:nagios_alias, :parent => ContactGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:contactgroup_members, :parent => ContactGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:members, :parent => ContactGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:register, :parent => ContactGroupParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:target) do
    desc 'Nagios configuration file parameter.'
    defaultto do
      if @resource[:site]
        '/omd/sites/' + @resource[:site] + '/etc/nagios/conf.d/contactgroups_puppet.cfg'
      else
        ''
      end
    end
  end

  newproperty(:use, :parent => ContactGroupParam) do
    desc 'Nagios configuration file parameter.'
  end
end
