require 'augeas'

Puppet::Type.type(:omd_nagios_contactgroup).provide(:ruby) do
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
      self.load_from_file(f).collect do |nc|
        ins.push(new(nc))
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
  #####################################################################
  # Funciones auxiliares
  #

  def self.get_files
    files = Array.new
    Dir['/omd/sites/*']. each do |d|
      if File.directory?(d + '/etc/nagios/conf.d')
        files.push(d + '/etc/nagios/conf.d/contactgroups_puppet.cfg') if File.exists?(d + '/etc/nagios/conf.d/contactgroups_puppet.cfg')
      end
    end
    return files
  end

  def self.load_from_file(filename)
    aug_path = '/files' + filename
    contactgroups = Array.new
    if match = filename.match(/^\/omd\/sites\/([^\/]+)\/.+$/)
      site = match[1]
    end
    if File.exists?(filename)
      # Abrimos el fichero con augeas
      aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(:lens => 'nagiosobjects.lns', :incl => filename)
      aug.load

      aug.match(aug_path + '/*').each do |entry|
        if entry.match(/^#{aug_path}\/contactgroup(\[\d+\])?$/)
          hash = Hash.new
          hash[:ensure] = :present
          aug.match(entry + '/*').each do |attr|
            name = (match = attr.match(/^.+\/([^\/]+)$/)) ? match[1] : nil
            case name
              when 'contactgroup_name' then hash[:contactgroup_name] = aug.get(attr)
              when 'alias' then hash[:nagios_alias] = aug.get(attr)
              when 'contactgroup_members' then hash[:contactgroup_members] = aug.get(attr)
              when 'members' then hash[:members] = aug.get(attr)
              when 'register' then hash[:register] = aug.get(attr)
              when 'use' then hash[:use] = aug.get(attr)
              when 'name' then hash[:name] = aug.get(attr)
              else hash[name] = aug.get(attr)
            end
          end
          hash[:aug_entry] = entry
          hash[:target] = filename
          hash[:name] = hash[:contactgroup_name] if !hash[:name]
          hash[:site] = site ? site : ''
          contactgroups.push(hash)
        end
      end
      return contactgroups
    else
      return nil
    end
  end

  def save_to_disk
    raise Puppet::Error, 'You must provide a site paramater' if !resource[:site]
    filename = resource[:target] ? @resource[:target] : '/omd/sites/' + resource[:site] + '/etc/nagios/conf.d/contactgroups_puppet.cfg'
    aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
    aug.transform(:lens => 'nagiosobjects.lns', :incl => filename)
    aug.load

    if @property_hash[:aug_entry] and @property_hash[:aug_entry].match(/^\/files#{filename}\//)
      contactgroup_entry = @property_hash[:aug_entry]
    else
      # Busco el último contactgroup en augeas
      last_contactgroup = 0
      aug.match('/files' + filename + '/*').each do |entry|
        if entry.match(/^.+\/contactgroup(\[\d+\])?$/)
          contactgroup_number = (match = entry.match(/^.+\/contactgroup\[(\d+)\]$/)) ? match[1].to_i : 1
          last_contactgroup = contactgroup_number if contactgroup_number > last_contactgroup
        end
      end
      contactgroup_entry = '/files' + filename + '/contactgroup[' + (last_contactgroup + 1).to_s + ']'
    end

    if @property_flush[:ensure] == :absent
      aug.rm(contactgroup_entry)
    else
      aug.set(contactgroup_entry + '/contactgroup_name', resource[:contactgroup_name]) if resource[:contactgroup_name]
      aug.set(contactgroup_entry + '/alias', resource[:nagios_alias]) if resource[:nagios_alias]
      aug.set(contactgroup_entry + '/contactgroup_members', resource[:contactgroup_members]) if resource[:contactgroup_members]
      aug.set(contactgroup_entry + '/members', resource[:members]) if resource[:members]
      aug.set(contactgroup_entry + '/register', resource[:register]) if resource[:register]
      aug.set(contactgroup_entry + '/use', resource[:use]) if resource[:use]
      aug.set(contactgroup_entry + '/name', resource[:name]) if resource[:name]
    end

    aug.save
    aug.close
  end
end
