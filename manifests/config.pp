# == Class omd::config
#
# This class is called from omd
#
class omd::config {

  $managed_file_content = $omd::file_content ? {
    undef   => $omd::file_template ? {
      undef   => undef,
      default => template($omd::file_template),
    },
    default => $omd::file_content,
  }

  $managed_file_source = $omd::file_source ? {
    ''      => undef,
    default => $omd::file_source,
  }

  $managed_dir_ensure = $omd::ensure ? {
    'absent'  => 'absent',
    'present' => 'directory',
  }

  $managed_file_replace = $omd::audit_only ? {
    true  => false,
    false => true,
  }

  $managed_audit = $omd::audit_only ? {
    true  => 'all',
    false => undef,
  }

  #
  # Manage single file configuration
  if $omd::file {
    file { 'omd.conf':
      ensure  => $omd::ensure,
      path    => $omd::file,
      mode    => $omd::file_mode,
      owner   => $omd::file_owner,
      group   => $omd::file_group,
      source  => $omd::config::managed_file_source,
      content => $omd::config::managed_file_content,
      replace => $omd::config::managed_file_replace,
      audit   => $omd::config::managed_audit,
    }
  }

  #
  # Manage whole config dir
  if $omd::dir_source {
    file { 'omd.dir':
      ensure  => $omd::config::managed_dir_ensure,
      path    => $omd::dir,
      source  => $omd::dir_source,
      recurse => true,
      purge   => $omd::dir_purge,
      force   => $omd::dir_purge,
      replace => $omd::config::managed_file_replace,
      audit   => $omd::config::managed_audit,
    }
  }
}
