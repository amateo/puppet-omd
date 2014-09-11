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
    save_nagios_objects

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

  def save_nagios_objects
    # Abrimos el fichero con augeas
    path = '/omd/sites/' + resource[:site] + '/etc/nagios/conf.d/thruk_bp_generated.cfg'
    aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
    aug.transform(:lens => "nagiosobjects.lns", :incl => path)
    aug.load

    if match = get_filename.match(/^.+\/([^\/]+)\.tbp/)
      bp_id = match[1]
    end
    host_entry = nil
    service_entry = nil
    last_host = 0
    last_service = 0
    aug.match('/files/' + path + '/*').each do |entry|
      if match = entry.match(/^.+\/host\[(\d+)\]$/)
        host_number = match[1].to_i
        last_host = host_number if host_number > last_host
        entry_id = aug.get(entry + '/_THRUK_BP_ID')
        if entry_id == bp_id
          host_entry = entry
        end
      elsif match = entry.match(/^.+\/service\[(\d+)\]$/)
        service_number = match[1].to_i
        last_service = service_number if service_number > last_service
        entry_id = aug.get(entry + '/_THRUK_BP_ID')
        if entry_id == bp_id
          service_entry = entry
        end
      end
    end
    aug_host_path = host_entry ?
      host_entry : '/files' + path + '/host[' + (last_host + 1).to_s + ']'
    aug_service_path = service_entry ?
      service_entry : '/files' + path + '/service[' + (last_service + 1).to_s + ']'
    host_template = resource[:host_template] ? resource[:host_template] : 'thruk-bp-template'
    service_template = resource[:service_template] ? resource[:service_template] : 'thruk-bp-node-template'
    aug.set(aug_host_path + '/use', host_template)
    aug.set(aug_host_path + '/host_name', resource[:host_name])
    aug.set(aug_host_path + '/alias', 'Business Process: ' + resource[:host_name])
    aug.set(aug_host_path + '/_THRUK_BP_ID', bp_id)
    aug.set(aug_host_path + '/_THRUK_NODE_ID', 'node1')
    aug.set(aug_service_path + '/use', service_template)
    aug.set(aug_service_path + '/host_name', resource[:host_name])
    aug.set(aug_service_path + '/service_description', resource[:name])
    aug.set(aug_service_path + '/display_name', resource[:name])
    aug.set(aug_service_path + '/_THRUK_BP_ID', bp_id)
    aug.set(aug_service_path + '/_THRUK_NODE_ID', 'node1')

    aug.save
    aug.close
  end
end
