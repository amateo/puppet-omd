require 'json'

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
    @property_hash[:target] = self.class.bp_internal_path + '/node_' + resource[:name].gsub(' ', '_') + '.json'
  end

  def self.instances
    #ins = []
    #self.get_files.collect do |f|
      #self.load_from_file(f).collect do |node|
        #ins.push(new(node))
      #end
    #end
    #return ins
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
      File.delete(@property_hash[:target])
      fail("Fail synchronizing Thruk_bp_node[#{@property_hash[:name]}]")
    end
  end

  #
  ####################################################
  # Aux
  #

  def self.bp_internal_path
    return '/var/lib/puppet/thruk'
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


  ##
  #####################################################
  ## Aux
  ##
  
  #def self.get_files
    #files = Array.new
    #Dir['/omd/sites/*'].each do |d|
      #if File.directory?(d + '/etc/thruk/bp')
        #files += Dir[d + '/etc/thruk/bp/*.tbp']
      #end
    #end
    #return files
  #end

  #def self.load_from_file(filename)
    #site = filename.split('/')[3]
    #json = JSON.load(File.read(filename))
    #return [] if !json.has_key?('nodes')
    #bpnodes = []
    #nodes = json['nodes']
    #index = 0
    #nodes.each do |node|
      #bpnode = {}
      #bpnode[:ensure]   = :present
      #bpnode[:json]     = json
      #bpnode[:site]     = site
      #bpnode[:bp]       = nodes[0]['label']
      #bpnode[:name]     = site + '/' + bpnode[:bp] + '/' + node['id']
      #bpnode[:target]   = filename
      #bpnode[:id]       = node['id']
      #bpnode[:label]    = node['label'] if node['label']
      #bpnode[:function] = node['function'] if node['function']
      #bpnode[:index]    = index
      ## Buscamos si algún otro nodo depende de este
      #nodes.each do |node2|
        #if node2['depends'] and node2['depends'].include?(node['id'])
          #bpnode[:parent] = node2['id']
          #break
        #end
      #end
      #bpnodes.push(bpnode)
      #index += 1
    #end
    #bpnodes
  #end

  #def flush_disk
    #raise Puppet::Error, 'You must provide a site parameter' if !resource[:site]
    ## Load JSON file
    #filename = resource[:target] ? @property_hash[:target] : get_filename
    #if !filename
      #raise Puppet::Error, "Can't find BP for " + resource[:name]
    #end
    #File.open(@property_hash[:target], 'w') do |f|
      #f.puts JSON.pretty_generate(@property_hash[:json])
    #end
  #end

  #def get_filename
    #dir = '/omd/sites/' + resource[:site] + '/etc/thruk/bp'
    #Dir[dir + '/*'].each do |f|
      #json = JSON.load(File.read(f))
      #json['nodes'].each do |node|
        #if node['label'] == resource[:bp]
          #return f
        #end
      #end
    #end
    #return nil
  #end

  #def find_index(json, id)
    #return nil if !json.has_key?('nodes')
    #index = 0
    #json['nodes'].each do |node|
      #if node['id'] == id
        #return index
      #end
      #index += 1
    #end
    #return nil
  #end

  #def modify_parents(json, oldid, newid)
    #json['nodes'].collect do |node|
      #if node.has_key?('depends') and node['depends'].include?(oldid)
        #node['depends'].delete(oldid)
        #node['depends'].push(newid)
      #end
    #end
    #json
  #end

  #def switch_parent(json, old, new)
    #json['nodes'].collect do |node|
      #if node['id'] == old
        #node['depends'].delete(resource[:id])
      #elsif node['id'] == new
        #node['depends'].push(resource[:id])
      #end
    #end
    #json
  #end

  #def include_in_parent(json, id)
    #json['nodes'].collect do |node|
      #if node['id'] == id
        #node['depends'].push(resource[:id])
      #end
    #end
    #json
  #end

  #def modify_json
    ## Recargamos el json por si ha habido cambios de otros resources
    #json = JSON.load(File.read(@property_hash[:target]))
    #index = find_index(json, @property_hash[:id])
    #if index != nil
      #json['nodes'][index]['label'] = @property_flush[:label] if @property_flush[:label]
      #json['nodes'][index]['function'] = @property_flush[:function] if @property_flush[:function]
      #if @property_flush[:id]
        #json['nodes'][index]['id'] = @property_flush[:id]
        #json = modify_parents(json, @property_hash[:id], @property_flush[:id])
      #end
      #if @property_flush[:parent]
        #json = switch_parent(json, @property_hash[:parent], @property_flush[:parent])
      #end
    #else
      ## Es un thruk_bp_node nuevo
      #newnode = {}
      #newnode['label'] = @property_flush[:label] if @property_flush[:label]
      #newnode['function'] = @property_flush[:function] if @property_flush[:function]
      #newnode['id'] = @property_flush[:id] if @property_flush[:id]
      #if @property_flush[:parent]
        #include_in_parent(json, @property_flush[:parent])
      #end
      #json['nodes'].push(newnode)
    #end
    #@property_hash[:json] = json
  #end
end
