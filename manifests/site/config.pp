define omd::site::config (
  $site,
  $ensure = 'present',
  $mode   = 'own',
  $defaultgui = 'welcome',
  $core = 'nagios',
  $auth_options = undef,
  $admin_users  = 'omdadmin',
  $apache_modules = [],
) {
  $sitename = $site

  $sitedir = "/opt/omd/sites/${site}"

  $_link_ensure = $ensure ? {
    'absent' => 'absent',
    default  => 'link',
  }

  #
  # Configuración del apache, dependiendo del modo
  #
  $fcgid_template = $mode ? {
    shared  => 'omd/site/fcgid_site_shared.conf.erb',
    own     => 'omd/site/fcgid_site_own.conf.erb',
    default => undef,
  }

  #
  # Configuration
  #

  file {"${site}_02_fcgid.conf":
    ensure  => $ensure,
    path    => "${sitedir}/etc/apache/conf.d/02_fcgid.conf",
    owner   => $site,
    group   => $site,
    mode    => '0644',
    content => template($fcgid_template),
  }


  #
  # Fichero leído por el apache global que determina el modo de ejecución
  # del site
  #
  file { "${sitedir}/etc/apache/mode.conf":
    ensure => $_link_ensure,
    target => "mode_${mode}_${site}.conf",
    notify => Class['apache::service'],
  }

  apache::dotconf { "mode_${mode}_${site}":
    ensure   => $ensure,
    path     => "${sitedir}/etc/apache",
    owner    => $site,
    group    => $site,
    mode     => '0644',
    template => "omd/site/mode_${mode}.conf.erb",
    require  => File["${sitedir}/etc/apache/mode.conf"],
  }

  #
  # This file is only needed with 'own' mode. In other case, it is just
  # confusing if it is still there.
  #
  $_apache_file_ensure = $mode ? {
    'shared' => 'absent',
    default  => $ensure,
  }

  file { "${sitedir}/etc/apache/apache.conf":
    ensure  => $_apache_file_ensure,
    owner   => $site,
    group   => $site,
    mode    => '0644',
    content => template('omd/site/apache.conf.erb'),
  }

  if $auth_options and $mode == 'own' {
    file { "${name}_auth.conf":
      ensure  => $ensure,
      path    => "${sitedir}/etc/apache/conf.d/auth.conf",
      owner   => $site,
      group   => $site,
      mode    => '0640',
      content => template('omd/site/auth.conf.erb'),
    }

    # Si vamos a autenticar con SASL, necesitamos meter al usuario
    # en el grupo 'sasl'
    # No tengo claro que este sea el mejor sitio para hacer esto, pero
    # bueno.
    if has_key($auth_options, 'AuthBasicProvider') {
      if $auth_options[AuthBasicProvider] =~ /(?i:\bsasl\b)/ {
        exec {"${site}_add_group_sasl":
          command => "/usr/sbin/usermod -a -G sasl ${site}",
          unless  => "/usr/bin/groups ${site} | /bin/egrep -q '\bsasl\b'",
        }
      }
    }
  }

  #
  # Configuración del etc/omd/site.conf
  #
  file { "${sitedir}/etc/omd/site.conf":
    ensure  => $ensure,
    owner   => $site,
    group   => $site,
    mode    => '0644',
    content => template('omd/site/omd/site.conf.erb'),
  }

  if $ensure == 'present' {
    case $core {
      'nagios': {
        anchor {"omd::site::config::${name}::begin": } ->
        omd::site::nagios { $site: } ~>
        anchor {"omd::site::config::${name}::end": }
      }
    }
  }

  file {"${sitedir}/etc/check_mk/multisite.mk":
    ensure  => $ensure,
    owner   => $sitename,
    group   => $sitename,
    mode    => '0644',
    content => template('omd/site/check_mk/multisite.mk.erb'),
  }

  file {"${sitedir}/etc/nagios/cgi.cfg":
    ensure  => $ensure,
    owner   => $sitename,
    group   => $sitename,
    mode    => '0644',
    content => template('omd/site/nagios/cgi.cfg.erb'),
  }

  file {"${sitedir}/etc/shinken/cgi.cfg":
    ensure  => $ensure,
    owner   => $sitename,
    group   => $sitename,
    mode    => '0644',
    content => template('omd/site/shinken/cgi.cfg.erb'),
  }

  file {"${sitedir}/etc/icinga/cgi.cfg":
    ensure  => $ensure,
    owner   => $sitename,
    group   => $sitename,
    mode    => '0644',
    content => template('omd/site/icinga/cgi.cfg.erb'),
  }

  file {"${sitedir}/etc/pnp4nagios/config.php":
    ensure  => $ensure,
    owner   => $sitename,
    group   => $sitename,
    mode    => '0644',
    content => template('omd/site/pnp4nagios/config.php.erb'),
  }
}
