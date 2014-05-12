# == Class omd::service
#
# This class is meant to be called from omd
# It ensure the service is running
#
class omd::service {

  $managed_service_enabled = $omd::ensure ? {
    'absent' => undef,
    default  => $omd::service_enable,
  }

  $managed_service_ensure = $omd::ensure ? {
    'absent' => 'stopped',
    default  => $omd::service_ensure,
  }

  if $omd::service {
    service { $omd::service:
      ensure     => $omd::service::managed_service_ensure,
      enable     => $omd::service::managed_service_enabled,
      hasstatus  => $omd::service_status,
      hasrestart => $omd::service_restart,
    }
  }
}
