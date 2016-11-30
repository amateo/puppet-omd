module Puppet_X
  module Test

    def test
    end

    def load_resource_from_file(filename, resource)
      
      property_map = Puppet_X::Test::map_properties(resource.class)

      object_prefix = Puppet_X::Test::object_prefix(resource.type)

      object = {}
      custom = {}
      aug_path = '/files' + filename
      if File.exists?(filename)
        # Abrimos el fichero con augeas
        aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
        aug.transform(:lens => 'nagiosobjects.lns', :incl => filename)
        aug.load

        key = Puppet_X::Test::key_attr(resource.type)
        matchs = aug.match(aug_path + "/#{object_prefix}[#{key} = \"#{resource[:name]}\"]")
        if matchs.length > 0
          aug.match("#{matchs[0]}/*").each do |attr|
            name = (match = attr.match(/^.+\/([^\/]+)$/)) ? match[1] : nil
            if name.start_with?('_')
              custom[name] = aug.get(attr)
            elsif property_map.has_key?(name)
              object[property_map[name]] = aug.get(attr)
            end
          end
          object[:ensure] = :present
          object[:custom] = custom if !custom.empty?
        end
      end
      object
    end

    def self.load_resources_from_file(type, file)
      Puppet.debug("SELF.LOAD_RESOURCES(#{type}, #{file})")
      property_map = map_properties(Puppet::Type.type(type))
      object_prefix = object_prefix(type)

      objects = []
      key = key_attr(type)
      if File.exists?(file)
        Puppet.debug("SELF.LOAD_RESOURCES Leyendo fichero #{file}")
        # Abrimos el fichero con augeas
        aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
        aug.transform(:lens => 'nagiosobjects.lns', :incl => file)
        aug.load

        aug_path = "/files#{file}"

        Puppet.debug("SELF.LOAD_RESOURCES Empezando augeas")
        kk = aug.match("#{aug_path}/*")
        Puppet.debug("SELF.LOAD_RESOURCES Match: #{kk.to_s}")
        aug.match("#{aug_path}/*").select do |m|
          Puppet.debug("SELF.LOAD_RESOURCES Filtrando atributo: #{m}")
          m =~ /^#{aug_path}\/#{object_prefix}(\[\d+\])?$/
        end.each do |entry|
          Puppet.debug("SELF.LOAD_RESOURCES Procesando entry: #{entry}")
          object = {}
          custom = {}
          object[:ensure] = :present
          aug.match("#{entry}/*").each do |attr|
            Puppet.debug("SELF.LOAD_RESOURCES Parsing atributo: #{attr}")
            name = (match = attr.match(/^.+\/([^\/]+)$/)) ? match[1] : nil
            if name.start_with?('_')
              custom[name] = aug.get(attr)
            elsif property_map.has_key?(name)
              object[property_map[name]] = aug.get(attr)
            elsif name == 'name'
              object[:name] = aug.get(attr)
            end
          end
          object[:custom] = custom if !custom.empty?
          object[:name] = object[property_map[key]] if !object[:name]
          objects << object
        Puppet.debug("SELF.LOAD_RESOURCES Fin fichero #{file}")
        end
      end
      Puppet.debug("SELF.LOAD_RESOURCES END")
      objects
    end

    def self.get_files(type)
      files = []
      sites.each do |s|
        filename = file_path_for_object(type, s)
        if File.exists?(filename)
          Puppet.debug("Añadiendo fichero: #{filename}")
          files << filename
        end
      end
      files
    end

    def save_to_disk(resource)
      raise Puppet::Error, 'You must provide a site paramater' if !resource.propertydefined?(:site)
      if !resource[:target] or resource[:target] == ''
        resource[:target] = Puppet_X::Test::file_path_for_object(resource.type, resource[:site])
        Puppet.debug("#{resource[:name]}: Assigning default target to #{resource[:target]}")
      end

      # Abrimos fichero con augeas
      aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(:lens => 'nagiosobjects.lns', :incl => resource[:target])
      aug.load


      prefix = Puppet_X::Test::object_prefix(resource.type)
      property_map = Puppet_X::Test::map_properties(resource.class)

      key = Puppet_X::Test::key_attr(resource.type)
      if resource[:ensure] == :absent
        aug.rm("/files#{resource[:target]}/#{prefix}[#{key} = \"#{resource[:name]}\"]")
      else

        aug_prefix = "/files#{resource[:target]}/#{prefix}"
        if aug.match("/#{aug_prefix}[#{key} = \"#{resource[:name]}\"]").length == 0
          aug.set("#{aug_prefix}[last+1]/#{key}", resource[:name])
        end
        aug_entry = "#{aug_prefix}[#{key} = \"#{resource[:name]}\"]"
        property_map.select {|k, v| !k.match(/^(ensure|custom)$/)}.each do |k, v|
          set_value(aug, aug_entry, k, resource[v]) if resource[v]
        end
        if property_map.include?('custom') and resource[:custom]
          resource[:custom].each do |k, v|
            set_value(aug, aug_entry, k, v)
          end
        end
      end

      aug.save
      aug.close
    end

    def self.base_path
      '/omd/sites'
      '/tmp/sites'
    end

    def self.file_path_for_object(object_class, site)
      filename = case object_class
      when :omd_nagios_command
        'commands_puppet.cfg'
      when :omd_nagios_contactgroup
        'contactgroups_puppet.cfg'
      when :omd_nagios_contact
        'contacts_puppet.cfg'
      when :omd_nagios_host
        'hosts_puppet.cfg'
      when :omd_nagios_hostgroup
        'hostgroups_puppet.cfg'
      when :omd_nagios_service
        'services_puppet.cfg'
      when :omd_nagios_servicegroup
        'servicegroups_puppet.cfg'
      when :omd_service
        'omd_services_puppet.cfg'
      end
      "#{base_path}/#{site}/etc/nagios/conf.d/#{filename}"
    end

    def self.map_properties(object_class)
      property_map = {}
      object_class.validproperties.each do |p|
        case p
        when :nagios_alias
          property_map['alias'] = :nagios_alias
        else
          property_map[p.to_s.sub(/:/, '')] = p
        end
      end
      case object_class
      when :omd_nagios_host
        property_map['name'] = :name
      when :omd_nagios_service
        property_map['name'] = :name
      end
      # Hacemos algunos apaños
      property_map
    end

    def set_value(aug, entry, attr, value)
      if value != :absent
        aug.set("#{entry}/#{attr}", value)
      else
        aug.rm("#{entry}/#{attr}")
      end
    end

    def self.object_prefix(object_class)
      case object_class
      when :omd_nagios_command then
        'command'
      when :omd_nagios_contactgroup then
        'contactgroup'
      when :omd_nagios_contact then
        'contact'
      when :omd_nagios_host then
        'host'
      when :omd_nagios_hostgroup then
        'hostgroup'
      when :omd_nagios_service then
        'service'
      when :omd_nagios_servicegroup then
        'servicegroup'
      else
        ''
      end
    end

    def self.key_attr(object_class)
      case object_class
      when :omd_nagios_command then
        'command_name'
      else
        'name'
      end
    end

    def self.sites
      %x( omd sites -b ).split(/\n/)
    end
  end
end
