# == Define: omd::site
#
# This define creates and configures an OMD site.
#
# === Parameters
#
# [*ensure*]
#   Set to 'absent' to remove the site.
#
# [*site*]
#   The name of the site to be create. Defaults to $name
#
# [*mode*]
#   Run mode for the site. Defaults to 'own'. Use 'share' to configure
#   the site in the standard apache instance.
#
# [*defaultgui*]
#   Configures the default GUI for the site.
#
define omd::site::auth (
  $site,
  $options,
) {
  $sitedir = "/opt/omd/sites/${site}"

  @file {"auth.conf_${name}":
    path    => "${sitedir}/etc/apache/conf.d/auth.conf",
    owner   => $site,
    group   => $site,
    mode    => '0640',
    content => template('omd/site/auth.conf.erb'),
    tag     => 'omd::site::config',
    require => Exec["create_site_${site}"],
  }
}
