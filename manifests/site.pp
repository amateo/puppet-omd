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
  $site           = '',
  $ensure         = 'present',
  $mode           = 'own',
  $defaultgui     = 'welcome',
  $core           = 'nagios',
  $auth_options   = '',
  $apache_modules = [],
  $admin_users    = 'omdadmin',
  $livestatus     = 'off',
  $livestatus_port = undef,
  $livestatus_peers = {},
) {
  # Validación
  validate_re($ensure, '^(present|absent)$',
    'ensure parameter must be one of \'present\' or \'absent\'')

  validate_re($mode, '^(own|shared)$',
    'mode parameter must be one of \'own\' or \'shared\'')

  validate_re($core, '^(nagios)$',
    'At this moment, only nagios core is supported')

  validate_re($livestatus, '^(on|off)$',
    'livestatus parameter must be \'on\' or \'off\'')

  validate_re($defaultgui, '^(welcome|nagios|icinga|check_mk|thruk|nagvis)$',
    "defaultgui \'${defaultgui}\' not supported")

  validate_array($apache_modules)

  if !is_array($admin_users) and !is_string($admin_users) {
    fail('admin_user parameter must be a String or Array of Strings')
  }

  if size($apache_modules) and $mode == 'shared' {
    warning('Apache modules are not configured when shared mode is configured. You should configure them directly in apache configuration')
  }

  if $livestatus == 'on' and !$livestatus_port {
    fail('You must provide a livestatus port when it is enabled')
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
    ensure          => $ensure,
    site            => $sitename,
    mode            => $mode,
    defaultgui      => $defaultgui,
    core            => $core,
    auth_options    => $auth_options,
    admin_users     => $admin_users,
    apache_modules  => $apache_modules,
    livestatus      => $livestatus,
    livestatus_port => $livestatus_port,
  } ~>
  ::omd::site::service {$name:
    ensure => $ensure,
    site   => $sitename,
  } ~>
  anchor { "omd::site::${name}::end": }
}
