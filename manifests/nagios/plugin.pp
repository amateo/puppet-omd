# Define omd::nagios::plugin
#
define omd::nagios::plugin (
  $ensure  = 'present',
  $version = 'default',
  $source  = undef,
  $content = undef,
  $target  = undef,
  $owner   = 'root',
  $group   = 'root',
  $mode    = '0755',
  $recurse = undef,
) {
  file { $name:
    path    => "/opt/omd/versions/${version}/lib/nagios/plugins/${name}",
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    source  => $source,
    content => $content,
    target  => $target,
    recurse => $recurse,
  }
}
