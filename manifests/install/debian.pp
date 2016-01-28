# == Class omd::install
#
class omd::install::debian {
  apt::source { 'omd':
    ensure   => $omd::ensure,
    location => $omd::params::repo,
    release  => $::lsbdistcodename,
    repos    => 'main',
    key      => $omd::key,
    include  => {
      'src' => false,
    },
  }
    
}
