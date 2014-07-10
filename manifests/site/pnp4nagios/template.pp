define omd::site::pnp4nagios::template (
  $site,
  $ensure   = 'present',
  $source   = undef,
  $content  = undef,
  $template = undef,
  $owner    = undef,
  $group    = undef,
  $mode     = '0644',
  $path     = undef,
  $template_name = undef,
  $special  = false,
) {
  if !$source and !$content and !$template {
    fail('You must provide one of source, content or template parameters')
  }

  $_owner = $owner ? {
    undef   => $site,
    default => $owner,
  }

  $_group = $group ? {
    undef   => $site,
    default => $group,
  }

  $_template_name = $template_name ? {
    undef   => $name,
    default => $template_name,
  }

  $sitedir = "/omd/sites/${site}"

  $_path = $path ? {
    undef   => $special ? {
      true    => "${sitedir}/etc/pnp4nagios/templates.special/${_template_name}",
      default => "${sitedir}/etc/pnp4nagios/templates/${_template_name}",
    },
    default => $path,
  }

  $_content = $content ? {
    undef   => $template ? {
      undef   => undef,
      default => template($template),
    },
    default => $content,
  }

  file { "pnp4nagios_template_${name}":
    ensure  => $ensure,
    path    => $_path,
    owner   => $_owner,
    group   => $_group,
    mode    => $mode,
    source  => $source,
    content => $_content,
  }
}
