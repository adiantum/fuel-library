#
class openstack::mirantis_repos (
  # DO NOT change this value to 'defaults'. All our customers are relying on external repositories
  $type        = 'default',
  $originator  = 'Mirantis Product <product@mirantis.com>',
  $disable_puppet_labs_repos = true,
  $upstream_mirror        = true,
  $deb_mirror             = 'http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu',
  $deb_updates            = 'http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu',
  $deb_security           = 'http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu',
  $deb_fuel_folsom_repo   = 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom',
  $deb_cloud_archive_repo = 'http://172.18.67.168/ubuntu-cloud.archive.canonical.com/ubuntu',
  $deb_rabbit_repo        = 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom',
  $enable_epel = false,
  $fuel_mirrorlist        = 'http://download.mirantis.com/epel-fuel-folsom-2.1/mirror.internal-stage.list',
  $mirrorlist_base        = 'http://172.18.67.168/centos-repo/mirror-6.3-os.list',
  $mirrorlist_updates     = 'http://172.18.67.168/centos-repo/mirror-6.3-updates.list',
  $enable_test_repo = false,
  $repo_proxy = undef,
) {
  case $::osfamily {
    'Debian': {
      class {'apt::proxy': 
        proxy => $repo_proxy,
        stage => $::openstack::mirantis_repos::stage
      }

      if $type == 'default' {
        apt::source { 'cloud-archive':
          location    => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
          release     => 'precise-updates/folsom',
          repos       => 'main',
          key         => '5EDB1B62EC4926EA',
          key_source  => 'http://download.mirantis.com/precise-fuel-folsom/cloud-archive.key',
          #key_server => 'keys.gnupg.net',
          include_src => false,
        }

          apt::source { 'precise-fuel-folsom':
          location    => 'http://download.mirantis.com/precise-fuel-folsom',
          release     => 'precise-2.1',
          repos       => 'main',
          key         => 'F8AF89DD',
          key_source  => 'http://download.mirantis.com/precise-fuel-folsom/Mirantis.key',
          #key_server => "pgp.mit.edu",
          include_src => false,
          pin         => '1001'
        }

        apt::source { 'rabbit-3.0':
          location    => 'http://download.mirantis.com/precise-fuel-folsom',
          release     => 'precise-rabbitmq-3.0',
          repos       => 'main',
          key         => '5EDB1B62EC4926EA',
          key_source  => 'http://download.mirantis.com/precise-fuel-folsom/Mirantis.key',
          include_src => false,
        }
      }
      # Below we set our internal repos for testing purposes. Some of them may match with external ones.
      if $type == 'custom' {
	
	if $enable_test_repo { 

	

         apt::source  { 'precise-fuel-folsom':
          location    => $deb_fuel_folsom_repo,
          release     => 'precise-2.1',
          repos       => 'main',
          key         => 'F8AF89DD',
          key_source  => 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom/Mirantis.key',
          #key_server  => "pgp.mit.edu",
          include_src => false,
          #pin         => 1000,
        }->
        apt::pin{'mirantis-releases': priority=> 1001, originator=>$originator }
	}
	else { 
         apt::source  { 'precise-fuel-folsom':
          location    => $deb_fuel_folsom_repo,
          release     => 'precise-2.1',
          repos       => 'main',
          key         => 'F8AF89DD',
          key_source  => 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom/Mirantis.key',
          #key_server  => "pgp.mit.edu",
          include_src => false,
          #pin         => 1000,
        }->
        apt::pin{'mirantis-releases': priority=> 1001, originator=>$originator }
	}
        apt::source { 'cloud-archive':
          location    => $deb_cloud_archive_repo,
          release     => 'precise-updates/folsom',
          repos       => 'main',
          key         => '5EDB1B62EC4926EA',
          key_source  => 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom/cloud-archive.key',
          #key_server   => "pgp.mit.edu",
          include_src => false,
        }

        apt::source { 'rabbit-3.0':
          location    => $deb_rabbit_repo,
          release     => 'precise-rabbitmq-3.0',
          repos       => 'main',
          key         => '5EDB1B62EC4926EA',
          key_source  => 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom/Mirantis.key',
          include_src => false,
        }

        if $upstream_mirror == true {

          file {'/etc/apt/sources.list': ensure => absent }
          File['/etc/apt/sources.list'] -> Apt::Source<||>

          apt::source { 'ubuntu-mirror':
            location => $deb_mirror,
            release  => 'precise',
            repos    => 'main universe multiverse restricted',
          }

           apt::source { 'ubuntu-updates':
            location => $deb_updates,
            release  => 'precise-updates',
            repos    => 'main universe multiverse restricted',
          }

           apt::source { 'ubuntu-security':
            location => $deb_security,
            release  => 'precise-security',
            repos    => 'main universe multiverse restricted',
          }
        }
      }

      if !defined(Class['apt::update']) {
       class { 'apt::update': stage => $::openstack::mirantis_repos::stage }
      }

#     In no one custom Debian repository is defined, it is necessary to force run apt-get update
#     Please uncomment the following block to order puppet to force apt-get update
################ Start of forced apt-get update block ##############
#        class { 'apt':
#          always_apt_update => true,
#        }
################ End of forced apt-get update block ###############
    }

    'RedHat': {
      Yumrepo {
        proxy =>$repo_proxy,
      }
      #added internal/external network mirror
      if $type == 'default' {
        yumrepo { 'openstack-epel-fuel':
          descr      => 'Mirantis OpenStack Custom Packages',
          mirrorlist => 'http://download.mirantis.com/epel-fuel-folsom-2.1/mirror.external.list',
          gpgcheck   => '1',
          gpgkey     => 'http://download.mirantis.com/epel-fuel-folsom-2.1/epel.key  http://download.mirantis.com/epel-fuel-folsom-2.1/centos.key http://download.mirantis.com/epel-fuel-folsom-2.1/rabbit.key http://download.mirantis.com/epel-fuel-folsom-2.1/mirantis.key http://download.mirantis.com/epel-fuel-folsom-2.1/mysql.key',
        }
      }

      if $type == 'custom' {
        yumrepo { 'openstack-epel-fuel':
          descr      => 'Mirantis OpenStack Custom Packages',
          mirrorlist => $fuel_mirrorlist,
          gpgcheck   => '1',
          gpgkey     => 'http://download.mirantis.com/epel-fuel-folsom-2.1/epel.key  http://download.mirantis.com/epel-fuel-folsom-2.1/centos.key http://download.mirantis.com/epel-fuel-folsom-2.1/rabbit.key http://download.mirantis.com/epel-fuel-folsom-2.1/mirantis.key http://download.mirantis.com/epel-fuel-folsom-2.1/mysql.key',
        }

        if $upstream_mirror == true {
          yumrepo { 'centos-base':
            descr      => 'Local base mirror repository',
            name       => 'base',
            mirrorlist => $mirrorlist_base,
          }

          yumrepo { 'centos-updates':
            descr      => 'Local updates mirror repository',
            name       => 'updates',
            mirrorlist => $mirrorlist_updates,
          }
        }
      }

      if $enable_test_repo {
        yumrepo {'openstack-osci-repo':
          descr      => 'Mirantis OpenStack OSCI Packages',
          baseurl    => 'http://osci-koji.srt.mirantis.net/mash/fuel-folsom/x86_64/',
          gpgcheck   => '1',
          gpgkey     => 'http://download.mirantis.com/epel-fuel-folsom/epel.key  http://download.mirantis.com/epel-fuel-folsom/centos.key http://download.mirantis.com/epel-fuel-folsom/rabbit.key http://download.mirantis.com/epel-fuel-folsom/mirantis.key http://download.mirantis.com/epel-fuel-folsom/mysql.key',
        }
      }

      if $enable_epel {
        Yumrepo {
          failovermethod => 'priority',
          gpgkey         => 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6',
          gpgcheck       => 1,
          enabled        => 1,
        }

        yumrepo { 'epel-testing':
          descr      => 'Extra Packages for Enterprise Linux 6 - Testing - $basearch',
          mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=testing-epel6&arch=$basearch',
        }

        yumrepo { 'epel':
          descr      => 'Extra Packages for Enterprise Linux 6 - $basearch',
          mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        }
      }

#Puppetlabs repos are really slow. This can slow deployment or even lead to yum timeout.

      if $disable_puppet_labs_repos {
          if defined (Yumrepo['puppetlabs-products']) {yumrepo {'puppetlabs-products': enabled=>0 }}
          if defined (Yumrepo['puppetlabs-deps']) {yumrepo {'puppetlabs-deps': enabled=>0}}
      }

      exec {'yum_make_safe_cache':
        command => "/usr/bin/yum clean all",
      }
      Yumrepo<||> -> Exec['yum_make_safe_cache']
    }
    default: {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }
}
