require 'json'
require 'yaml'

Puppet::Type.type(:thruk_bp).provide(:ruby) do
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
    self.get_files.collect do |f|
      bp_properties = self.load_from_file(f)
      new(bp_properties)
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
    save_to_disk

    # Collect the resources again once they've been changed (that way `puppet
    # resource` will show the correct values after changes have been made).
    @property_hash = self.class.load_from_file(@property_hash[:target])
  end



  #
  #################################################################
  #
  
  def to_hash
    hash = Hash.new
    hash['rankDir'] = 'TB'
    hash['state_type'] = resource[:state_type]
    hash['name'] = resource[:host_name]
    hash['template'] = resource[:host_template] if resource[:host_template]
    if @property_hash.has_key?(:nodes)
      hash['nodes'] = @property_hash[:nodes]
    else
      node = {
        'function' => 'worst()',
        'label'    => resource[:name],
        'id'       => 'node1',
      }
      node['template'] = resource[:service_template] if resource[:service_template]
      hash['nodes'] = [ node ]
    end
    return hash
  end

  def get_filename
    if @property_hash.has_key?(:target)
      return @property_hash[:target]
    else
      dir = '/omd/sites/' + resource[:site] + '/etc/thruk/bp'
      raise Puppet::Error, 'Directory ' + dir + ' does not exists!!!' if !File.directory?(dir)
      files = Dir[dir + '/*.tbp'].collect! do |x|
        x = File.basename(x).split('.')[0]
      end
      @property_hash[:target] = dir + '/' + (files.sort[files.length-1].to_i + 1).to_s + '.tbp'
      return @property_hash[:target]
    end
  end

  #
  #########################################################
  # Para el self.instances
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
    if File.exists?(filename)
      hash_tmp = JSON.load(File.read(filename))
      hash = Hash.new
      hash[:ensure] = :present
      hash[:host_template] = hash_tmp['template']
      hash[:state_type] = hash_tmp['state_type']
      hash[:name] = hash_tmp['nodes'][0]['label']
      hash[:target] = filename
      hash[:site] = filename.split('/')[3]
      hash[:nodes] = hash_tmp['nodes']
      hash[:host_name] = hash_tmp['name']
      return hash
    else
      return nil
    end
  end

  def save_to_disk
    raise Puppet::Error, 'You must provide a site paramater' if !resource[:site]
    if @property_flush[:ensure] == :absent
      File.delete(@property_hash[:target])
    else
      file = File.open(get_filename, 'w')
      file.write(JSON.pretty_generate(to_hash))
      file.close
    end
  end
end
