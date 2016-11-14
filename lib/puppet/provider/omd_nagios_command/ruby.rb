begin
  require 'puppet_x/omd'
rescue
  libdir = Pathname.new(__FILE__).parent.parent.parent.parent
  require File.join(libdir, 'puppet_x/omd')
end

Puppet::Type.type(:omd_nagios_command).provide(:ruby) do
  confine :feature => :augeas

  include Puppet_X::Omd

  defaultfor :osfamily => :debian

  mk_resource_methods

  def exists?
    @property_hash = load_resource_from_file(resource[:target], resource)
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def create
    @property_flush[:ensure] = :present
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def flush
    save_to_disk(resource)
  end
end
