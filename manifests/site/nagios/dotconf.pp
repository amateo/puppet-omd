define omd::site::nagios::dotconf (
  $site,
  $ensure   = 'present',
  $source   = undef,
  $content  = undef,
  $template = undef,
  $owner    = undef,
  $group    = undef,
  $mode     = '0644',
  $path     = undef,
) {
  if !$source and !$content and !$template {
    fail('You must provide one of source, content or template parameters')
  }

  $_owner = $owner ? {
    undef   => $site,
    default => $owner,
  }

  $_group = $group ? {
    undef   => $site,
    default => $group,
  }

  $sitedir = "/omd/sites/${site}"

  $_path = $path ? {
    undef   => "${sitedir}/etc/nagios/conf.d/${name}",
    default => $path,
  }

  # Para recargar la configuración del nagios
  exec { "reload nagios dotconf ${name}":
    command     => "${sitedir}/etc/init.d/nagios reload",
    user        => $site,
    path        => "/bin:/usr/bin:${sitedir}/bin",
    refreshonly => true,
    onlyif      => "${sitedir}/etc/init.d/nagios checkconfig",
  }

  $_content = $content ? {
    undef   => $template ? {
      undef   => undef,
      default => template($template),
    },
    default => $content,
  }

  file { "nagios_dotconf_${name}":
    ensure  => $ensure,
    path    => $_path,
    owner   => $_owner,
    group   => $_group,
    mode    => $mode,
    source  => $source,
    content => $_content,
    notify  => Exec["reload nagios dotconf ${name}"],
  }
}
