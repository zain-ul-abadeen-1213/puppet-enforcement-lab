# Manifest: web.pp
# Maqsad: nginx web server ki halat ko hamesha waisi hi rakhna jaisi yahan likhi hai

package { 'nginx':
  ensure => installed,
}

file { '/etc/nginx/sites-available/default':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => 'server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html;
    server_name _;
    location / {
        try_files $uri $uri/ =404;
    }
}
',
  require => Package['nginx'],
  notify  => Service['nginx'],
}

file { '/var/www/html/index.html':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => '<!DOCTYPE html><html><head><title>Zain Tech Automation Solutions</title></head><body><h1>Zain Tech Automation Solutions</h1><p>Ye page Puppet manifest se lagi hai aur Puppet hi ise hamesha aisi hi rakhega.</p><p>Automate. Accelerate. Achieve.</p></body></html>',
  require => Package['nginx'],
}

file { '/etc/motd':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => 'Zain Tech Automation Solutions - Ye machine Puppet se managed hai. Haath se tabdeeli mat karo, Puppet use wapas theek kar dega.',
}

user { 'deploy':
  ensure     => present,
  shell      => '/bin/bash',
  managehome => true,
}

service { 'nginx':
  ensure  => running,
  enable  => true,
  require => Package['nginx'],
}
