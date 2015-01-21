Puppet::Type.newtype(:omd_nagios_command) do
  @doc = 'Creates a nagios command object in an OMD site'
  desc <<-EOT
    Creates a nagios command object in an OMD site

  EOT

  ensurable

  class CommandParam < Puppet::Property
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
    desc "The name of the puppet's nagios command resource"
    isnamevar
  end

  newproperty(:site) do
    desc 'OMD site in which to create the nagios command object'
    validate do |value|
      unless value =~ /^.+$/
        raise ArgumentError, 'You must provide a site paramater for omd_nagios_command objects'
      end
    end
  end

  newproperty(:command_name, :parent => CommandParam) do
    isnamevar
    desc 'The name of this nagios_command resource.'
    defaultto { @resource[:name] }
  end

  newproperty(:command_line, :parent => CommandParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:poller_tag, :parent => CommandParam) do
    desc 'Nagios configuration file parameter.'
  end

  newproperty(:target) do
    desc 'Nagios configuration file parameter.'
    defaultto do
      if @resource[:site]
        '/omd/sites/' + @resource[:site] + '/etc/nagios/conf.d/commands_puppet.cfg'
      else
        ''
      end
    end
  end

  newproperty(:use, :parent => CommandParam) do
    desc 'Nagios configuration file parameter.'
  end
end
