define omd::site::service (
  $site,
  $ensure = 'present',
) {
  if $ensure == 'present' {
    $_service_enabled = $omd::ensure ? {
      'absent' => undef,
      default  => $omd::service_enable,
    }

    $_service_ensure = $omd::ensure ? {
      'absent' => 'stopped',
      default  => $omd::service_ensure,
    }

    service { "site_service_${site}":
      ensure     => $_service_ensure,
      enable     => $_service_enabled,
      hasrestart => true,
      hasstatus  => true,
      restart    => "/usr/bin/omd restart ${site}",
      start      => "/usr/bin/omd start ${site}",
      status     => "/usr/bin/omd status ${site}",
      stop       => "/usr/bin/omd stop ${site}",
      provider   => 'base',
    }
  }
}

