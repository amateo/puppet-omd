define omd::site (
  $site   = '',
  $ensure = 'present',
  $mode   = 'own',
  $defaultgui = '',
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
        creates => "${sitedir}",
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

      if $mode == 'shared' {
        apache::dotconf{"02_fcgid_${name}":
          path     => "${sitedir}/etc/apache/conf.d/",
          owner    => $sitename,
          group    => $sitename,
          mode     => '0644',
          template => 'omd/fcgid_site.conf.erb',
          require  => [ Exec["create_site_${name}"],
                        File["${sitedir}/etc/apache/conf.d/02_fcgid.conf"],
          ]
        }

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

        file {"${sitedir}/etc/apache/conf.d/02_fcgid.conf":
          ensure => 'absent',
        }

        file {"${sitedir}/etc/apache/mode.conf":
          ensure => 'link',
          target => "mode_${name}.conf",
        }

        omd::site::config {"CONFIG_APACHE_MODE_${name}":
          site   => $sitename,
          option => 'CONFIG_APACHE_MODE',
          value  => 'shared',
        }
      }

      if $defaultgui != '' {
        omd::site::config {"CONFIG_DEFAULT_GUI_${name}":
          site   => $sitename,
          option => 'CONFIG_DEFAULT_GUI',
          value  => $defaultgui,
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
        require  => Mount['/omd/sites/kk1/tmp'],
      }
    }
    default: {
      fail("ensure parameter (${ensure}) must be \'present\' or \'absent\'")
    }
  }
}
