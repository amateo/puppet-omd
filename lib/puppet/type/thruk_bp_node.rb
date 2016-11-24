Puppet::Type.newtype(:thruk_bp_node) do
  @doc = "Creates a node in a Thruk BP"

  ensurable do
    defaultvalues

    defaultto { :present }
  end

  def exists?
    self[:ensure] == :present
  end

  newparam(:name, :namevar => true) do
    desc "The name"
    isnamevar
    validate do |value|
      if match = value.match(/^([^\/]+)\/([^\/]+)\/([^\/]+)$/)
        id = match.captures[2]
        raise ArgumentError, "Thruk_bp_node[#{value}]: Name of thruk_bp_node resource can't contain space blanks" if id =~ /\s/
      else
        raise ArgumentError, "Thruk_bp_node[#{value}]: Name of thruk_bp_node resource can't contain space blanks" if @resource[:name] =~ /\s/
      end
    end
  end

  newparam(:site) do
    desc "site"
    defaultto do
      if match = @resource[:name].match(/^([^\/]+)\/([^\/]+)\/([^\/]+)$/)
        match.captures[0]
      else
        :absent
      end
    end
    validate do |value|
      raise ArgumentError, "Thruk_bp_node[#{@resource[:name]}]: 'site' parameter is mandatory" if value == :absent
    end
  end

  newparam(:bp) do
    desc "bp"
    defaultto do
      if match = @resource[:name].match(/^([^\/]+)\/([^\/]+)\/([^\/]+)$/)
        match.captures[1]
      else
        :absent
      end
    end
    validate do |value|
      raise ArgumentError, "Thruk_bp_node[#{@resource[:name]}]: 'bp' parameter is mandatory" if value == :absent
    end
  end

  newparam(:id) do
    desc 'Id'
    defaultto do
      if match = @resource[:name].match(/^([^\/]+)\/([^\/]+)\/([^\/]+)$/)
        match.captures[2]
      else
        @resource[:name]
      end
    end
    validate do |value|
      raise ArgumentError, "Thruk_bp_node[#{@resource[:name]}]: 'id' parameter is mandatory" if value == :absent
    end
  end

  newparam(:label) do
    desc 'Label'
    defaultto { @resource[:id] }
  end

  newparam(:parent) do
    desc "parent"
    defaultto { 'node1' }
  end

  newparam(:function) do
    desc "function"
    defaultto { "fixed('OK')" }
  end
  
  autorequire(:thruk_bp) do
    #unless catalog.resource("Thruk_bp[#{self[:bp]}]")
    #  warning "Target Thruk_bp[#{self[:bp]}] not found in the catalog"
    #end
    [self[:bp]]
  end

  autorequire(:thruk_bp_node) do
    if self[:parent] != 'node1'
      deps = catalog.resources.collect do |r|
        if r.is_a?(Puppet::Type.type(:thruk_bp_node)) &&
          r[:site] == self[:site] && r[:bp] == self[:bp] && r[:id] == self[:parent]
          r.name
        end
      end.compact
      #if deps.empty?
      #  warning "Parent node \"#{self[:parent]}\" for Thruk_bp_node[#{self[:name]} not found in the catalog"
      #end
      deps
    end
  end

end
