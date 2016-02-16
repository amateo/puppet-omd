require 'json'

begin
  require 'puppet_x/omd/thruk'
rescue
  libdir = Pathname.new(__FILE__).parent.parent.parent.parent
  require File.join(libdir, 'puppet_x/omd/thruk')
end

Puppet::Type.type(:thruk_bp).provide(:ruby) do
  confine :feature => :json
  defaultfor :osfamily => :debian
  include Puppet_X::Omd::Thruk

  mk_resource_methods
  
  def exists?
    return !@property_hash.empty?
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def create
    @property_hash[:state_type] = resource[:state_type]
    @property_hash[:site] = resource[:site]
    @property_hash[:host_template] = resource[:host_template] if resource[:host_template]
    @property_hash[:rank_dir] = resource[:rank_dir]
    @property_hash[:host_name] = resource[:host_name]
    @property_hash[:function] = resource[:function]
    @property_hash[:service_template] = resource[:service_template] if resource[:service_template]
    @property_hash[:servicegroups] = resource[:servicegroups] if resource[:servicegroups]
    @property_hash[:bp_target] = get_new_filename(self.class.config_path(resource[:site]))
    @property_hash[:target] = get_bp_filename(resource[:name])
    @property_hash[:name] = resource[:name]
  end

  def self.instances
    self.load_bps.collect do |bp|
      new(bp)
    end
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
    if @property_flush[:ensure] == :absent
      File.delete(@property_hash[:target]) if File.file?(@property_hash[:target])
      File.delete(@property_hash[:bp_target]) if File.file?(@property_hash[:bp_target])
      @property_hash = []
    else
      flush_json

      # Collect the resources again once they've been changed (that way `puppet
      # resource` will show the correct values after changes have been made).
      @property_hash = self.class.load_bp(@property_hash[:target])

      to_json(@property_hash)
    end
    save_nagios_objects
    ensure_cron
  end

  #
  #################################################################
  #
  
  def self.config_path(site)
    return '/omd/sites/' + site + '/etc/thruk/bp'
  end

  def self.bp_internal_path
    return '/var/lib/puppet/thruk'
  end

  def get_new_filename(path)
    raise Puppet::Error, 'Directory ' + dir + ' does not exists!!!' if !File.directory?(path)
    i = 1
    filename = path + '/' + i.to_s + '.tbp'
    while File.file?(filename)
      i += 1
      filename = path + '/' + i.to_s + '.tbp'
    end
    return filename
  end

  def self.load_bps
    bps = []
    Dir[bp_internal_path + '/bp_*.json'].each do |f|
      @property_hash = JSON.parse(File.read(f), { :symbolize_names => true })
      bps.push(@property_hash)
    end
    bps
  end

  def self.load_bp(filename)
    begin
      json = JSON.parse(File.read(filename), { :symbolize_names => true })
      return json
    rescue
      return nil
    end
  end

  def flush_json
    if !File.directory?(self.class.bp_internal_path) and !File.file?(self.class.bp_internal_path)
      Dir.mkdir(self.class.bp_internal_path)
    elsif File.file?(self.class.bp_internal_path)
      raise Puppet::Error, "Can't create " + self.class.bp_internal_path + ' directory. It already exists as file'
    end
    filename = @property_hash[:target]
    File.open(filename, 'w') do |f|
      f.puts JSON.pretty_generate(@property_hash)
    end
  end

  def save_nagios_objects
    # Abrimos el fichero con augeas
    path = '/omd/sites/' + resource[:site] + '/etc/nagios/conf.d/thruk_bp_generated.cfg'
    aug = Augeas::open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
    aug.transform(:lens => "nagiosobjects.lns", :incl => path)
    aug.load

    if match = @property_hash[:bp_target].match(/^.+\/([^\/]+)\.tbp/)
      bp_id = match[1]
    end
    host_entry = nil
    service_entry = nil
    last_host = 0
    last_service = 0
    aug.match('/files/' + path + '/*').each do |entry|
      if entry.match(/^.+\/host(\[\d+\])?$/)
        host_number = (match = entry.match(/^.+\/host\[(\d+)\]$/)) ? match[1].to_i : 1
        last_host = host_number if host_number > last_host
        entry_id = aug.get(entry + '/_THRUK_BP_ID')
        if entry_id == bp_id
          host_entry = entry
        end
      elsif entry.match(/^.+\/service(\[\d+\])?$/)
        service_number = (match = entry.match(/^.+\/service\[(\d+)\]$/)) ? match[1].to_i : 1
        last_service = service_number if service_number > last_service
        entry_id = aug.get(entry + '/_THRUK_BP_ID')
        if entry_id == bp_id
          service_entry = entry
        end
      end
    end
    if @property_flush[:ensure] == :absent
      aug.rm(host_entry) if host_entry
      aug.rm(service_entry) if service_entry
    else
      aug_host_path = host_entry ?
        host_entry : '/files' + path + '/host[' + (last_host + 1).to_s + ']'
      aug_service_path = service_entry ?
        service_entry : '/files' + path + '/service[' + (last_service + 1).to_s + ']'
      host_template = resource[:host_template] ? resource[:host_template] : 'thruk-bp-template'
      service_template = resource[:service_template] ? resource[:service_template] : 'thruk-bp-node-template'
      aug.set(aug_host_path + '/use', host_template)
      aug.set(aug_host_path + '/host_name', resource[:host_name])
      aug.set(aug_host_path + '/alias', 'Business Process: ' + resource[:host_name])
      aug.set(aug_host_path + '/_THRUK_BP_ID', bp_id)
      aug.set(aug_host_path + '/_THRUK_NODE_ID', 'node1')
      aug.set(aug_service_path + '/use', service_template)
      aug.set(aug_service_path + '/host_name', resource[:host_name])
      aug.set(aug_service_path + '/service_description', resource[:name])
      if resource[:servicegroups] and resource[:servicegroups].respond_to?('join')
        aug.set(aug_service_path + '/servicegroups', resource[:servicegroups].join(','))
      elsif resource[:servicegroups]
        aug.set(aug_service_path + '/servicegroups', resource[:servicegroups])
      end
      aug.set(aug_service_path + '/display_name', resource[:name])
      aug.set(aug_service_path + '/_THRUK_BP_ID', bp_id)
      aug.set(aug_service_path + '/_THRUK_NODE_ID', 'node1')
    end

    aug.save
    aug.close

    # Reload nagios
    system('/usr/bin/omd reload  ' + resource[:site] + ' nagios')
  end

  def ensure_cron
    path = '/omd/sites/' + resource[:site] + '/etc/cron.d/thruk.auto'
    version = get_site_version
    changed = false
    if File.zero?(path)
      file = File.open(path, 'w')
      file.puts('# THIS PART IS WRITTEN BY THRUK, CHANGES WILL BE OVERWRITTEN')
      file.puts('##############################################################')
      file.puts('# business process')
      file.puts("* * * * * cd /opt/omd/versions/" + version + "/share/thruk && /bin/bash -l -c '/omd/sites/" + resource[:site] + "/bin/thruk -a bpd' >/dev/null 2>>/omd/sites/" + resource[:site] + "/var/thruk/cron.log")
      file.puts('##############################################################')
      file.puts('# END OF THRUK')
      file.close
      changed = true
    else
      first_mark = false
      file = File.open(path, 'r+')
      file.each do |line|
        if line.match(/^#+$/)
          if !first_mark
            first_mark = true
          else
            # Hemos llegado a la marca de fin, tenemos
            # que crear la entrada
            length = 0 - line.length
            file.seek length, IO::SEEK_CUR
            file.puts('# business process')
            file.puts("* * * * * cd /opt/omd/versions/1.10/share/thruk && /bin/bash -l -c '/omd/sites/" + resource[:site] + "/bin/thruk -a bpd' >/dev/null 2>>/omd/sites/" + resource[:site] + "/var/thruk/cron.log")
            file.puts('##############################################################')
            file.puts('# END OF THRUK')
            changed = true
          end
        elsif line.match(/^# business process$/)
          break
        end
      end
      file.close
    end
    system('/usr/bin/omd reload ' + resource[:site] + ' crontab') if changed == true
  end

  def get_site_version
    command = '/usr/bin/omd version ' + resource[:site]
    output = `#{command}`
    if match = output.match(/^OMD - Open Monitoring Distribution Version (\d+\.\d+)$/)
      return match[1]
    else
      return 'default'
    end
  end
end
