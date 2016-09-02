begin
  require 'puppet_x/omd/thruk'
rescue
  libdir = Pathname.new(__FILE__).parent.parent.parent.parent
  require File.join(libdir, 'puppet_x/omd/thruk')
end


Puppet::Type.type(:thruk_bp_node).provide(:ruby) do
  confine :feature => :json
  defaultfor :osfamily => :debian
  include Puppet_X::Omd::Thruk

  mk_resource_methods

  def exists?
    return !@property_hash.empty?
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def create
    @property_hash[:ensure] = :present
    @property_hash[:name] = resource[:name]
    @property_hash[:site] = resource[:site]
    @property_hash[:bp]   = resource[:bp]
    @property_hash[:id]   = resource[:id]
    @property_hash[:label] = resource[:label]
    @property_hash[:parent] = resource[:parent]
    @property_hash[:function] = resource[:function]
    @property_hash[:target] = get_node_filename(resource[:name])
  end

  def self.instances
    self.load_nodes.collect do |node|
      new(node)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def flush
    begin
      parent = get_bp_node(@property_hash)
      if @property_flush[:ensure] == :absent
        File.delete(@property_hash[:target]) if File.file?(@property_hash[:target])
        # TODO: Actualizar BP
        @property_hash = []
      else
        flush_json
        # TODO: Actualizar BP
        # Collect the resources again once they've been changed (that way `puppet
        # resource` will show the correct values after changes have been made).
        @property_hash = self.class.load_node(@property_hash[:target])
      end
      to_json(parent)
    rescue
      # Si la sicronización al .tbp falla, entonces borro el json del node.
      # Así la próxima vez volverá a ejecutarse
      File.delete(@property_hash[:target])
      fail("Fail synchronizing Thruk_bp_node[#{@property_hash[:name]}]")
    end
  end

  #
  ####################################################
  # Aux
  #

  def self.bp_internal_path
    Puppet.debug("BP_INTERNAL_PATH: #{Puppet[:vardir]}/thruk")
    return "#{Puppet[:vardir]}/thruk"
  end

  def self.load_nodes
    nodes = []
    Dir[bp_internal_path + '/node_*.json'].each do |f|
      @property_hash = JSON.parse(File.read(f), { :symbolize_names => true })
      nodes.push(@property_hash)
    end
    nodes
  end

  def self.load_node(filename)
    begin
      json = JSON.parse(File.read(filename), { :symbolize_names => true })
      return json
    rescue
      return nil
    end
  end

  def flush_json
    if !File.directory?(self.class.bp_internal_path) and !File.file?(self.class.bp_internal_path)
      Dir.mkdir(self.class.bp_internal_path)
    elsif File.file?(self.class.bp_internal_path)
      raise Puppet::Error, "Can't create " + self.class.bp_internal_path + ' directory. It already exists as file'
    end
    filename = @property_hash[:target]
    File.open(filename, 'w') do |f|
      f.puts JSON.pretty_generate(@property_hash)
    end
  end
end
