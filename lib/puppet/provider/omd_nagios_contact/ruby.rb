begin
  require 'puppet_x/omd'
rescue
  libdir = Pathname.new(__FILE__).parent.parent.parent.parent
  require File.join(libdir, 'puppet_x/omd')
end

Puppet::Type.type(:omd_nagios_contact).provide(:ruby) do
  confine :feature => :augeas

  include Puppet_X::Omd

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

  def self.instances
    ins = []
    Puppet_X::Omd::get_files(:omd_nagios_contact).collect do |f|
      Puppet_X::Omd::load_resources_from_file(:omd_nagios_contact, f).collect do |nc|
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
