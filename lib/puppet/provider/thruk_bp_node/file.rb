require 'puppetx/filemapper'
begin
  require 'puppet_x/omd/thruk'
rescue
  libdir = Pathname.new(__FILE__).parent.parent.parent.parent
  require File.join(libdir, 'puppet_x/omd/thruk')
end


Puppet::Type.type(:thruk_bp_node).provide(:file) do
  include PuppetX::FileMapper

  desc 'Filemapper provider for thruk_bp_node'

  has_feature :provider_options

  mk_resource_methods

  def select_file
    Puppet.debug("SELECT FILE: #{@resource[:target]}")
    Puppet.debug("SELECT FILE RESOURCE: #{@resource.to_s}")
    @resource[:target]
  end

  def self.target_files
    Puppet.debug("SELF.TARGET_FILES BEGIN")
    Dir[Puppet[:vardir] + '/thruk/node_*.json']
  end

  def self.parse_file(filename, contents)
    Puppet.debug("SELF.PARSE_FILE BEGIN(#{filename})")
    Puppet.debug("SELF.PARSE_FILE CONTENTS: #{contents}")
    #nodes = []
    #Puppet.debug("INTERNAL PATH: #{bp_internal_path}")
    #Dir[bp_internal_path + '/node_*.json'].each do |f|
      #Puppet.debug("SELF.PARSE_FILE: Parsing file #{f}")
      #properties = JSON.parse(File.read(f), { :symbolize_names => true })
      #nodes.push(properties)
    #end
    #nodes
    property_hash = nil
    if !contents.empty?
      [ JSON.parse(contents, { :symbolize_names => true } ) ]
    else
      [ {} ]
    end
  end

  def self.format_file(filename, providers)
    Puppet.debug("FORMAT_FILE(#{filename}, #{providers})")
    contents = []
    providers.sort_by(&:name).each do |provider|
      Puppet.debug("FORMAT FILE provider: #{provider} -> #{provider.name}")
      json = Hash.new
      json[:name] = provider.name
      json[:site] = provider.site
      json[:bp] = provider.bp
      json[:id] = provider.id
      json[:label] = provider.label
      json[:parent] = provider.parent
      json[:function] = provider.function
      json[:target] = provider.target
      json[:ensure] = provider.ensure
      Puppet.debug("FORMAT FILE json: #{JSON.pretty_generate(json)}")
      contents << JSON.pretty_generate(json)
    end
    Puppet.debug("FORMAT_FILE CONTENTS: #{contents.join}")
    contents.join
  end
end
