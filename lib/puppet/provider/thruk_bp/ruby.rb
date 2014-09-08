require 'json'

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
    @property_hash = self.class.load_from_file(@property_hash[:file])
  end



  #
  #################################################################
  #
  
  def to_hash
    hash = Hash.new
    hash['rankDir'] = 'TB'
    hash['template'] = ''
    hash['state_type'] = resource[:state_type]
    hash['name'] = resource[:name]
    hash['template'] = resource[:host_template]

    return hash
  end

  def get_filename
    if @property_hash.has_key?(:file)
      return @property_hash[:file]
    else
      files = Dir['/tmp/bp_maps/*.tbp'].collect! do |x|
        x = File.basename(x).split('.')[0]
      end
      @property_hash[:file] = '/tmp/bp_maps/' + (files.sort[files.length-1].to_i + 1).to_s + '.tbp'
      return @property_hash[:file]
    end
  end

  #
  #########################################################
  # Para el self.instances
  #

  def self.get_files
    return Array.new unless File.directory?('/tmp/bp_maps')
    return Dir['/tmp/bp_maps/*.tbp']
  end

  def self.load_from_file(filename)
    if File.exists?(filename)
      hash_tmp = JSON.load(File.read(filename))
      hash = Hash.new
      hash[:ensure] = :present
      hash[:host_template] = hash_tmp['template']
      hash[:state_type] = hash_tmp['state_type']
      hash[:name] = hash_tmp['name']
      hash[:file] = filename
      return hash
    else
      return nil
    end
  end

  def save_to_disk
    if @property_flush[:ensure] == :absent
      File.delete(@property_hash[:file])
    else
      file = File.open(get_filename, 'w')
      JSON.dump(to_hash, file)
      file.close
    end
  end
end
