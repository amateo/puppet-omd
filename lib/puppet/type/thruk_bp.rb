Puppet::Type.newtype(:thruk_bp) do
  @doc = "Creates a BP object for Thruk"
  desc <<-EOT
    Creates a BP object for Thruk monitoring

  EOT

  ensurable do
    defaultvalues

    defaultto { :present }
  end

  class NagiosParam < Puppet::Property
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
        if value.respond_to?('force_encoding') then
          #value.force_encoding('ASCII-8BIT')
          value.force_encoding('UTF-8')
        end
        return super(value)
      end
    end
  end

  def exists?
    self[:ensure] == :present
  end

  newparam(:name, :parent => NagiosParam) do
    desc "The name"
    isnamevar
  end

  newparam(:state_type, :parent => NagiosParam) do
    desc "Nagios state types used. 'both' uses soft and hard states. 'hard' only uses hard states"
    newvalues(:both, :hard)
    defaultto(:both)
  end

  newparam(:site, :parent => NagiosParam) do
    desc 'OMD site where to apply configuration in'
    validate do |value|
      if !value or value == ''
        raise ArgumentError,
          'You must provide a site parameter'
      end
    end
    defaultto do
      if match = @resource[:name].match(/^([^\/]+)\/([^\/]+)$/)
        match.captures[0]
      else
        :absent
      end
    end
  end
  
  newparam(:host_template, :parent => NagiosParam) do
    desc 'Nagios template to use for the nagios host object created'
    defaultto { 'thruk-bp-template' }

  end
  
  newparam(:service_template, :parent => NagiosParam) do
    desc 'Nagios template to use for the nagios service object created'
    defaultto { 'thruk-bp-node-template' }
  end
  #
  #newparam(:host_name, :parent => NagiosParam) do
  #  desc 'Name of the nagios host created'
  #  defaultto { @resource[:name] }
  #end

  newparam(:servicegroups, :parent => NagiosParam) do
    desc 'Nagios servicegroups this BP belongs to'
  end

  newparam(:notes, :parent => NagiosParam) do
    desc 'Nagios notes for this BP service'
  end

  newparam(:display_name, :parent => NagiosParam) do
    desc 'Nagios service diplay name'
    defaultto { @resource[:name] }
  end

  newparam(:function, :parent => NagiosParam) do
    desc 'Function to use in the main node of the BP'
    defaultto { 'worst()' }
  end

  newparam(:rank_dir, :parent => NagiosParam) do
    desc 'Graph direction. Valid values are TB (Top-Bottom) and LR (Left-Right)'
    newvalues(:TB, :LR)
    defaultto(:TB)
  end

  newparam(:target) do
    desc 'The path of the .tbp file'
    defaultto {
      filename = @resource.find_bp_file(@resource[:name])
      if filename
        filename
      else
        nil
      end
    }
  end

  autorequire(:file) do
    [self[:target]]
  end

  def should_content
    return @generated_content if @generated_content
    @generated_content = ""

    resources = catalog.resources.sort_by(&:name).select do |r|
      r.is_a?(Puppet::Type.type(:thruk_bp_node)) && r[:bp] == self[:name] and r[:ensure] == :present
    end

    # Atributos del BP
    json = Hash.new
    json[:rankDir] = self[:rank_dir].to_s.force_encoding('UTF-8') if self[:rank_dir]
    json[:state_type] = self[:state_type].to_s.force_encoding('UTF-8') if self[:state_type]
    json[:name] = self[:name]
    json[:template] = self[:host_template].force_encoding('UTF-8') if self[:host_template]

    # Nodo raíz
    node = {}
    node[:function] = self[:function] if self[:function]
    node[:label] = self[:name]
    node[:id] = 'node1'
    node[:template] = self[:service_template] if self[:service_template]
    node[:depends] = resources.select do |r|
      r[:parent] == 'node1'
    end.map do |r|
      r[:id]
    end
    json[:nodes] = [ node ]

    resources.each do |r|
      node = {}
      node[:label] = r[:label]
      node[:id] = r[:id]
      node[:function] = r[:function] if r[:function]
      depended_resources = resources.select do |r2|
        r2[:parent] == r[:id]
      end.map do |r2|
        r2[:id]
      end
      node[:depends] = depended_resources if !depended_resources.empty?
      json[:nodes] << node
    end

    @generated_content = JSON.pretty_generate(json)
    @generated_content
  end

  def generate
    if !self[:target]
      self[:target] = self.find_new_bp_file
    end

    file_opts = {
      :ensure => self[:ensure] == :absent ? :absent : :file,
      :path => self[:target],
      :owner => self[:site],
      :group => self[:site],
      :mode => '0644',
    }
    
    bp_id = self[:target].match(/^.+\/(\d+)\.tbp$/)[1]

    #nagios_host_opts = {
    #  :name => "#{self[:name]}",
    #  :ensure => "#{self[:ensure].to_s.force_encoding('UTF-8')}",
    #  :use => self[:host_template],
    #  :host_name => self[:name],
    #  :nagios_alias => "Business Process: #{self[:name]}",
    #  :site => self[:site],
    #  :custom => {
    #    '_THRUK_BP_ID' => bp_id,
    #    '_THRUK_NODE_ID' => 'node1',
    #  },
    #  :target => "#{site_path}/etc/nagios/conf.d/thruk_bp_generated.cfg",
    #  :notify => "Omd::Site::Service[#{self[:site]}]",
    #}
    #
    #nagios_service_opts = {
    #  :name => "#{self[:name]}",
    #  :use => self[:service_template],
    #  :host_name => self[:name],
    #  :service_description => self[:name],
    #  :display_name => self[:display_name],
    #  :site => self[:site],
    #  :custom => {
    #    '_THRUK_BP_ID' => bp_id,
    #    '_THRUK_NODE_ID' => 'node1',
    #  },
    #  :target => "#{site_path}/etc/nagios/conf.d/thruk_bp_generated.cfg",
    #  :notify => "Omd::Site::Service[#{self[:site]}]",
    #}
    #nagios_service_opts[:notes] = self[:notes] if self[:notes]
    #nagios_service_opts[:servicegroups] = self[:servicegroups] if self[:servicegroups]

    [
      Puppet::Type.type(:file).new(file_opts),
      #Puppet::Type.type(:omd_nagios_host).new(nagios_host_opts),
      #Puppet::Type.type(:omd_nagios_service).new(nagios_service_opts)
    ]
  end

  def eval_generate
    content = should_content

    if !content.nil? and !content.empty?
      catalog.resource("File[#{self[:target]}]")[:content] = content
    end

    [
      catalog.resource("File[#{self[:target]}]"),
      #catalog.resource("Omd_nagios_host[#{self[:name]}]"),
      #catalog.resource("Omd_nagios_service[#{self[:name]}]")
    ]
  end

  def bp_path
    "#{site_path}/etc/thruk/bp"
  end

  def site_path
    "/omd/sites/#{self[:site]}"
  end


  def find_bp_file(name)
    Puppet.debug("FIND_BP_FILE(#{name})")
    Dir[bp_path + '/*.tbp'].each do |f|
      json = JSON.parse(File.read(f), { :symbolize_names => true })
      if json[:name] == name
        FileUtils.touch(f)
        Puppet.debug("FIND_BP_FILE #{name}: #{f}")
        return f
      end
    end
    Puppet.debug("FIND_BP_file #{name}: Not found")
    nil
  end

  def find_new_bp_file
    path = bp_path
    raise Puppet::Error, "Directory #{path} does not exists!!!" if !File.directory?(path)
    i = 1
    filename = "#{path}/#{i.to_s}.tbp"
    while File.file?(filename)
      i += 1
      filename = "#{path}/#{i.to_s}.tbp"
    end
    return filename
  end
end
