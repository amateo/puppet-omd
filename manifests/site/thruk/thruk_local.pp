define omd::site::thruk::thruk_local (
  $site  = undef,
  $peers = {},
) {
  $_site = $site ? {
    undef   => $name,
    default => $site,
  }

  $sitedir = "/opt/omd/sites/${_site}"

  file { "${name} thruk local":
    ensure  => 'present',
    path    => "${sitedir}/etc/thruk_local.conf",
    owner   => $_site,
    group   => $_site,
    mode    => '0644',
    content => template('omd/site/thruk/thruk_local.conf.erb'),
  }
}
