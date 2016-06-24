# == Class omd::install
#
class omd::install {
  case $::osfamily {
    'Debian': {
      class {'omd::install::debian':} ->
      Class['omd::install']
    }
  }

  $managed_package_ensure = $omd::ensure ? {
    present => $omd::version,
    absent  => 'absent',
  }

  $managed_package = $omd::version ? {
    present => $omd::package,
    default => "omd-${omd::version}",
  }

  ensure_resource('package',
    $managed_package,
    { ensure   => $omd::install::managed_package_ensure,
      provider => $omd::package_provider,
    })
}
