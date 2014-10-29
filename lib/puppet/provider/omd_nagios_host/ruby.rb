require 'augeas'

Puppet::Type.type(:omd_nagios_host).provide(:ruby) do
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
        files.push(d + '/etc/nagios/conf.d/hosts_puppet.cfg') if File.exists?(d + '/etc/nagios/conf.d/hosts_puppet.cfg')
      end
    end
    return files
  end

  def self.load_from_file(filename)
    aug_path = '/files' + filename
    hosts = Array.new
    if match = filename.match(/^\/omd\/sites\/([^\/]+)\/.+$/)
      site = match[1]
    end
    if File.exists?(filename)
      # Abrimos el fichero con augeas
      aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(:lens => 'nagiosobjects.lns', :incl => filename)
      aug.load

      aug.match(aug_path + '/*').each do |entry|
        if entry.match(/^#{aug_path}\/host(\[\d+\])?$/)
          hash = Hash.new
          hash[:ensure] = :present
          aug.match(entry + '/*').each do |attr|
            name = (match = attr.match(/^.+\/([^\/]+)$/)) ? match[1] : nil
            case name
              when 'host_name' then hash[:host_name] = aug.get(attr)
              when 'action_url' then hash[:action_url] = aug.get(attr)
              when 'active_checks_enabled' then hash[:active_checks_enabled] = aug.get(attr)
              when 'address' then hash[:address] = aug.get(attr)
              when 'alias' then hash[:nagios_alias] = aug.get(attr)
              when 'business_impact' then hash[:business_impact] = aug.get(attr)
              when 'check_command' then hash[:check_command] = aug.get(attr)
              when 'check_freshness' then hash[:check_freshness] = aug.get(attr)
              when 'check_interval' then hash[:check_interval] = aug.get(attr)
              when 'check_period' then hash[:check_period] = aug.get(attr)
              when 'contact_groups' then hash[:contact_groups] = aug.get(attr)
              when 'contacts' then hash[:contacts] = aug.get(attr)
              when 'display_name' then hash[:display_name] = aug.get(attr)
              when 'event_handler' then hash[:event_handler] = aug.get(attr)
              when 'event_handler_enabled' then hash[:event_handler_enabled] = aug.get(attr)
              when 'failure_prediction_enabled' then hash[:failure_prediction_enabled] = aug.get(attr)
              when 'first_notification_delay' then hash[:first_notification_delay] = aug.get(attr)
              when 'flap_detection_enabled' then hash[:flap_detection_enabled] = aug.get(attr)
              when 'flap_detection_options' then hash[:flap_detection_options] = aug.get(attr)
              when 'freshness_threshold' then hash[:freshness_threshold] = aug.get(attr)
              when 'high_flap_threshold' then hash[:high_flap_threshold] = aug.get(attr)
              when 'hostgroups' then hash[:hostgroups] = aug.get(attr)
              when 'icon_image' then hash[:icon_image] = aug.get(attr)
              when 'icon_image_alt' then hash[:icon_image_alt] = aug.get(attr)
              when 'initial_state' then hash[:initial_state] = aug.get(attr)
              when 'low_flap_threshold' then hash[:low_flap_threshold] = aug.get(attr)
              when 'max_check_attempts' then hash[:max_check_attempts] = aug.get(attr)
              when 'notes' then hash[:notes] = aug.get(attr)
              when 'notes_url' then hash[:notes_url] = aug.get(attr)
              when 'notification_interval' then hash[:notification_interval] = aug.get(attr)
              when 'notification_options' then hash[:notification_options] = aug.get(attr)
              when 'notification_period' then hash[:notification_period] = aug.get(attr)
              when 'notifications_enabled' then hash[:notifications_enabled] = aug.get(attr)
              when 'obsess_over_host' then hash[:obsess_over_host] = aug.get(attr)
              when 'parents' then hash[:parents] = aug.get(attr)
              when 'passive_checks_enabled' then hash[:passive_checks_enabled] = aug.get(attr)
              when 'poller_tag' then hash[:poller_tag] = aug.get(attr)
              when 'process_perf_data' then hash[:process_perf_data] = aug.get(attr)
              when 'realm' then hash[:realm] = aug.get(attr)
              when 'register' then hash[:register] = aug.get(attr)
              when 'retain_nonstatus_information' then hash[:retain_nonstatus_information] = aug.get(attr)
              when 'retain_status_information' then hash[:retain_status_information] = aug.get(attr)
              when 'retry_interval' then hash[:retry_interval] = aug.get(attr)
              when 'stalking_options' then hash[:stalking_options] = aug.get(attr)
              when 'statusmap_image' then hash[:statusmap_image] = aug.get(attr)
              when 'use' then hash[:use] = aug.get(attr)
              when 'vrml_image' then hash[:vrml_image] = aug.get(attr)
              when 'name' then hash[:name] = aug.get(attr)
              else hash[name] = aug.get(attr)
            end
          end
          hash[:aug_entry] = entry
          hash[:target] = filename
          hash[:name] = hash[:host_name] if !hash[:name]
          hash[:site] = site ? site : ''
          hosts.push(hash)
        end
      end
      return hosts
    else
      return nil
    end
  end

  def save_to_disk
    raise Puppet::Error, 'You must provide a site paramater' if !resource[:site]
    filename = resource[:target] ? @resource[:target] : '/omd/sites/' + resource[:site] + '/etc/nagios/conf.d/hosts_puppet.cfg'
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
        host_entry = @property_hash[:aug_entry]
        # Comprobamos si el aug_entry sigue siendo válido.
        # Si no, volvemos a buscar la entrada augeas que corresponde
        # (bug TLM-784)
        if (aug.get(host_entry + '/name') != @resource[:name])
          aug.match('/files' + filename + '/*').each do |entry|
            if (aug.get(entry + '/name') == @resource[:name])
              @property_hash[:aug_entry] = entry
              host_entry = entry
            end
          end
        end
      else
        # Busco el último host en augeas
        last_host = 0
        aug.match('/files' + filename + '/*').each do |entry|
          if entry.match(/^.+\/host(\[\d+\])?$/)
            host_number = (match = entry.match(/^.+\/host\[(\d+)\]$/)) ? match[1].to_i : 1
            last_host = host_number if host_number > last_host
          end
        end
        host_entry = '/files' + filename + '/host[' + (last_host + 1).to_s + ']'
      end

      if @property_flush[:ensure] == :absent
        aug.rm(host_entry)
      else
        save_with_augeas(aug, host_entry)
      end
    end

    aug.save
    aug.close
  end

  def change_site(name, oldsite, newsite)
    oldfile = "/omd/sites/#{oldsite}/etc/nagios/conf.d/hosts_puppet.cfg"
    newfile = resource[:target] ? @resource[:target] : "/omd/sites/#{newsite}/etc/nagios/conf.d/hosts_puppet.cfg"

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
      if entry.match(/^.+\/host(\[\d+\])?$/)
        number = (match = entry.match(/^.+\/host\[(\d+)\]$/)) ? match[1].to_i : 1
        last = number if number > last
      end
    end
    entry = '/files' + newfile + '/host[' + (last + 1).to_s + ']'
    save_with_augeas(newaug, entry)

    oldaug.save
    oldaug.close
    newaug.save
    newaug.close
  end

  def save_with_augeas(aug, entry)
    aug.set(entry + '/name', resource[:name]) if resource[:name]
    aug.set(entry + '/host_name', resource[:host_name]) if resource[:host_name]
    aug.set(entry + '/action_url', resource[:action_url]) if resource[:action_url]
    aug.set(entry + '/active_checks_enabled', resource[:active_checks_enabled]) if resource[:active_checks_enabled]
    aug.set(entry + '/address', resource[:address]) if resource[:address]
    aug.set(entry + '/alias', resource[:nagios_alias]) if resource[:nagios_alias]
    aug.set(entry + '/business_impact', resource[:business_impact]) if resource[:business_impact]
    aug.set(entry + '/check_command', resource[:check_command]) if resource[:check_command]
    aug.set(entry + '/check_freshness', resource[:check_freshness]) if resource[:check_freshness]
    aug.set(entry + '/check_interval', resource[:check_interval]) if resource[:check_interval]
    aug.set(entry + '/check_period', resource[:check_period]) if resource[:check_period]
    aug.set(entry + '/contact_groups', resource[:contact_groups]) if resource[:contact_groups]
    aug.set(entry + '/contacts', resource[:contacts]) if resource[:contacts]
    aug.set(entry + '/display_name', resource[:display_name]) if resource[:display_name]
    aug.set(entry + '/event_handler', resource[:event_handler]) if resource[:event_handler]
    aug.set(entry + '/event_handler_enabled', resource[:event_handler_enabled]) if resource[:event_handler_enabled]
    aug.set(entry + '/failure_prediction_enabled', resource[:failure_prediction_enabled]) if resource[:failure_prediction_enabled]
    aug.set(entry + '/first_notification_delay', resource[:first_notification_delay]) if resource[:first_notification_delay]
    aug.set(entry + '/flap_detection_enabled', resource[:flap_detection_enabled]) if resource[:flap_detection_enabled]
    aug.set(entry + '/flap_detection_options', resource[:flap_detection_options]) if resource[:flap_detection_options]
    aug.set(entry + '/freshness_threshold', resource[:freshness_threshold]) if resource[:freshness_threshold]
    aug.set(entry + '/high_flap_threshold', resource[:high_flap_threshold]) if resource[:high_flap_threshold]
    aug.set(entry + '/hostgroups', resource[:hostgroups]) if resource[:hostgroups]
    aug.set(entry + '/icon_image', resource[:icon_image]) if resource[:icon_image]
    aug.set(entry + '/icon_image_alt', resource[:icon_image_alt]) if resource[:icon_image_alt]
    aug.set(entry + '/initial_state', resource[:initial_state]) if resource[:initial_state]
    aug.set(entry + '/low_flap_threshold', resource[:low_flap_threshold]) if resource[:low_flap_threshold]
    aug.set(entry + '/max_check_attempts', resource[:max_check_attempts]) if resource[:max_check_attempts]
    aug.set(entry + '/notes', resource[:notes]) if resource[:notes]
    aug.set(entry + '/notes_url', resource[:notes_url]) if resource[:notes_url]
    aug.set(entry + '/notification_interval', resource[:notification_interval]) if resource[:notification_interval]
    aug.set(entry + '/notification_options', resource[:notification_options]) if resource[:notification_options]
    aug.set(entry + '/notification_period', resource[:notification_period]) if resource[:notification_period]
    aug.set(entry + '/notifications_enabled', resource[:notifications_enabled]) if resource[:notifications_enabled]
    aug.set(entry + '/obsess_over_host', resource[:obsess_over_host]) if resource[:obsess_over_host]
    aug.set(entry + '/parents', resource[:parents]) if resource[:parents]
    aug.set(entry + '/passive_checks_enabled', resource[:passive_checks_enabled]) if resource[:passive_checks_enabled]
    aug.set(entry + '/poller_tag', resource[:poller_tag]) if resource[:poller_tag]
    aug.set(entry + '/process_perf_data', resource[:process_perf_data]) if resource[:process_perf_data]
    aug.set(entry + '/realm', resource[:realm]) if resource[:realm]
    aug.set(entry + '/register', resource[:register]) if resource[:register]
    aug.set(entry + '/retain_nonstatus_information', resource[:retain_nonstatus_information]) if resource[:retain_nonstatus_information]
    aug.set(entry + '/retain_status_information', resource[:retain_status_information]) if resource[:retain_status_information]
    aug.set(entry + '/retry_interval', resource[:retry_interval]) if resource[:retry_interval]
    aug.set(entry + '/stalking_options', resource[:stalking_options]) if resource[:stalking_options]
    aug.set(entry + '/statusmap_image', resource[:statusmap_image]) if resource[:statusmap_image]
    aug.set(entry + '/use', resource[:use]) if resource[:use]
    aug.set(entry + '/vrml_image', resource[:vrml_image]) if resource[:vrml_image]
  end
end
