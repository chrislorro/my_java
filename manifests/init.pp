#
class my_java (
  String $version                       = 'installed',
  String $package                       = 'java-1.8.0-openjdk',
  String $architecture                  = 'x86_64',
  String $java_home                     = '/usr/lib/jvm/java-1.8.0/',
  Optional[Boolean] $enable_alternative = true,
) {

  case $facts['kernel'] {
    default: {
      $package_provider = $facts['osfamily'] ? {
        default  => 'yum',
        'Debian' => 'apt',
      }
    }
    'windows': {
      fail("Unsupported on ${facts['kernel']}")
    }
  }

  if $trusted['extensions']['pp_image_name'] == 'storefront_production' {
    notify {'storefront_production':
      withpath => "${facts['ssldir']}/certs/${trusted['certname']}.pem",
    }
  }

  package { $package:
    ensure   => $version,
    provider => $package_provider,
  }

  file_line { 'java-home-environment':
    path    => '/etc/environment',
    line    => "JAVA_HOME=${java_home}",
    match   => 'JAVA_HOME=',
    require => Package['java-1.8.0-openjdk'],
  }
  if $enable_alternative {

    $openjdk_architecture = $environment ? {
      default       => $architecture,
      'development' => 'i686'
    }

    $jdk = {
      'package'          => "java-1.7.0-openjdk.${openjdk_architecture}",
      'java_alternative' => "java-1.7.0-openjdk-${openjdk_architecture}",
      'alternative_path' => "/usr/lib/jvm/java-1.7.0-openjdk-${openjdk_architecture}/bin/java",
      'java_home'        => "/usr/lib/jvm/java-1.7.0-openjdk-${openjdk_architecture}/",
    }

    package { $jdk[package]:
      ensure   => $version,
      provider => $package_provider,
      notify   => Exec['update-java-alternatives']
    }

    exec { 'update-java-alternatives':
      path    => '/usr/bin:/usr/sbin',
      command => "alternatives --set java ${jdk[java_alternative]}",
      unless  => "test /etc/alternatives/java -ef ${jdk[java_alternative_path]}",
    }
  }
}
