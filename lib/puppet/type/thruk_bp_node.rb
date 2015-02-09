Puppet::Type.newtype(:thruk_bp_node) do
  @doc = "asdflkajsdfkjf"

  ensurable

  newparam(:name) do
    desc "The name"
    isnamevar
  end

  newproperty(:site) do
    desc "site"
    defaultto do :absent end
    validate do |value|
      raise Puppet::Error, "Thruk_bp_node[#{@resource[:name]}]: 'site' parameter is mandatory" if value == :absent
    end
  end

  newproperty(:bp) do
    desc "bp"
    defaultto do :absent end
    validate do |value|
      raise Puppet::Error, "Thruk_bp_node[#{@resource[:name]}]: 'bp' parameter is mandatory" if value == :absent
    end
  end

  newproperty(:id) do
    desc 'Id'
    defaultto do :absent end
    validate do |value|
      raise Puppet::Error, "Thruk_bp_node[#{@resource[:name]}]: 'id' parameter is mandatory" if value == :absent
    end
  end

  newproperty(:label) do
    desc 'Label'
    defaultto { @resource[:id] }
  end

  newproperty(:parent) do
    desc "parent"
    defaultto { 'node1' }
  end

  newproperty(:function) do
    desc "function"
    defaultto { "fixed('OK')" }
  end

  newparam(:target) do
    desc 'The file to store the BP definition'
  end

  autorequire(:thruk_bp) do
    if not catalog.resource("Thruk_bp[#{self[:bp]}]") then
      err "There is no Thruk_bp resource named #{self[:bp]}."
    end
    [ self[:bp] ]
  end
end
