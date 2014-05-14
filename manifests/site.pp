define omd::site (
  $ensure = 'present',
) {
  #
  # Create/Remove site
  # 
  case $ensure {
    'present': {
      @exec { "create_site_${name}":
        command => "omd create ${name}",
        path    => '/usr/bin',
        unless  => "omd sites -b | /bin/grep -q '^${name}$'",
        creates => "/opt/omd/sites/${name}",
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
        enable     => $manage_service_enable,
        hasrestart => true,
        hasstatus  => true,
        restart    => "/usr/bin/omd restart ${name}",
        start      => "/usr/bin/omd start ${name}",
        status     => "/usr/bin/omd status ${name}",
        stop       => "/usr/bin/omd stop ${name}",
        provider   => 'base',
        tag        => 'omd::site::service',
        require    => Exec["create_site_${name}"],
      }
    }
    'absent': {
      #
      # Esto es un poco puñeta, pero el "omd rm <site>" es interactivo",
      # así que toca deshabilitarlo, desmontar el tmpfs y borrar a mano
      #
      @mount {"/omd/sites/${name}/tmp":
        ensure => 'absent',
        tag    => 'omd::site::config',
      }

      @exec { "remove_site_${name}":
        command  => "omd disable ${name} && /bin/rm -rf /opt/omd/sites/${name} && /usr/sbin/userdel ${name} && /usr/sbin/groupdel ${name}",
        path     => '/usr/bin',
        onlyif   => "omd sites -b | /bin/grep -q '^${name}$'",
        tag      => 'omd::site::config',
        require  => Mount['/omd/sites/kk1/tmp'],
      }
    }
    default: {
      fail("ensure parameter ($ensure) must be \'present\' or \'absent\'")
    }
  }
}
