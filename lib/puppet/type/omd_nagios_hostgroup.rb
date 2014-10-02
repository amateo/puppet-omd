Puppet::Type.newtype(:omd_nagios_hostgroup) do
  @doc = 'Creates a nagios hostgroup object in an OMD site'
  desc <<-EOT
    Creates a nagios hostgroup object in an OMD site

  EOT

  ensurable

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

  newproperty(:hostgroup_name) do
    desc 'The name of this nagios_hostgroup resource.'
    defaultto { @resource[:name] }
  end

  newproperty(:action_url) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:nagios_alias) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:hostgroup_members) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:members) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notes) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:notes_url) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:realm) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:register) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:target) do
    desc 'Nagios configuration file parameter.'
    defaultto do
      if @resource[:site]
        '/omd/sites/' + @resource[:site] + '/etc/nagios/conf.d/hostgroups_puppet.cfg'
      else
        ''
      end
    end
  end

  newproperty(:use) do
    desc 'Nagios configuration file parameter.'
  end
end
