Puppet::Type.type(:omd_nagios_service).provide(:ruby) do
  confine :feature => :augeas

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

  def site=(value)
    @property_flush[:site] = value
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
        files.push(d + '/etc/nagios/conf.d/services_puppet.cfg') if File.exists?(d + '/etc/nagios/conf.d/services_puppet.cfg')
      end
    end
    return files
  end

  def self.load_from_file(filename)
    aug_path = '/files' + filename
    services = Array.new
    if match = filename.match(/^\/omd\/sites\/([^\/]+)\/.+$/)
      site = match[1]
    end
    if File.exists?(filename)
      # Abrimos el fichero con augeas
      aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(:lens => 'nagiosobjects.lns', :incl => filename)
      aug.load

      aug.match(aug_path + '/*').each do |entry|
        if entry.match(/^#{aug_path}\/service(\[\d+\])?$/)
          hash = Hash.new
          hash[:ensure] = :present
          aug.match(entry + '/*').each do |attr|
            name = (match = attr.match(/^.+\/([^\/]+)$/)) ? match[1] : nil
            if name.match(/^#comment/)
              if match2 = aug.get(attr).match(/^# --PUPPET_NAME-- \(called '_naginator_name' in the manifest\)\s+(.+)$/)
                hash[:name] = match2[1]
              end
            end
            case name
              when 'naginator_name' then hash[:naginator_name] = aug.get(attr)
              when 'action_url' then hash[:action_url] = aug.get(attr)
              when 'active_checks_enabled' then hash[:active_checks_enabled] = aug.get(attr)
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
              when 'host_name' then hash[:host_name] = aug.get(attr)
              when 'hostgroup_name' then hash[:hostgroup_name] = aug.get(attr)
              when 'icon_image' then hash[:icon_image] = aug.get(attr)
              when 'icon_image_alt' then hash[:icon_image_alt] = aug.get(attr)
              when 'initial_state' then hash[:initial_state] = aug.get(attr)
              when 'is_volatile' then hash[:is_volatile] = aug.get(attr)
              when 'low_flap_threshold' then hash[:low_flap_threshold] = aug.get(attr)
              when 'max_check_attempts' then hash[:max_check_attempts] = aug.get(attr)
              when 'normal_check_interval' then hash[:normal_check_interval] = aug.get(attr)
              when 'notes' then hash[:notes] = aug.get(attr)
              when 'notes_url' then hash[:notes_url] = aug.get(attr)
              when 'notification_interval' then hash[:notification_interval] = aug.get(attr)
              when 'notification_options' then hash[:notification_options] = aug.get(attr)
              when 'notification_period' then hash[:notification_period] = aug.get(attr)
              when 'notifications_enabled' then hash[:notifications_enabled] = aug.get(attr)
              when 'obsess_over_service' then hash[:obsess_over_service] = aug.get(attr)
              when 'parallelize_check' then hash[:parallelize_check] = aug.get(attr)
              when 'passive_checks_enabled' then hash[:passive_checks_enabled] = aug.get(attr)
              when 'poller_tag' then hash[:poller_tag] = aug.get(attr)
              when 'process_perf_data' then hash[:process_perf_data] = aug.get(attr)
              when 'register' then hash[:register] = aug.get(attr)
              when 'retain_nonstatus_information' then hash[:retain_nonstatus_information] = aug.get(attr)
              when 'retain_status_information' then hash[:retain_status_information] = aug.get(attr)
              when 'retry_check_interval' then hash[:retry_check_interval] = aug.get(attr)
              when 'retry_interval' then hash[:retry_interval] = aug.get(attr)
              when 'service_description' then hash[:service_description] = aug.get(attr)
              when 'servicegroups' then hash[:servicegroups] = aug.get(attr)
              when 'stalking_options' then hash[:stalking_options] = aug.get(attr)
              when 'use' then hash[:use] = aug.get(attr)
              when 'name' then hash[:name] = aug.get(attr)
              else hash[name] = aug.get(attr)
            end
          end
          hash[:aug_entry] = entry
          hash[:target] = filename
          hash[:name] = hash[:service_name] if !hash[:name]
          hash[:site] = site ? site : ''
          services.push(hash)
        end
      end
      return services
    else
      return nil
    end
  end

  def save_to_disk
    raise Puppet::Error, 'You must provide a site paramater' if !resource[:site]
    filename = resource[:target] ? @resource[:target] : '/omd/sites/' + resource[:site] + '/etc/nagios/conf.d/services_puppet.cfg'
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
        service_entry = @property_hash[:aug_entry]
        # Comprobamos si el aug_entry sigue siendo válido.
        # Si no, volvemos a buscar la entrada augeas que corresponde
        # (bug TLM-784)
        if (aug.get(service_entry + '/name') != @resource[:name])
          aug.match('/files' + filename + '/*').each do |entry|
            if (aug.get(entry + '/name') == @resource[:name])
              @property_hash[:aug_entry] = entry
              service_entry = entry
            end
          end
        end
      else
        # Busco el último service en augeas
        last_service = 0
        aug.match('/files' + filename + '/*').each do |entry|
          if entry.match(/^.+\/service(\[\d+\])?$/)
            service_number = (match = entry.match(/^.+\/service\[(\d+)\]$/)) ? match[1].to_i : 1
            last_service = service_number if service_number > last_service
          end
        end
        service_entry = '/files' + filename + '/service[' + (last_service + 1).to_s + ']'
      end

      if @property_flush[:ensure] == :absent
        aug.rm(service_entry)
      else
        save_with_augeas(aug, service_entry)
      end
    end

    aug.save
    aug.close
  end

  def change_site(name, oldsite, newsite)
    oldfile = "/omd/sites/#{oldsite}/etc/nagios/conf.d/services_puppet.cfg"
    newfile = resource[:target] ? @resource[:target] : "/omd/sites/#{newsite}/etc/nagios/conf.d/services_puppet.cfg"

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
      if entry.match(/^.+\/service(\[\d+\])?$/)
        number = (match = entry.match(/^.+\/service\[(\d+)\]$/)) ? match[1].to_i : 1
        last = number if number > last
      end
    end
    entry = '/files' + newfile + '/service[' + (last + 1).to_s + ']'
    save_with_augeas(newaug, entry)

    oldaug.save
    oldaug.close
    newaug.save
    newaug.close
  end

  def save_with_augeas(aug, entry)
    set_value(aug, entry, 'name', @resource[:name]) if @resource[:name]
    set_value(aug, entry, 'action_url', @resource[:action_url]) if @resource[:action_url]
    set_value(aug, entry, 'active_checks_enabled', @resource[:active_checks_enabled]) if @resource[:active_checks_enabled]
    set_value(aug, entry, 'business_impact', @resource[:business_impact]) if @resource[:business_impact]
    set_value(aug, entry, 'check_command', @resource[:check_command]) if @resource[:check_command]
    set_value(aug, entry, 'check_freshness', @resource[:check_freshness]) if @resource[:check_freshness]
    set_value(aug, entry, 'check_interval', @resource[:check_interval]) if @resource[:check_interval]
    set_value(aug, entry, 'check_period', @resource[:check_period]) if @resource[:check_period]
    set_value(aug, entry, 'contact_groups', @resource[:contact_groups]) if @resource[:contact_groups]
    set_value(aug, entry, 'contacts', @resource[:contacts]) if @resource[:contacts]
    set_value(aug, entry, 'display_name', @resource[:display_name]) if @resource[:display_name]
    set_value(aug, entry, 'event_handler', @resource[:event_handler]) if @resource[:event_handler]
    set_value(aug, entry, 'event_handler_enabled', @resource[:event_handler_enabled]) if @resource[:event_handler_enabled]
    set_value(aug, entry, 'failure_prediction_enabled', @resource[:failure_prediction_enabled]) if @resource[:failure_prediction_enabled]
    set_value(aug, entry, 'first_notification_delay', @resource[:first_notification_delay]) if @resource[:first_notification_delay]
    set_value(aug, entry, 'flap_detection_enabled', @resource[:flap_detection_enabled]) if @resource[:flap_detection_enabled]
    set_value(aug, entry, 'flap_detection_options', @resource[:flap_detection_options]) if @resource[:flap_detection_options]
    set_value(aug, entry, 'freshness_threshold', @resource[:freshness_threshold]) if @resource[:freshness_threshold]
    set_value(aug, entry, 'high_flap_threshold', @resource[:high_flap_threshold]) if @resource[:high_flap_threshold]
    set_value(aug, entry, 'host_name', @resource[:host_name]) if @resource[:host_name]
    set_value(aug, entry, 'hostgroup_name', @resource[:hostgroup_name]) if @resource[:hostgroup_name]
    set_value(aug, entry, 'icon_image', @resource[:icon_image]) if @resource[:icon_image]
    set_value(aug, entry, 'icon_image_alt', @resource[:icon_image_alt]) if @resource[:icon_image_alt]
    set_value(aug, entry, 'initial_state', @resource[:initial_state]) if @resource[:initial_state]
    set_value(aug, entry, 'is_volatile', @resource[:is_volatile]) if @resource[:is_volatile]
    set_value(aug, entry, 'low_flap_threshold', @resource[:low_flap_threshold]) if @resource[:low_flap_threshold]
    set_value(aug, entry, 'max_check_attempts', @resource[:max_check_attempts]) if @resource[:max_check_attempts]
    set_value(aug, entry, 'normal_check_interval', @resource[:normal_check_interval]) if @resource[:normal_check_interval]
    set_value(aug, entry, 'notes', @resource[:notes]) if @resource[:notes]
    set_value(aug, entry, 'notes_url', @resource[:notes_url]) if @resource[:notes_url]
    set_value(aug, entry, 'notification_interval', @resource[:notification_interval]) if @resource[:notification_interval]
    set_value(aug, entry, 'notification_options', @resource[:notification_options]) if @resource[:notification_options]
    set_value(aug, entry, 'notification_period', @resource[:notification_period]) if @resource[:notification_period]
    set_value(aug, entry, 'notifications_enabled', @resource[:notifications_enabled]) if @resource[:notifications_enabled]
    set_value(aug, entry, 'obsess_over_service', @resource[:obsess_over_service]) if @resource[:obsess_over_service]
    set_value(aug, entry, 'parallelize_check', @resource[:parallelize_check]) if @resource[:parallelize_check]
    set_value(aug, entry, 'passive_checks_enabled', @resource[:passive_checks_enabled]) if @resource[:passive_checks_enabled]
    set_value(aug, entry, 'poller_tag', @resource[:poller_tag]) if @resource[:poller_tag]
    set_value(aug, entry, 'process_perf_data', @resource[:process_perf_data]) if @resource[:process_perf_data]
    set_value(aug, entry, 'register', @resource[:register]) if @resource[:register]
    set_value(aug, entry, 'retain_nonstatus_information', @resource[:retain_nonstatus_information]) if @resource[:retain_nonstatus_information]
    set_value(aug, entry, 'retain_status_information', @resource[:retain_status_information]) if @resource[:retain_status_information]
    set_value(aug, entry, 'retry_check_interval', @resource[:retry_check_interval]) if @resource[:retry_check_interval]
    set_value(aug, entry, 'retry_interval', @resource[:retry_interval]) if @resource[:retry_interval]
    set_value(aug, entry, 'service_description', @resource[:service_description]) if @resource[:service_description]
    set_value(aug, entry, 'servicegroups', @resource[:servicegroups]) if @resource[:servicegroups]
    set_value(aug, entry, 'stalking_options', @resource[:stalking_options]) if @resource[:stalking_options]
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
