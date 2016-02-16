require 'augeas'

Puppet::Type.type(:omd_nagios_servicegroup).provide(:ruby) do
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
        files.push(d + '/etc/nagios/conf.d/servicegroups_puppet.cfg') if File.exists?(d + '/etc/nagios/conf.d/servicegroups_puppet.cfg')
      end
    end
    return files
  end

  def self.load_from_file(filename)
    aug_path = '/files' + filename
    servicegroups = Array.new
    if match = filename.match(/^\/omd\/sites\/([^\/]+)\/.+$/)
      site = match[1]
    end
    if File.exists?(filename)
      # Abrimos el fichero con augeas
      aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(:lens => 'nagiosobjects.lns', :incl => filename)
      aug.load

      aug.match(aug_path + '/*').each do |entry|
        if entry.match(/^#{aug_path}\/servicegroup(\[\d+\])?$/)
          hash = Hash.new
          hash[:ensure] = :present
          aug.match(entry + '/*').each do |attr|
            name = (match = attr.match(/^.+\/([^\/]+)$/)) ? match[1] : nil
            case name
              when 'servicegroup_name' then hash[:servicegroup_name] = aug.get(attr)
              when 'action_url' then hash[:action_url] = aug.get(attr)
              when 'alias' then hash[:nagios_alias] = aug.get(attr)
              when 'servicegroup_members' then hash[:servicegroup_members] = aug.get(attr)
              when 'members' then hash[:members] = aug.get(attr)
              when 'notes' then hash[:notes] = aug.get(attr)
              when 'notes_url' then hash[:notes_url] = aug.get(attr)
              when 'realm' then hash[:realm] = aug.get(attr)
              when 'register' then hash[:register] = aug.get(attr)
              when 'use' then hash[:use] = aug.get(attr)
              when 'name' then hash[:name] = aug.get(attr)
              else hash[name] = aug.get(attr)
            end
          end
          hash[:aug_entry] = entry
          hash[:target] = filename
          hash[:name] = hash[:servicegroup_name] if !hash[:name]
          hash[:site] = site ? site : ''
          servicegroups.push(hash)
        end
      end
      return servicegroups
    else
      return nil
    end
  end

  def save_to_disk
    raise Puppet::Error, 'You must provide a site paramater' if !resource[:site]
    filename = resource[:target] ? @resource[:target] : '/omd/sites/' + resource[:site] + '/etc/nagios/conf.d/servicegroups_puppet.cfg'
    aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
    aug.transform(:lens => 'nagiosobjects.lns', :incl => filename)
    aug.load

    # Comprobamos si el atributo cambiado es el site. En este caso
    # la operación es un poco especial, porque hay que borrar del fichero
    # antiguo y crear en el nuevo
    if (@resource[:site] != @property_hash[:site])
      change_site(@resource[:name], @property_hash[:site], @resource[:site])
    else
      if @property_hash[:aug_entry] and @property_hash[:aug_entry].match(/^\/files#{filename}\//)
        servicegroup_entry = @property_hash[:aug_entry]
        # Comprobamos si el aug_entry sigue siendo válido.
        # Si no, volvemos a buscar la entrada augeas que corresponde
        # (bug TLM-784)
        if (aug.get(servicegroup_entry + '/name') != @resource[:name])
          aug.match('/files' + filename + '/*').each do |entry|
            if (aug.get(entry + '/name') == @resource[:name])
              @property_hash[:aug_entry] = entry
              servicegroup_entry = entry
            end
          end
        end
      else
        # Busco el último servicegroup en augeas
        last_servicegroup = 0
        aug.match('/files' + filename + '/*').each do |entry|
          if entry.match(/^.+\/servicegroup(\[\d+\])?$/)
            servicegroup_number = (match = entry.match(/^.+\/servicegroup\[(\d+)\]$/)) ? match[1].to_i : 1
            last_servicegroup = servicegroup_number if servicegroup_number > last_servicegroup
          end
        end
        servicegroup_entry = '/files' + filename + '/servicegroup[' + (last_servicegroup + 1).to_s + ']'
      end

      if @property_flush[:ensure] == :absent
        aug.rm(servicegroup_entry)
      else
        save_with_augeas(aug, servicegroup_entry)
      end
    end

    aug.save
    aug.close
  end

  def change_site(name, oldsite, newsite)
    oldfile = "/omd/sites/#{oldsite}/etc/nagios/conf.d/servicegroups_puppet.cfg"
    newfile = resource[:target] ? @resource[:target] : "/omd/sites/#{newsite}/etc/nagios/conf.d/servicegroups_puppet.cfg"

    newaug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
    newaug.transform(:lens => 'nagiosobjects.lns', :incl => newfile)
    newaug.load
    oldaug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
    oldaug.transform(:lens => 'nagiosobjects.lns', :incl => oldfile)
    oldaug.load

    # Buscamos en el viejo y borramos
    oldaug.match('/files' + oldfile + '/*').each do |entry|
      if (oldaug.get(entry + '/name') == @resource[:name])
        oldaug.rm(entry)
        break
      end
    end

    # Añadimos en el nuevo
    last = 0
    newaug.match('/files' + newfile + '/*').each do |entry|
      if entry.match(/^.+\/servicegroup(\[\d+\])?$/)
        number = (match = entry.match(/^.+\/servicegroup\[(\d+)\]$/)) ? match[1].to_i : 1
        last = number if number > last
      end
    end
    entry = '/files' + newfile + '/servicegroup[' + (last + 1).to_s + ']'
    save_with_augeas(newaug, entry)

    oldaug.save
    oldaug.close
    newaug.save
    newaug.close
  end

  def save_with_augeas(aug, entry)
    set_value(aug, entry, 'name', @resource[:name]) if @resource[:name]
    set_value(aug, entry, 'servicegroup_name', @resource[:servicegroup_name]) if @resource[:servicegroup_name]
    set_value(aug, entry, 'action_url', @resource[:action_url]) if @resource[:action_url]
    set_value(aug, entry, 'alias', @resource[:nagios_alias]) if @resource[:nagios_alias]
    set_value(aug, entry, 'servicegroup_members', @resource[:servicegroup_members]) if @resource[:servicegroup_members]
    set_value(aug, entry, 'members', @resource[:members]) if @resource[:members]
    set_value(aug, entry, 'notes', @resource[:notes]) if @resource[:notes]
    set_value(aug, entry, 'notes_url', @resource[:notes_url]) if @resource[:notes_url]
    set_value(aug, entry, 'register', @resource[:register]) if @resource[:register]
    set_value(aug, entry, 'use', @resource[:use]) if @resource[:use]
  end

  def set_value(aug, entry, attr, value)
    if value != :absent
      aug.set(entry + "/#{attr}", value)
    else
      aug.rm(entry + "/#{attr}")
    end
  end
end
