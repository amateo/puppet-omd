# == Class omd::params
#
# This class is meant to be called from omd
# It sets variables according to platform
#
class omd::params {
  $ensure = 'present'
  $version = 'present'
  $audit_only = false
  $options = {}

  case $::osfamily {
    'Debian': {
      if $::lsbdistcodename !~ /^(lucid|precise|trusty)/ {
        fail("${::lsbdistcodename} version is not supported!!!")
      }

      $service            = omd
      $service_status     = true
      $service_hasrestart = true
      $service_ensure     = 'running'
      $service_enable     = true
      $file               = '/etc/omd/omd.conf'
      $file_source        = undef
      $file_content       = undef
      $file_template      = undef
      $file_owner         = 'root'
      $file_group         = 'root'
      $file_mode          = '0644'
      $dir                = '/etc/omd'
      $dir_source         = undef
      $dir_purge          = false
      $package            = 'omd'
      $package_provider   = 'apt'

      $repo = 'http://labs.consol.de/repo/stable/ubuntu'
      $key = {
        'id'     => 'F2F97737B59ACCC92C23F8C7F8C1CA08A57B9ED7',
        'server' => 'keys.gnupg.net',
      }
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
