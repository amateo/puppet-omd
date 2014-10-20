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

    if @property_hash[:aug_entry] and @property_hash[:aug_entry].match(/^\/files#{filename}\//)
      contact_entry = @property_hash[:aug_entry]
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
      aug.set(contact_entry + '/contact_name', resource[:contact_name]) if resource[:contact_name]
      aug.set(contact_entry + '/address1', resource[:address1]) if resource[:address1]
      aug.set(contact_entry + '/address2', resource[:address2]) if resource[:address2]
      aug.set(contact_entry + '/address3', resource[:address3]) if resource[:address3]
      aug.set(contact_entry + '/address4', resource[:address4]) if resource[:address4]
      aug.set(contact_entry + '/address5', resource[:address5]) if resource[:address5]
      aug.set(contact_entry + '/address6', resource[:address6]) if resource[:address6]
      aug.set(contact_entry + '/alias', resource[:nagios_alias]) if resource[:nagios_alias]
      aug.set(contact_entry + '/can_submit_commands', resource[:can_submit_commands]) if resource[:can_submit_commands]
      aug.set(contact_entry + '/contactgroups', resource[:contactgroups]) if resource[:contactgroups]
      aug.set(contact_entry + '/email', resource[:email]) if resource[:email]
      aug.set(contact_entry + '/group', resource[:group]) if resource[:group]
      aug.set(contact_entry + '/host_notification_commands', resource[:host_notification_commands]) if resource[:host_notification_commands]
      aug.set(contact_entry + '/host_notification_options', resource[:host_notification_options]) if resource[:host_notification_options]
      aug.set(contact_entry + '/host_notification_period', resource[:host_notification_period]) if resource[:host_notification_period]
      aug.set(contact_entry + '/host_notifications_enabled', resource[:host_notifications_enabled]) if resource[:host_notifications_enabled]
      aug.set(contact_entry + '/mode', resource[:mode]) if resource[:mode]
      aug.set(contact_entry + '/pager', resource[:pager]) if resource[:pager]
      aug.set(contact_entry + '/register', resource[:register]) if resource[:register]
      aug.set(contact_entry + '/retain_nonstatus_information', resource[:retain_nonstatus_information]) if resource[:retain_nonstatus_information]
      aug.set(contact_entry + '/retain_status_information', resource[:retain_status_information]) if resource[:retain_status_information]
      aug.set(contact_entry + '/service_notification_commands', resource[:service_notification_commands]) if resource[:service_notification_commands]
      aug.set(contact_entry + '/service_notification_options', resource[:service_notification_options]) if resource[:service_notification_options]
      aug.set(contact_entry + '/service_notification_period', resource[:service_notification_period]) if resource[:service_notification_period]
      aug.set(contact_entry + '/service_notifications_enabled', resource[:service_notifications_enabled]) if resource[:service_notifications_enabled]
      aug.set(contact_entry + '/use', resource[:use]) if resource[:use]
      aug.set(contact_entry + '/name', resource[:name]) if resource[:name]
    end

    aug.save
    aug.close
  end
end
