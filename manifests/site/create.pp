define omd::site::create (
  $ensure = 'present',
  $site,
) {
  $sitedir = "/opt/omd/sites/${site}"

  case $ensure {
    'present': {
      exec { "create_site_${name}":
        command => "omd create ${site}",
        path    => '/usr/bin',
        unless  => "omd sites -b | /bin/grep -q '^${site}$'",
        creates => $sitedir,
      }
    }
    'absent': {
      #
      # Esto es un poco puñeta, pero el "omd rm <site>" es interactivo",
      # así que toca deshabilitarlo, desmontar el tmpfs y borrar a mano
      #
      mount {"/omd/sites/${site}/tmp":
        ensure => 'absent',
      }

      exec { "remove_site_${name}":
        command => "omd disable ${site} && /bin/rm -rf ${sitedir} && /usr/sbin/userdel ${site} && /usr/sbin/groupdel ${site}",
        path    => '/usr/bin',
        onlyif  => "omd sites -b | /bin/grep -q '^${site}$'",
        require => Mount["/omd/sites/${site}/tmp"],
      }
    }
  }
}
