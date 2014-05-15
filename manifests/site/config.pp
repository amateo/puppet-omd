define omd::site::config (
  $site,
  $option = '',
  $value  = '',
) {
  $manage_option = $option ? {
    ''      => $name,
    default => $option,
  }

  $site_file = "/opt/omd/sites/${site}/etc/omd/site.conf"

  @exec {"config_${name}_${site}":
    command => "/bin/sed -i \"s/^${manage_option}=.\\+$/${manage_option}='${value}'/\" ${site_file}",
    unless  => "/bin/egrep -q \"^${manage_option}='${value}'$\" ${site_file}",
    require => Exec["create_site_${site}"],
    tag     => 'omd::site::config',
  }
}
