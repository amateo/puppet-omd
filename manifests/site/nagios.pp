define omd::site::nagios (
  $site = '',
) {
  $sitename = $site ? {
    ''      => $name,
    default => $site,
  }

  $sitedir = "/omd/sites/${sitename}"
  $initdir = "${sitedir}/etc/init.d"
  $nagiosdir = "${sitedir}/etc/nagios"

  #
  # Configuramos el core a nagios
  omd::site::config { "core_config_${name}":
    site   => $sitename,
    option => 'CONFIG_CORE',
    value  => 'nagios',
  }

  # Para recargar la configuración del nagios
  exec { "reload nagios ${name}":
    #command    => "/usr/bin/omd reload ${sitename}",
    command     => "${initdir}/nagios reload",
    user        => $sitename,
    path        => "/bin:/usr/bin:${sitedir}/bin",
    refreshonly => true,
    onlyif      => "${initdir}/nagios checkconfig",
  }

  #
  # Instanciamos todos los resources nagios_XXX definidos para este servidor
  # y este site
  #
  Nagios_command <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/commands.cfg",
  }
  Nagios_contact <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/contacts.cfg",
  }
  Nagios_contactgroup <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/contactgroups.cfg",
  }
  Nagios_host <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/hosts.cfg",
  }
  Nagios_hostdependency <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/hostdependency.cfg",
  }
  Nagios_hostescalation <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/hostescalation.cfg",
  }
  Nagios_hostextinfo <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/hostextinfo.cfg",
  }
  Nagios_hostgroup <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/hostgroups.cfg",
  }
  Nagios_service <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/services.cfg",
  }
  Nagios_servicedependency <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/servicedependency.cfg",
  }
  Nagios_serviceescalation <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/serviceescalation.cfg",
  }
  Nagios_serviceextinfo <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/serviceextinfo.cfg",
  }
  Nagios_servicegroup <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/servicegroups.cfg",
  }
  Nagios_timeperiod <<| tag == "omd-nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/timeperiods.cfg",
  }

  #
  # Si los ficheros los crea el nagios_*, se crean con
  # propietario root y permisos 600, así que fuerzo que
  # sean del usuario que utiliza el nagios del site
  file { [
    "${nagiosdir}/conf.d/commands.cfg",
    "${nagiosdir}/conf.d/contacts.cfg",
    "${nagiosdir}/conf.d/contactgroups.cfg",
    "${nagiosdir}/conf.d/hosts.cfg",
    "${nagiosdir}/conf.d/hostdependency.cfg",
    "${nagiosdir}/conf.d/hostescalation.cfg",
    "${nagiosdir}/conf.d/hostextinfo.cfg",
    "${nagiosdir}/conf.d/hostgroups.cfg",
    "${nagiosdir}/conf.d/services.cfg",
    "${nagiosdir}/conf.d/servicedependency.cfg",
    "${nagiosdir}/conf.d/serviceescalation.cfg",
    "${nagiosdir}/conf.d/serviceextinfo.cfg",
    "${nagiosdir}/conf.d/servicegroups.cfg",
    "${nagiosdir}/conf.d/timeperiods.cfg",
  ]:
    owner => $sitename,
  }
}
