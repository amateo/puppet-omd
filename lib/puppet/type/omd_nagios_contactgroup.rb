Puppet::Type.newtype(:omd_nagios_contactgroup) do
  @doc = 'Creates a nagios contactgroup object in an OMD site'
  desc <<-EOT
    Creates a nagios contactgroup object in an OMD site

  EOT

  ensurable

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

  newproperty(:contactgroup_name) do
    desc 'The name of this nagios_contactgroup resource.'
    defaultto { @resource[:name] }
  end

  newproperty(:nagios_alias) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:contactgroup_members) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:members) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:register) do
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

  newproperty(:use) do
    desc 'Nagios configuration file parameter.'
  end
end
