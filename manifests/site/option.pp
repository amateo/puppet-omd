define omd::site::option (
  $site,
  $option,
  $value,
) {
  $site_file = "/opt/omd/sites/${site}/etc/omd/site.conf"

  @exec {"config_${name}_${site}":
    command => "/bin/sed -i \"s/^${option}=.\\+$/${option}='${value}'/\" ${site_file}",
    unless  => "/bin/egrep -q \"^${option}='${value}'$\" ${site_file}",
    require => Exec["create_site_${site}"],
    tag     => 'omd::site::config',
  }
}
