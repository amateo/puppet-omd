# == Define: omd::site
#
# This define creates and configures an OMD site.
#
# === Parameters
#
# [*ensure*]
#   Set to 'absent' to remove the site.
#
# [*site*]
#   The name of the site to be create. Defaults to $name
#
# [*mode*]
#   Run mode for the site. Defaults to 'own'. Use 'share' to configure
#   the site in the standard apache instance.
#
# [*defaultgui*]
#   Configures the default GUI for the site.
#
# [*core*]
#   Configures de monitoring core to use. By default, nagios
#
# [*auth_options*]
#   Parameter to pass apache auth options to the site. It configures
#   the auth.conf file with the options included.
#
# [*apache_modules*]
#   Array with additional modules loaded in the apache instance
#
# [*omadmin*]
#   User of array of users with administration privileges.
#
define omd::site (
  $site             = '',
  $ensure              = 'present',
  $mode                = 'own',
  $defaultgui          = 'welcome',
  $core                = 'nagios',
  $auth_options        = '',
  $apache_modules      = [],
  $admin_users         = 'omdadmin',
  $admin_contactgroups = undef,
  $livestatus          = 'off',
  $livestatus_port     = undef,
  $livestatus_peers    = undef,
  $nagios_options      = undef,
  $gearman_server      = undef,
  $gearman_worker      = undef,
  $gearmand_port       = undef,
  $gearman_key         = undef,
) {
  # Validación
  validate_re($ensure, '^(present|absent)$',
    'ensure parameter must be one of \'present\' or \'absent\'')

  validate_re($mode, '^(none|own|shared)$',
    'mode parameter must be one of \'none\', \'own\' or \'shared\'')

  validate_re($core, '^(none|nagios)$',
    'core parameter must be one of \'none\' or \'nagios\'')

  validate_re($livestatus, '^(on|off)$',
    'livestatus parameter must be \'on\' or \'off\'')

  validate_re($defaultgui, '^(welcome|nagios|icinga|check_mk|thruk|nagvis)$',
    "defaultgui \'${defaultgui}\' not supported")

  validate_array($apache_modules)

  if !is_array($admin_users) and !is_string($admin_users) {
    fail('admin_user parameter must be a String or Array of Strings')
  }

  if !is_array($admin_contactgroups) and !is_string($admin_contactgroups) {
    fail('admin_contactgroups parameter must be a String or Array of Strings')
  }

  if size($apache_modules) and $mode == 'shared' {
    warning('Apache modules are not configured when shared mode is configured. You should configure them directly in apache configuration')
  }

  if $livestatus == 'on' and !$livestatus_port {
    fail('You must provide a livestatus port when it is enabled')
  }

  if $livestatus_peers {
    validate_hash($livestatus_peers)
  }

  if $gearman_server != undef {
    validate_bool($gearman_server)
  }

  if $gearman_worker != undef {
    validate_bool($gearman_worker)
  }

  if $gearmand_port {
    validate_re($gearmand_port, '^.+:\d+$',
      "gearmand_port parameter must be a <fqdn>:<port>: ${gearmand_port}")
  }

  if $gearman_key {
    validate_string($gearman_key)
  }

  $sitename = $site ? {
    ''      => $name,
    default => $site,
  }

  anchor { "omd::site::${name}::begin": } ->
  ::omd::site::create {$name:
    ensure => $ensure,
    site   => $sitename,
  } ->
  ::omd::site::config {$name:
    ensure              => $ensure,
    site                => $sitename,
    mode                => $mode,
    defaultgui          => $defaultgui,
    core                => $core,
    auth_options        => $auth_options,
    admin_users         => $admin_users,
    admin_contactgroups => $admin_contactgroups,
    apache_modules      => $apache_modules,
    livestatus          => $livestatus,
    livestatus_port     => $livestatus_port,
    livestatus_peers    => $livestatus_peers,
    nagios_options      => $nagios_options,
    gearman_server      => $gearman_server,
    gearman_worker      => $gearman_worker,
    gearmand_port       => $gearmand_port,
    gearman_key         => $gearman_key,
  } ~>
  ::omd::site::service {$name:
    ensure => $ensure,
    site   => $sitename,
  } ~>
  anchor { "omd::site::${name}::end": }
}
