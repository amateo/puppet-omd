Puppet::Type.newtype(:thruk_bp) do
  @doc = "Creates a BP object for Thruk"
  desc <<-EOT
    Creates a BP object for Thruk monitoring

  EOT

  ensurable

  newparam(:name) do
    desc "The name"
    isnamevar
  end

  newproperty(:state_type) do
    desc "Nagios state types used. 'both' uses soft and hard states. 'hard' only uses hard states"
    newvalues(:both, :hard)
    defaultto(:both)
  end

  newproperty(:site) do
    desc 'OMD site where to apply configuration in'
    validate do |value|
      if !value or value == ''
        raise ArgumentError,
          'You must provide a site parameter'
      end
    end
  end

  #newproperty(:core) do
    #desc 'Monitorization system core to use. Currently, oly nagios is supported'
    #newvalue(:nagios) do
      #provider.create
    #end
    #defaultto(:nagios)
  #end
  
  newproperty(:host_template) do
    desc 'Nagios template to use for the nagios host object created'
  end
  
  newproperty(:service_template) do
    desc 'Nagios template to use for the nagios service object created'
  end

  newproperty(:host_name) do
    desc 'Name of the nagios host created'
    defaultto { @resource[:name] }
  end

  newparam(:target) do
    desc 'The file to store the BP definition'
  end
end
