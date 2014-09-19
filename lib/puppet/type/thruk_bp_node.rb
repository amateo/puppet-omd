Puppet::Type.newtype(:thruk_bp_node) do
  @doc = "asdflkajsdfkjf"

  ensurable

  newparam(:name) do
    desc "The name"
    isnamevar
  end

  newproperty(:site) do
    desc "site"
    defaultto {
      if match = @resource[:name].match(/^([^\/]+)\/([^\/]+)\/([^\/]+)$/)
        site, bp, id = match.captures
        site
      else
        ''
      end
    }
  end

  newproperty(:bp) do
    desc "bp"
    defaultto {
      if match = @resource[:name].match(/^([^\/]+)\/([^\/]+)\/([^\/]+)$/)
        site, bp, id = match.captures
        bp
      else
        ''
      end
    }
  end

  newproperty(:id) do
    desc 'Id'
    defaultto {
      if match = @resource[:name].match(/^([^\/]+)\/([^\/]+)\/([^\/]+)$/)
        site, bp, id = match.captures
        id
      else
        ''
      end
    }
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
end
