require 'augeas'

Puppet::Type.type(:omd_nagios_command).provide(:ruby) do
  defaultfor :osfamily => :debian

  mk_resource_methods

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] == :absent
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
        files.push(d + '/etc/nagios/conf.d/commands_puppet.cfg') if File.exists?(d + '/etc/nagios/conf.d/commands_puppet.cfg')
      end
    end
    return files
  end

  def self.load_from_file(filename)
    aug_path = '/files' + filename
    commands = Array.new
    if match = filename.match(/^\/omd\/sites\/([^\/]+)\/.+$/)
      site = match[1]
    end
    if File.exists?(filename)
      # Abrimos el fichero con augeas
      aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(:lens => 'nagiosobjects.lns', :incl => filename)
      aug.load

      aug.match(aug_path + '/*').each do |entry|
        if entry.match(/^#{aug_path}\/command(\[\d+\])?$/)
          hash = Hash.new
          hash[:ensure] = :present
          aug.match(entry + '/*').each do |attr|
            name = (match = attr.match(/^.+\/([^\/]+)$/)) ? match[1] : nil
            case name
              when 'command_name' then hash[:command_name] = aug.get(attr)
              when 'command_line' then hash[:command_line] = aug.get(attr)
              when 'poller_tag' then hash[:poller_tag] = aug.get(attr)
              when 'use' then hash[:use] = aug.get(attr)
              else hash[name] = aug.get(attr)
            end
          end
          hash[:aug_entry] = entry
          hash[:target] = filename
          hash[:name] = hash[:command_name] if !hash[:name]
          hash[:site] = site ? site : ''
          commands.push(hash)
        end
      end
      return commands
    else
      return nil
    end
  end

  def save_to_disk
    raise Puppet::Error, 'You must provide a site paramater' if !resource[:site]
    filename = resource[:target] ? @resource[:target] : '/omd/sites/' + resource[:site] + '/etc/nagios/conf.d/commands_puppet.cfg'
    aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
    aug.transform(:lens => 'nagiosobjects.lns', :incl => filename)
    aug.load

    if @property_hash[:aug_entry] and @property_hash[:aug_entry].match(/^\/files#{filename}\//)
      command_entry = @property_hash[:aug_entry]
    else
      # Busco el último command en augeas
      last_command = 0
      aug.match('/files' + filename + '/*').each do |entry|
        if entry.match(/^.+\/command(\[\d+\])?$/)
          command_number = (match = entry.match(/^.+\/command\[(\d+)\]$/)) ? match[1].to_i : 1
          last_command = command_number if command_number > last_command
        end
      end
      command_entry = '/files' + filename + '/command[' + (last_command + 1).to_s + ']'
    end

    if @property_flush[:ensure] == :absent
      aug.rm(command_entry)
    else
      aug.set(command_entry + '/command_name', resource[:command_name]) if resource[:command_name]
      aug.set(command_entry + '/command_line', resource[:command_line]) if resource[:command_line]
      aug.set(command_entry + '/poller_tag', resource[:poller_tag]) if resource[:poller_tag]
      aug.set(command_entry + '/use', resource[:use]) if resource[:use]
    end

    aug.save
    aug.close
  end
end
