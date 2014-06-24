define omd::site::config::livestatus (
  $site            = undef,
  $livestatus_port = undef,
) {
  $_site = $site ? {
    undef   => $name,
    default => $site,
  }

  $sitedir = "/opt/omd/sites/${_site}"

  if $livestatus_port {
    augeas { "${_site}_livestatus_port":
      context => "/files/${sitedir}/etc/mk-livestatus/xinetd.conf/service/",
      changes => "set port ${livestatus_port}",
      lens    => 'xinetd.lns',
      incl    => "${sitedir}/etc/mk-livestatus/xinetd.conf",
    }
  }

  file {"${_site} xinetd link":
    ensure => 'link',
    path   => "${sitedir}/etc/xinetd.d/mk-livestatus",
    target => '../mk-livestatus/xinetd.conf'
  }
}
