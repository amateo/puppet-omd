Puppet::Type.newtype(:omd_nagios_contact) do
  @doc = 'Creates a nagios contact object in an OMD site'
  desc <<-EOT
    Creates a nagios contact object in an OMD site

  EOT

  ensurable

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

  newproperty(:contact_name) do
    desc 'The name of this nagios_contact resource.'
    defaultto { @resource[:name] }
  end

  newproperty(:address1) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address2) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address3) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address4) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address5) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:address6) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:nagios_alias) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:can_submit_commands) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:contactgroups) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:email) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:group) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:host_notification_commands) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:host_notification_options) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:host_notification_period) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:host_notifications_enabled) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:mode) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:owner) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:pager) do
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

  newproperty(:service_notification_commands) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:service_notification_options) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:service_notification_period) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:service_notifications_enabled) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:target) do
    desc 'Nagios configuration file parameter.'
    defaultto do
      if @resource[:site]
        '/omd/sites/' + @resource[:site] + '/etc/nagios/conf.d/contacts_puppet.cfg'
      else
        ''
      end
    end
  end

  newproperty(:use) do
    desc 'Nagios configuration file parameter.'
  end

  #autorequire(:Omd::Site) do
    #[ @resource[:site] ]
  #end
end
