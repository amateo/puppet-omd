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
define omd::site (
  $site         = '',
  $ensure       = 'present',
  $mode         = 'own',
  $defaultgui   = '',
  $core         = 'nagios',
  $auth_options = '',
) {
  validate_re($mode, '^(own|shared)$',
    'mode parameter must be one of \'own\' or \'shared\'')

  $sitename = $site ? {
    ''      => $name,
    default => $site,
  }

  $sitedir = "/opt/omd/sites/${sitename}"

  #
  # Create/Remove site
  #
  case $ensure {
    'present': {
      @exec { "create_site_${name}":
        command => "omd create ${sitename}",
        path    => '/usr/bin',
        unless  => "omd sites -b | /bin/grep -q '^${sitename}$'",
        creates => $sitedir,
        tag     => 'omd::site::config',
      }

      $manage_service_enabled = $omd::ensure ? {
        'absent' => undef,
        default  => $omd::service_enable,
      }

      $manage_service_ensure = $omd::ensure ? {
        'absent' => 'stopped',
        default  => $omd::service_ensure,
      }

      @service { "site_service_${name}":
        ensure     => $manage_service_ensure,
        enable     => $manage_service_enabled,
        hasrestart => true,
        hasstatus  => true,
        restart    => "/usr/bin/omd restart ${sitename}",
        start      => "/usr/bin/omd start ${sitename}",
        status     => "/usr/bin/omd status ${sitename}",
        stop       => "/usr/bin/omd stop ${sitename}",
        provider   => 'base',
        tag        => 'omd::site::service',
        require    => Exec["create_site_${name}"],
      }

      #
      # Configuración del apache, dependiendo del modo
      #
      $fcgid_template = $mode ? {
        shared  => 'omd/fcgid_site_shared.conf.erb',
        own     => 'omd/site/fcgid_site_own.conf.erb',
        default => undef,
      }

      apache::dotconf{"02_fcgid_${name}":
        path     => "${sitedir}/etc/apache/conf.d/",
        owner    => $sitename,
        group    => $sitename,
        mode     => '0644',
        template => $fcgid_template,
        require  => [ Exec["create_site_${name}"],
                      File["${sitedir}/etc/apache/conf.d/02_fcgid.conf"],
        ]
      }

      file {"${sitedir}/etc/apache/conf.d/02_fcgid.conf":
        ensure => 'absent',
      }

      $mode_target = $mode ? {
        'own'    => 'apache-own.conf',
        'shared' => "mode_${name}.conf",
      }

      file {"${sitedir}/etc/apache/mode.conf":
        ensure => 'link',
        #target => "mode_${name}.conf",
        target => $mode_target,
      }

      if $mode == 'shared' {
        apache::dotconf {"mode_${name}":
          path     => "${sitedir}/etc/apache",
          owner    => $sitename,
          group    => $sitename,
          mode     => '0644',
          template => 'omd/mode_shared.conf.erb',
          require  => [ Exec["create_site_${name}"],
                        File["${sitedir}/etc/apache/mode.conf"],
          ]
        }
      }

      omd::site::config {"CONFIG_APACHE_MODE_${name}":
        site   => $sitename,
        option => 'CONFIG_APACHE_MODE',
        value  => $mode,
      }

      if $defaultgui != '' {
        omd::site::config {"CONFIG_DEFAULT_GUI_${name}":
          site   => $sitename,
          option => 'CONFIG_DEFAULT_GUI',
          value  => $defaultgui,
        }
      }

      case $core {
        'nagios': { omd::site::nagios {$sitename:} }
        default:  { fail("Core ${core} is not supported") }
      }

      if $auth_options and $mode == 'own' {
        notify {"CONFIGURANDO AUTH DE ${sitename}":}
        omd::site::auth {"auth_${name}":
          site    => $sitename,
          options => $auth_options,
        }
      }
    }
    'absent': {
      #
      # Esto es un poco puñeta, pero el "omd rm <site>" es interactivo",
      # así que toca deshabilitarlo, desmontar el tmpfs y borrar a mano
      #
      @mount {"/omd/sites/${sitename}/tmp":
        ensure => 'absent',
        tag    => 'omd::site::config',
      }

      @exec { "remove_site_${name}":
        command  => "omd disable ${sitename} && /bin/rm -rf ${sitedir} && /usr/sbin/userdel ${sitename} && /usr/sbin/groupdel ${sitename}",
        path     => '/usr/bin',
        onlyif   => "omd sites -b | /bin/grep -q '^${sitename}$'",
        tag      => 'omd::site::config',
        require  => Mount["/omd/sites/${sitename}/tmp"],
      }
    }
    default: {
      fail("ensure parameter (${ensure}) must be \'present\' or \'absent\'")
    }
  }
}
