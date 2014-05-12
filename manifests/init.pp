# == Class: omd
#
# Full description of class omd here.
#
# === Parameters
#
# Standard class parameters
# Define the general class behaviour and customizations
#
# [*ensure*]
#   Set to 'absent' to remove package(s) installed by module.
#
# [*version*]
#   The package version, used in the ensure parameter of the package type.
#   Default: present. Can be 'latest' or a specific version number.
#   Note that if the argument ensure (see above) is set to 'absent', the
#   package is removed, whatever the value of the version parameter.
#
# [*service*]
#   The name of omd service. If you don't want the module
#   to manage the service (for example, because it is managed by a cluster
#   software) set this to undef. 
#
# [*service_status*]
#   If the omd service init script supports status argument
#
# [*service_hasrestart*]
#   If the omd service init script supports hasrestart argument
#
# [*service_ensure*]
#   Wether the service should be running ('running' or 'true') or
#   stopped ('stopped' or 'false')
#
# [*service_enable*]
#   Set to 'false' to disable service(s) at boot, without checks if it's running
#   Use this when the service is managed by a tool like a cluster software
#
# [*file*]
#   Main configuration file path
#
# [*file_source*]
#   Sets the content of source parameter for main configuration file
#   If defined, omd main config file will have the param:
#   source => $file_source
#   Note file_source, file_content and file_template parameters are mutually exclusive.
#
# [*file_content*]
#   Sets the content of the main configuration file. If defined, omd
#   main config file has the param content => $file_content
#   Note file_source, file_content and file_template parameters are mutually exclusive.
#
# [*file_template*]
#   Sets the path to the template to use as content for main configuration file
#   If defined, omd main config file has
#   content => template("$file_template")
#   Note file_source, file_content and file_template parameters are mutually exclusive.
#
# [*file_owner*]
#   Main configuration file path owner
#
# [*file_group*]
#   Main configuration file path group
#
# [*file_mode*]
#   Main configuration file path mode
#
# [*dir*]
#   Main configuration directory.
#
# [*dir_source*]
#   If defined, the whole omd configuration directory
#   content is retrieved recursively from the specified source
#   (source => $dir_source, recurse => true)
#   Note dir_source and file_* are mutually exclusive.
#
# [*dir_purge*]
#   If set to true (default false) the existing configuration directory is
#   mirrored with the content retrieved from source_dir
#   (source => $dir_source, recurse => true, purge => true)
#
# [*package*]
#   The name of omd package
#
# [*package_provider*]
#   Provider for the instalation of the package. Currently only package
#   resource's providers are supported. If you want to use a different
#   one, you have to implement it.
#
# [*audit_only*]
#   Set to 'true' if you don't intend to override existing configuration files
#   and want to audit the difference between existing files and the ones
#   managed by Puppet. Default: false
#
# [*options*]
#   A hash of custom options to be used in templates for arbitrary settings.
#
class omd (
  $ensure              = $omd::params::ensure,
  $version             = $omd::params::version,
  $service             = $omd::params::service,
  $service_status      = $omd::params::service_status,
  $service_hasrestart  = $omd::params::service_hasrestart,
  $service_ensure      = $omd::params::service_ensure,
  $service_enable      = $omd::params::service_enable,
  $file                = $omd::params::file,
  $file_source         = $omd::params::file_source,
  $file_content        = $omd::params::file_content,
  $file_template       = $omd::params::file_template,
  $file_owner          = $omd::params::file_owner,
  $file_group          = $omd::params::file_group,
  $file_mode           = $omd::params::file_mode,
  $dir                 = $omd::params::dir,
  $dir_source          = $omd::params::dir_source,
  $dir_purge           = $omd::params::dir_purge,
  $package             = $omd::params::package,
  $package_provider    = $omd::params::package_provider,
  $audit_only          = $omd::params::audit_only,
  $options             = $omd::params::options,
) inherits omd::params {

  # validate parameters here
  validate_re($omd::ensure, '^(present|absent)$',
    'ensure parameter must be \'present\' or \'absent\'')
  validate_string($omd::version)

  validate_string($omd::service)
  validate_bool($omd::service_status)
  validate_re($omd::service_ensure, '^(running|stopped)$',
    'service_ensure parameter must be \'running\' or \'stopped\'')

  if is_string($omd::service_enable) and
    $omd::service_enable !~ /^(true|false|manual)/ {
    fail("service_enable (${omd::service_enable}) parameter must be one of true, false, or \'manual\'")
  } else {
    validate_bool($omd::service_enable)
  }

  if $omd::file {
    validate_absolute_path($omd::file)
  }

  if $omd::dir {
    validate_absolute_path($omd::dir)
  }
  validate_bool($omd::dir_purge)

  validate_string($omd::package)

  validate_bool($omd::audit_only)

  validate_hash($omd::options)

  anchor { 'omd::begin': } ->
  class {'omd::install': } ->
  class {'omd::config': } ~>
  class {'omd::service': } ~>
  anchor { 'omd::end': }
}
