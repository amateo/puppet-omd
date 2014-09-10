require 'json'

Puppet::Type.type(:thruk_bp_node).provide(:ruby) do
  defaultfor :osfamily => :debian

  mk_resource_methods

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def create
    @property_flush[:ensure] = :present
  end

  def self.instances
    ins = []
    self.get_files.collect do |f|
      self.load_from_file(f).collect do |node|
        ins.push(new(node))
      end
    end
    return ins
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
    save_to_disk
  end

  #
  ####################################################
  # Aux
  #

  def self.get_files
    files = Array.new
    Dir['/omd/sites/*'].each do |d|
      if File.directory?(d + '/etc/thruk/bp')
        files += Dir[d + '/etc/thruk/bp/*.tbp']
      end
    end
    return files
  end

  def self.load_from_file(filename)
    site = filename.split('/')[3]
    json = JSON.load(File.read(filename))
    return nil if !json.has_key?('nodes')
    nodes = json['nodes']
    nodes.collect do |node|
      node[:ensure]   = :present
      node[:site]     = site
      node[:bp]       = nodes[0]['label']
      node[:name]     = site + '/' + node[:bp] + '/' + node['id']
      node[:target]   = filename
      node[:id]       = node['id']
      node[:label]    = node['label'] if node['label']
      node[:function] = node['function'] if node['function']
      # Buscamos si algún otro nodo depende de este
      nodes.each do |node2|
        if node2['depends'] and node2['depends'].include?(node['id'])
          node[:parent] = node2['id']
          break
        end
      end
    end
    nodes
  end

  def save_to_disk
    raise Puppet::Error, 'You must provide a site parameter' if !resource[:site]
    # Load JSON file
    filename = resource[:target] ? @property_hash[:target] : get_filename
    if !filename
      raise Puppet::Error, "Can't find BP for " + resource[:name]
    end
    json = JSON.load(File.read(filename))
    nodes = json['nodes']
    if @property_flush[:ensure] == :absent
      index = nil
      nodes.each_index do |idx|
        node = nodes[idx]
        if node['depends'] and node['depends'].include?(@property_hash[:id])
          node['depends'].delete(@property_hash[:id])
        end
        if node['id'] == @property_hash[:id]
          index = idx
        end
      end
      if index != nil
        nodes.delete_at(index)
      end
    else
      # Busco el nodo...
      updated = false
      updated_parent = false
      nodes.each do |node|
        if node['id'] == resource[:id]
          node['label'] = resource[:label]
          node['function'] = resource[:function]
          updated = true
        else
          if node['id'] == resource[:parent]
            if node['depends']
              node['depends'].push(resource[:id]) if !node['depends'].include?(resource[:id])
            else
              node['depends'] = [ resource[:id] ]
            end
            updated_parent = true
          else
            node['depends'].delete(resource[:id]) if node['depends']
          end
        end
      end
      # Si no he actualizado, es que es un node nuevo
      if !updated
        nodes.push( {
          'id' => resource[:id],
          'label' => resource[:label],
          'function' => resource[:function]
        } )
      end
      warning('No parent found for ' + resource[:id] + ' BP node') if !updated_parent
    end
    #file = File.open('/tmp/kk.tbp', 'w')
    file = File.open(filename, 'w')
    file.write(JSON.pretty_generate(json))
    file.close
  end

  def get_filename
    dir = '/omd/sites/' + resource[:site] + '/etc/thruk/bp'
    Dir[dir + '/*'].each do |f|
      json = JSON.load(File.read(f))
      json['nodes'].each do |node|
        if node['label'] == resource[:bp]
          return f
        end
      end
    end
    return nil
  end
end
