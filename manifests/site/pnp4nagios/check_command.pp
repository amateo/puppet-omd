define omd::site::pnp4nagios::check_command (
  $site,
  $ensure = 'present',
  $command = undef,
  #  $custom_template = undef,
  $options = {},
  $path = undef,
) {
  validate_hash($options)

  $_command = $command ? {
    undef   => $name,
    default => $command,
  }

  $sitedir = "/omd/sites/${site}"

  $_path = $path ? {
    undef   => "${sitedir}/etc/pnp4nagios/check_commands/${_command}.cfg",
    default => $path,
  }

  file { "pnp4nagios_checkcommand_${name}":
    ensure  => $ensure,
    path    => $_path,
    owner   => $site,
    group   => $site,
    mode    => '0644',
    content => template('omd/site/pnp4nagios/check_command.cfg.erb'),
  }
}
