define omd::site::pnp4nagios::configd (
  $site,
  $ensure   = 'present',
  $source   = undef,
  $content  = undef,
  $config   = undef,
  $owner    = undef,
  $group    = undef,
  $mode     = '0644',
  $path     = undef,
  $config_name = undef,
) {
  if !$source and !$content and !$config {
    fail('You must provide one of source, content or config parameters')
  }

  $_owner = $owner ? {
    undef   => $site,
    default => $owner,
  }

  $_group = $group ? {
    undef   => $site,
    default => $group,
  }

  $_config_name = $config_name ? {
    undef   => $name,
    default => $config_name,
  }

  $sitedir = "/omd/sites/${site}"

  $_path = $path ? {
    undef => $path,
    default => "${sitedir}/etc/pnp4nagios/config.d/${_config_name}",
  }

  $_content = $content ? {
    undef   => $config ? {
      undef   => undef,
      default => configd($config),
    },
    default => $content,
  }

  file { "pnp4nagios_config_${name}":
    ensure  => $ensure,
    path    => $_path,
    owner   => $_owner,
    group   => $_group,
    mode    => $mode,
    source  => $source,
    content => $_content,
  }
}
