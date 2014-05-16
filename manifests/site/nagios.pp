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
#  Nagios_host <<| tag == "nagios-${sitename}" |>> {
#    notify => Exec["reload nagios ${name}"],
#  }
  Nagios_contact <<| tag == "nagios-${sitename}" |>> {
    notify => Exec["reload nagios ${name}"],
    target => "${nagiosdir}/conf.d/contacts.cfg",
  }

}
