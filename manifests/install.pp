# == Class omd::install
#
class omd::install {
  case $::osfamily {
    Debian: {
      class {'omd::install::debian':} ->
      Class['omd::install']
    }
  }

  $managed_package_ensure = $omd::ensure ? {
    present => $omd::version,
    absent  => 'absent',
  }

  ensure_resource('package',
    $omd::package,
    { ensure   => $omd::install::managed_package_ensure,
      provider => $omd::package_provider,
    })
}
