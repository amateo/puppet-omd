define omd::site::nbp (
  $site,
  $number,
  $ensure     = 'present',
  $core       = 'nagios',
  $state_type = 'both',
  $host_template   = '',
  $service_template   = '',
  $host_name  = undef,
  $service_name = undef,
) {
  validate_re($core, '^(nagios)$',
    'On nagios core is supported by now')
  validate_re($state_type, '^(both|hard)$',
    'state_type parameter must be \'both\' or \'hard\'')

  include ::omd::site::nbp::setup

  $sitedir   = "/omd/sites/${site}"
  $thrukdir  = "${sitedir}/etc/thruk"
  $bpdir     = "${thrukdir}/bp"
  $nagiosdir = "${sitedir}/etc/nagios/conf.d"

  $safe_name = regsubst("${site}_${name}", '[/:]', '_', 'G')
  $nbp_dir   = $::omd::site::nbp::setup::nbpdir
  $nodes_file = "${nbp_dir}/${safe_name}.yaml"

  $_host_name = $host_name ? {
    undef   => $name,
    default => $host_name,
  }
  $_service_name = $service_name ? {
    undef   => $name,
    default => $service_name,
  }

  File[$nodes_file] ->
  Omd::Site::Nbp::Node{} ->
  Omd::Site::Nagios::Dotconf["bp_generated_${name}.cfg"]

  file {$nodes_file:
    ensure => $ensure,
  }

  file {"${bpdir}/${number}.tbp":
    ensure  => $ensure,
    owner   => $site,
    group   => $site,
    mode    => '0660',
    content => template('omd/site/thruk/nbp.erb'),
  }

  omd::site::nagios::dotconf { "bp_generated_${name}.cfg":
    ensure  => $ensure,
    site    => $site,
    content => template('omd/site/thruk/nbp_nagios.erb'),
  }
}
