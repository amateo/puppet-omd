include ::omd


#omd::site {'kk1':
  #ensure => 'absent',
#}

#omd::site {'monitorum':
#}

#include ::profile::apache
#include ::apache

class {'::apache':
  default_vhost => true,
  mpm_module    => 'prefork',
  default_mods  => [
    'alias',
    'auth_basic',
    'authn_file',
    'authnz_ldap',
    'authz_default',
    'authz_groupfile',
    'authz_user',
    'autoindex',
    'cgi',
    'deflate',
    'dir',
    'env',
    'fcgid',
    'ldap',
    'mime',
    'negotiation',
    'php',
    'proxy',
    'proxy_http',
    'proxy_html',
    'reqtimeout',
    'rewrite',
    'setenvif',
    'ssl',
  ],
}

::apache::vhost {'monitorum.um.es':
  port          => 80,
  servername    => 'monitorum.um.es',
  serveraliases => ['monitorumtest.um.es'],
  docroot       => '/var/www',
  error_log     => false,
  access_log    => false,
  options       => ['FollowSymLinks'],
  rewrites      => [
    {
      comment      => 'Redirect to https',
      rewrite_cond => '%{HTTPS} !=on',
      rewrite_rule => '^/?(.*) https://%{SERVER_NAME}/$1 [R,L]'
    },
  ],
}

::apache::vhost {'monitorum.um.es_ssl':
  port                => 443,
  ssl                 => true,
  servername          => 'monitorum.um.es',
  serveraliases       => ['monitorumtest.um.es'],
  docroot             => '/var/www',
  error_log           => false,
  access_log          => false,
  options             => ['FollowSymLinks'],
  additional_includes => [ '/omd/apache/*.conf' ],
  custom_fragment     => '
      <IfModule mod_proxy_html.c>
        ProxyHTMLURLMap url\(http://((monitorum.+)/([^\)]*)\)   url(https://$1/$2) Rihe
      </IfModule>',
  ssl_cert  => '/etc/ssl/certs/monitorum.um.es.pem',
  ssl_key   => '/etc/ssl/private/privada_monitorum.um.es.pem',
  ssl_chain => '/etc/ssl/certs/terenassl_path.pem',
  ssl_ca    => '/etc/ssl/certs/terenassl_path.pem',
}


omd::site {'test1':
  #  ensure      => 'absent',
  apache_modules => [
    'authnz_ldap',
    'ldap',
    'authn_sasl',
    'auth_sys_group',
  ],
  admin_users    => 'amateo_adm',
  auth_options   => {
    'AuthBasicProvider'      => 'sasl ldap',
    'AuthLDAPBindDN'         => 'cn=monitorum,ou=People,ou=Management,o=SlapdRoot',
    'AuthLDAPBindPassword'   => 'kkdelavaca',
    'AuthLDAPURL'            => 'ldap://ldapacc.um.es:389/ou=Usuarios,dc=Telematica?uid?sub?(objectClass=posixAccount)',
    'AuthBasicAuthoritative' => 'On',
    'AuthSaslPwcheckMethod'  => 'saslauthd',
    'Require'                => [
      'group telematadm',
      'ldap-attribute irisUserStatus=urn:mace:rediris.es:um.es:userStatus:nagios:estado:activo'
    ],
  }
}

omd::nagios::plugin {'check_centreon_snmp_TcpConn':
  source => 'puppet:///modules/omd/tests/check_centreon_snmp_TcpConn',
}
