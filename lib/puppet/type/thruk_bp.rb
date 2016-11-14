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
          value.force_encoding('ASCII-8BIT')
        end
        return super(value)
      end
    end
  end

  def exists?
    self[:ensure] == :present
  end

  newparam(:name) do
    desc "The name"
    isnamevar
  end

  newparam(:state_type) do
    desc "Nagios state types used. 'both' uses soft and hard states. 'hard' only uses hard states"
    newvalues(:both, :hard)
    defaultto(:both)
  end

  newparam(:site) do
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

  #newparam(:core) do
    #desc 'Monitorization system core to use. Currently, oly nagios is supported'
    #newvalue(:nagios) do
      #provider.create
    #end
    #defaultto(:nagios)
  #end
  
  #newparam(:host_template, :parent => NagiosParam) do
  newparam(:host_template) do
    desc 'Nagios template to use for the nagios host object created'
    defaultto { 'thruk-bp-template' }

  end
  
  newparam(:service_template) do
    desc 'Nagios template to use for the nagios service object created'
    defaultto { 'thruk-bp-node-template' }
  end

  newparam(:host_name) do
  #newparam(:host_name, :parent => NagiosParam) do
    desc 'Name of the nagios host created'
    defaultto { @resource[:name] }
  end

  newparam(:servicegroups) do
    desc 'Nagios servicegroups this BP belongs to'
  end

  newparam(:notes) do
    desc 'Nagios notes for this BP service'
  end

  newparam(:display_name) do
    desc 'Nagios service diplay name'
    defaultto { @resource[:name] }
  end

  newparam(:function) do
    desc 'Function to use in the main node of the BP'
    defaultto { 'worst()' }
  end

  newparam(:rank_dir) do
    desc 'Graph direction. Valid values are TB (Top-Bottom) and LR (Left-Right)'
    newvalues(:TB, :LR)
    defaultto(:TB)
  end

  #newparam(:target) do
    #desc 'The file to store the BP definition'
    #defaultto { '/tmp/bp_' + @resource[:name].gsub(' ', '_').gsub('/', '_') + '.json' }
  #end

  #newparam(:bp_target) do
    #desc 'The path of the .tbp file'
    #defaultto {
      #Puppet.debug("BP_TARGET")
      #Puppet.debug("BP_TARGET TARGET: #{@resource[:target]}")
      #if File.file?(@resource[:target])
        #Puppet.debug("BP_TARGET Comprobando #{@resource[:target]}")
        #kk = JSON.parse(File.read(@resource[:target]), { :symbolize_names => true })[:bp_target]
        #Puppet.debug("BP_TARGET: #{kk}")
        #kk
      #else
        #Puppet.debug("BP_TARGET NEW FILE")
        #path = '/tmp'
        #raise Puppet::Error, 'Directory ' + dir + ' does not exists!!!' if !File.directory?(path)
        #i = 1
        #filename = path + '/' + i.to_s + '.tbp'
        #while File.file?(filename)
          #i += 1
          #filename = path + '/' + i.to_s + '.tbp'
        #end
        #filename
      #end
    #}
  #end

  #newparam(:bp_target) do
  newparam(:target) do
    desc 'The path of the .tbp file'
    defaultto {
      filename = @resource.find_bp_file(@resource[:name])
      if filename
        Puppet.debug("BP_TARGET FILE: #{filename}")
        filename
      else
        #filename = @resource.find_new_bp_file
        #Puppet.debug("BP_TARGET NEW FILE: #{filename}")
        #filename
        nil
      end
    }
  end

  autorequire(:thruk_bp_node) do
    Puppet.debug("THRUK_BP_NODE2 AUTOREQUIRE")
    catalog.resources.collect do |r|
      if r.is_a?(Puppet::Type.type(:thruk_bp_node)) && r[:bp] == self[:name]
        Puppet.debug("THRUK_BP_NODE2 require: #{r.name}")
        r.name
      end
    end.compact
  end

  autorequire(:file) do
    [self[:target]]
  end

  #autorequire(:'omd::site') do
    #[self[:site]]
  #end

  #autorequire(:nagios_host) do
    #Puppet.debug("AUTOREQUIRE: nagios_host[#{self[:host_name]}]")
    #[self[:host_name]]
  #end

  def should_content
    Puppet.debug("SHOULD_CONTENT BEGIN")
    return @generated_content if @generated_content
    @generated_content = ""

    resources = catalog.resources.sort_by(&:name).select do |r|
      r.is_a?(Puppet::Type.type(:thruk_bp_node)) && r[:bp] == self[:name]
    end
    Puppet.debug("SHOULD_CONTENT RESOURCES: #{resources.map { |r| r[:name] }}")

    # Atributos del BP
    json = Hash.new
    json[:rankDir] = self[:rank_dir] if self[:rank_dir]
    json[:state_type] = self[:state_type] if self[:state_type]
    json[:name] = self[:host_name] if self[:host_name]
    json[:template] = self[:host_template] if self[:host_template]

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
      node[:function] = r[:function] if r[:function]
      node[:label] = r[:name]
      node[:id] = r[:id]
      node[:template] = self[:service_template] if self[:service_template]
      depended_resources = resources.select do |r2|
        r2[:parent] == r[:id]
      end.map do |r2|
        r2[:id]
      end
      node[:depends] = depended_resources if !depended_resources.empty?
      json[:nodes] << node
    end

    #Puppet.debug("SHOULD_CONTENT RESOURCES: #{resources.to_s}")
    Puppet.debug("SHOULD CONTENT END")
    @generated_content = JSON.pretty_generate(json)
    @generated_content
  end

  def generate
    #Puppet.debug("THRUK_BP2: GENERATE")
    if !self[:target]
      Puppet.debug("GENERATE: #{self[:name]} NIL TARGET")
      self[:target] = self.find_new_bp_file
      Puppet.debug("GENERATE: #{self[:name]} -> #{self[:target]}")
    end

    file_opts = {
      :ensure => self[:ensure] == :absent ? :absent : :file,
      :path => self[:target],
      :owner => 'root',
      :group => 'root',
      :mode => '0644',
    }
    #Puppet.debug("GENERATE PEPE1")
    
    bp_id = self[:target].match(/^.+\/(\d+)\.tbp$/)[1]
    Puppet.debug("GENERATE BP ID: #{bp_id}")

    nagios_host_opts = {
      :name => "#{self[:host_name]}",
      :ensure => self[:ensure],
      :use => self[:host_template],
      :host_name => self[:host_name],
      :nagios_alias => "Business Process: #{self[:host_name]}",
      :site => self[:site],
      :custom => {
        '_THRUK_BP_ID' => bp_id,
        '_THRUK_NODE_ID' => 'node1',
      },
      :target => "#{site_path}/etc/nagios/conf.d/thruk_bp_generated.cfg",
      #:target => "#{site_path}/thruk_bp_generated.cfg",
      #:notify => "Omd::Site::Service[#{self[:site]}]",
    }
    Puppet.debug("GENERATE NAGIOS HASH: #{nagios_host_opts}")

    nagios_service_opts = {
      :name => "#{self[:name]}",
      :use => self[:service_template],
      :host_name => self[:host_name],
      :service_description => self[:name],
      :display_name => self[:display_name],
      :site => self[:site],
      :custom => {
        '_THRUK_BP_ID' => bp_id,
        '_THRUK_NODE_ID' => 'node1',
      },
      :target => "#{site_path}/etc/nagios/conf.d/thruk_bp_generated.cfg",
      #:target => "#{site_path}/thruk_bp_generated.cfg",
      #:notify => "Omd::Site::Service[#{self[:site]}]",
    }

    [
      Puppet::Type.type(:file).new(file_opts),
      Puppet::Type.type(:omd_nagios_host).new(nagios_host_opts),
      Puppet::Type.type(:omd_nagios_service).new(nagios_service_opts)
    ]
  end

  def eval_generate
    Puppet.debug("EVAL_GENERATE BEGIN")
    content = should_content

    #Puppet.debug("EVAL_GENERATE CONTENT: #{content}")
    if !content.nil? and !content.empty?
      #Puppet.debug("EVAL_GENERATE CONTENT NIL: #{catalog.resource("File[#{self[:target]}]").to_hash}")
      catalog.resource("File[#{self[:target]}]")[:content] = content
    end

    [
      catalog.resource("File[#{self[:target]}]"),
      catalog.resource("Omd_nagios_host[#{self[:host_name]}]"),
      catalog.resource("Omd_nagios_service[#{self[:name]}]")
    ]
    #[ catalog.resource("File[#{self[:target]}_kk]") ]
    #Puppet.debug("EVAL_GENERATE END")
  end

  def bp_path
    #path = "/omd/sites/#{self[:site]}/etc/thruk/bp"
    #Puppet.debug("BP_PATH: #{path}")
    "/omd/sites/#{self[:site]}/etc/thruk/bp"
  end

  def site_path
    path = "/omd/sites/#{self[:site]}"
    ##Puppet.debug("SITE_PATH: #{path}")
    #path = '/tmp'
    #path
  end


  def find_bp_file(name)
    #Puppet.debug("FIND_BP_FILE(#{name})")
    #Puppet.debug("FIND_BP_FILE PATH: #{bp_path}")
    Dir[bp_path + '/*.tbp'].each do |f|
      #Puppet.debug("FILE_BP_FILE Checking file #{f}")
      json = JSON.parse(File.read(f), { :symbolize_names => true })
      #Puppet.debug("FILE_BP_FILE FILE BP name: #{json[:name]}")
      if json[:name] == name
        FileUtils.touch(f)
        return f
      end
    end
    #Puppet.debug("FIND_BP_FILE END")
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
