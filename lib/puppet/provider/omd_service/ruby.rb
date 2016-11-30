begin
  require 'puppet_x/test'
rescue
  libdir = Pathname.new(__FILE__).parent.parent.parent.parent
  require File.join(libdir, 'puppet_x/test')
end

Puppet::Type.type(:omd_service).provide(:ruby) do
  confine :feature => :augeas

  include Puppet_X::Test

  defaultfor :osfamily => :debian

  mk_resource_methods

  def exists?
    if resource[:target] and !resource[:target].empty?
      @property_hash = load_resource_from_file(resource[:target], resource)
    end
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def create
    @property_flush[:ensure] = :present
  end

  def site=(value)
    @property_flush[:site] = value
  end

  def self.instances
    ins = []
    Puppet_X::Test::get_files(:omd_service).collect do |f|
      Puppet.debug("SELF.INSTANCES File: #{f}")
      Puppet_X::Test::load_resources_from_file(:omd_service, f).collect do |nc|
        ins << new(nc)
      end
    end
    ins
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
    save_to_disk(resource)
  end
end
