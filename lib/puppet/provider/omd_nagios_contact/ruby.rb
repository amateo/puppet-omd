require 'augeas'

Puppet::Type.type(:omd_nagios_contact).provide(:ruby) do
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
        files.push(d + '/etc/nagios/conf.d/contacts_puppet.cfg') if File.exists?(d + '/etc/nagios/conf.d/contacts_puppet.cfg')
      end
    end
    return files
  end

  def self.load_from_file(filename)
    aug_path = '/files' + filename
    contacts = Array.new
    if match = filename.match(/^\/omd\/sites\/([^\/]+)\/.+$/)
      site = match[1]
    end
    if File.exists?(filename)
      # Abrimos el fichero con augeas
      aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(:lens => 'nagiosobjects.lns', :incl => filename)
      aug.load

      aug.match(aug_path + '/*').each do |entry|
        if entry.match(/^#{aug_path}\/contact(\[\d+\])?$/)
          hash = Hash.new
          hash[:ensure] = :present
          aug.match(entry + '/*').each do |attr|
            name = (match = attr.match(/^.+\/([^\/]+)$/)) ? match[1] : nil
            case name
              when 'contact_name' then hash[:contact_name] = aug.get(attr)
              when 'address1' then hash[:address1] = aug.get(attr)
              when 'address2' then hash[:address2] = aug.get(attr)
              when 'address3' then hash[:address3] = aug.get(attr)
              when 'address4' then hash[:address4] = aug.get(attr)
              when 'address5' then hash[:address5] = aug.get(attr)
              when 'address6' then hash[:address6] = aug.get(attr)
              when 'alias' then hash[:nagios_alias] = aug.get(attr)
              when 'can_submit_commands' then hash[:can_submit_commands] = aug.get(attr)
              when 'contactgroups' then hash[:contactgroups] = aug.get(attr)
              when 'email' then hash[:email] = aug.get(attr)
              when 'group' then hash[:group] = aug.get(attr)
              when 'host_notification_commands' then hash[:host_notification_commands] = aug.get(attr)
              when 'host_notification_options' then hash[:host_notification_options] = aug.get(attr)
              when 'host_notification_period' then hash[:host_notification_period] = aug.get(attr)
              when 'host_notifications_enabled' then hash[:host_notifications_enabled] = aug.get(attr)
              when 'mode' then hash[:mode] = aug.get(attr)
              when 'pager' then hash[:pager] = aug.get(attr)
              when 'register' then hash[:register] = aug.get(attr)
              when 'retain_nonstatus_information' then hash[:retain_nonstatus_information] = aug.get(attr)
              when 'retain_status_information' then hash[:retain_status_information] = aug.get(attr)
              when 'service_notification_commands' then hash[:service_notification_commands] = aug.get(attr)
              when 'service_notification_options' then hash[:service_notification_options] = aug.get(attr)
              when 'service_notification_period' then hash[:service_notification_period] = aug.get(attr)
              when 'service_notifications_enabled' then hash[:service_notifications_enabled] = aug.get(attr)
              when 'use' then hash[:use] = aug.get(attr)
              when 'name' then hash[:name] = aug.get(attr)
              else hash[name] = aug.get(attr)
            end
          end
          hash[:aug_entry] = entry
          hash[:target] = filename
          hash[:name] = hash[:contact_name] if !hash[:name]
          hash[:site] = site ? site : ''
          contacts.push(hash)
        end
      end
      return contacts
    else
      return nil
    end
  end

  def save_to_disk
    raise Puppet::Error, 'You must provide a site paramater' if !resource[:site]
    filename = resource[:target] ? @resource[:target] : '/omd/sites/' + resource[:site] + '/etc/nagios/conf.d/contacts_puppet.cfg'
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
        contact_entry = @property_hash[:aug_entry]
        # Comprobamos si el aug_entry sigue siendo válido.
        # Si no, volvemos a buscar la entrada augeas que corresponde
        # (bug TLM-784)
        if (aug.get(contact_entry + '/name') != @resource[:name])
          aug.match('/files' + filename + '/*').each do |entry|
            if (aug.get(entry + '/name') == @resource[:name])
              @property_hash[:aug_entry] = entry
              contact_entry = entry
            end
          end
        end
      else
        # Busco el último contact en augeas
        last_contact = 0
        aug.match('/files' + filename + '/*').each do |entry|
          if entry.match(/^.+\/contact(\[\d+\])?$/)
            contact_number = (match = entry.match(/^.+\/contact\[(\d+)\]$/)) ? match[1].to_i : 1
            last_contact = contact_number if contact_number > last_contact
          end
        end
        contact_entry = '/files' + filename + '/contact[' + (last_contact + 1).to_s + ']'
      end

      if @property_flush[:ensure] == :absent
        aug.rm(contact_entry)
      else
        save_with_augeas(aug, contact_entry)
      end
    end

    aug.save
    aug.close
  end

  def change_site(name, oldsite, newsite)
    oldfile = "/omd/sites/#{oldsite}/etc/nagios/conf.d/contacts_puppet.cfg"
    newfile = resource[:target] ? @resource[:target] : "/omd/sites/#{newsite}/etc/nagios/conf.d/contacts_puppet.cfg"

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
      if entry.match(/^.+\/contact(\[\d+\])?$/)
        number = (match = entry.match(/^.+\/contact\[(\d+)\]$/)) ? match[1].to_i : 1
        last = number if number > last
      end
    end
    entry = '/files' + newfile + '/contact[' + (last + 1).to_s + ']'
    save_with_augeas(newaug, entry)

    oldaug.save
    oldaug.close
    newaug.save
    newaug.close
  end

  def save_with_augeas(aug, entry)
    set_value(aug, entry, 'contact_name', @resource[:contact_name]) if @resource[:contact_name]
    set_value(aug, entry, 'address1', @resource[:address1]) if @resource[:address1]
    set_value(aug, entry, 'address2', @resource[:address2]) if @resource[:address2]
    set_value(aug, entry, 'address3', @resource[:address3]) if @resource[:address3]
    set_value(aug, entry, 'address4', @resource[:address4]) if @resource[:address4]
    set_value(aug, entry, 'address5', @resource[:address5]) if @resource[:address5]
    set_value(aug, entry, 'address6', @resource[:address6]) if @resource[:address6]
    set_value(aug, entry, 'alias', @resource[:nagios_alias]) if @resource[:nagios_alias]
    set_value(aug, entry, 'can_submit_commands', @resource[:can_submit_commands]) if @resource[:can_submit_commands]
    set_value(aug, entry, 'contactgroups', @resource[:contactgroups]) if @resource[:contactgroups]
    set_value(aug, entry, 'email', @resource[:email]) if @resource[:email]
    set_value(aug, entry, 'group', @resource[:group]) if @resource[:group]
    set_value(aug, entry, 'host_notification_commands', @resource[:host_notification_commands]) if @resource[:host_notification_commands]
    set_value(aug, entry, 'host_notification_options', @resource[:host_notification_options]) if @resource[:host_notification_options]
    set_value(aug, entry, 'host_notification_period', @resource[:host_notification_period]) if @resource[:host_notification_period]
    set_value(aug, entry, 'host_notifications_enabled', @resource[:host_notifications_enabled]) if @resource[:host_notifications_enabled]
    set_value(aug, entry, 'mode', @resource[:mode]) if @resource[:mode]
    set_value(aug, entry, 'pager', @resource[:pager]) if @resource[:pager]
    set_value(aug, entry, 'register', @resource[:register]) if @resource[:register]
    set_value(aug, entry, 'retain_nonstatus_information', @resource[:retain_nonstatus_information]) if @resource[:retain_nonstatus_information]
    set_value(aug, entry, 'retain_status_information', @resource[:retain_status_information]) if @resource[:retain_status_information]
    set_value(aug, entry, 'service_notification_commands', @resource[:service_notification_commands]) if @resource[:service_notification_commands]
    set_value(aug, entry, 'service_notification_options', @resource[:service_notification_options]) if @resource[:service_notification_options]
    set_value(aug, entry, 'service_notification_period', @resource[:service_notification_period]) if @resource[:service_notification_period]
    set_value(aug, entry, 'service_notifications_enabled', @resource[:service_notifications_enabled]) if @resource[:service_notifications_enabled]
    set_value(aug, entry, 'use', @resource[:use]) if @resource[:use]
    set_value(aug, entry, 'name', @resource[:name]) if @resource[:name]
  end

  def set_value(aug, entry, attr, value)
    if value != :absent
      aug.set(entry + "/#{attr}", value)
    else
      aug.rm(entry + "/#{attr}")
    end
  end
end
