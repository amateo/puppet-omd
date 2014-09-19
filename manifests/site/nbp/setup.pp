class omd::site::nbp::setup {
  $nbpdir = '/var/lib/puppet/omd_bp'

  file { $nbpdir:
    ensure => directory,
    mode   => '0755',
  }
}
