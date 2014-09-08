Puppet::Type.newtype(:thruk_bp) do
  @doc = "Creates a BP object for Thruk"
  desc <<-EOT
    Creates a BP object for Thruk monitoring

  EOT

  ensurable do
    defaultto :present
  end
  #ensurable do
    #defaultto :present
    #newvalue(:present) do
      #provider.create
    #end
    #newvalue(:absent) do
      #provider.destroy
    #end
  #end

  newparam(:name) do
    desc "The name"
    isnamevar
  end

  newproperty(:state_type) do
    desc "Nagios state types used. 'both' uses soft and hard states. 'hard' only uses hard states"
    newvalues(:both, :hard)
    defaultto(:both)
  end

  #newproperty(:site) do
    #desc 'OMD site where to apply configuration in'
  #end

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

  newparam(:file) do
    desc 'The file'
  end

end
