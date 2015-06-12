# == Class: terraform
#
# Installs Terraform, the modern automated infrastructure creation tool.
#
# === Parameters
#
# [*ensure*]
#  Defaults to 'installed', if set to 'absent' will remove Terraform.
#
# [*version*]
#  The version of Terraform to install, defaults to '0.5.3'.
#
# [*bin_dir*]
#  The binary directory to place Terraform in.  Defaults to '/usr/local/bin'.
#
# [*cache_dir*]
#  The directory to cache Terraform release archives in.  Defaults to
#  '/usr/local/terraform'.
#
# [*base_url*]
#  The base download URL to retrieve Terraform from, including a
#  a trailing '/'.  Defaults to: 'https://dl.bintray.com/mitchellh/terraform/'.
#
class hashiconfigure(){


class terraform(
  $version   = '0.5.3',
  $latest_legacy_version = '0.1.0',
  $lowercase_name = 'terraform',
  $uppercase_name = 'Terraform',
  $package_contents = [
    'terraform',
    'terraform-provider-atlas',
    'terraform-provider-aws',
    'terraform-provider-cloudflare',
    'terraform-provider-cloudstack',
    'terraform-provider-consul',
    'terraform-provider-digitalocean',
    'terraform-provider-dme',
    'terraform-provider-dnsimple',
    'terraform-provider-docker',
    'terraform-provider-google',
    'terraform-provider-heroku',
    'terraform-provider-mailgun',
    'terraform-provider-null',
    'terraform-provider-openstack',
    'terraform-provider-template',
    'terraform-provider-terraform',
    'terraform-provisioner-chef',
    'terraform-provisioner-file',
    'terraform-provisioner-local-exec',
    'terraform-provisioner-remote-exec',
  ]
){
  create_resource(
    'hashicorp::binarry', 
    {
      'version'               => $version,
      'latest_legacy_version' => $latest_legacy_version,
      'lowercase_name'        => $lowercase_name,
      'uppercase_name'        => $uppercase_name,
      'package_contents'      => $package_contents,
    }
  )
}


class binary(
  $version,
  $lowercase_name,
  $uppercase_name,
  $package_contents,
  $ensure    = 'installed',
  $bin_dir   = '/usr/local/bin',
  $cache_dir = '/usr/local/${lowercase_name}',
  $base_url = 'https://dl.bintray.com/mitchellh/${lowercase_name}/'
){
  case $ensure {
    'present', 'installed': {
      # Need parameters from sys and unzip installed.
      include sys
      include sys::unzip

      if $::architecture in ['x86_64', 'amd64', 'x64'] {
        $arch = 'amd64'
      } else {
        $arch = '386'
      }

      if versioncmp($version, '0.1.0') >= 0 {
        $prefix = '${lowercase_name}_'
      } else {
        $prefix = ''
      }

      $hashicorp_basename = inline_template(
        "<%= \"#{@prefix}#{@version}_#{scope['::kernel'].downcase}_#{@arch}.zip\" %>"
      )

      $hashicorp_zip = "${cache_dir}/${hashicorp_basename}"
      $hashicorp_url = "${base_url}${hashicorp_basename}"

      # Ensure cache directory for this program's zip archives exists.
      file { $cache_dir:
        ensure => directory,
        owner  => 'root',
        group  => $sys::root_group,
        mode   => '0644',
      }

      # Download the Hashicorp zip archive to the cache.
      sys::fetch { 'download-${lowercase_name}':
        destination => $hashicorp_zip,
        source      => $hashicorp_url,
        require     => File[$cache_dir],
      }

      # Unzip directly into the binary directory, overwriting previous files.
      exec { 'install-${lowercase_name}':
        command => "${sys::unzip::path} -o ${hashicorp_zip}",
        path    => [$bin_dir, '/usr/bin', '/bin'],
        cwd     => $bin_dir,
        user    => 'root',
        unless  => "test -x ${lowercase_name} && ${lowercase_name} version | head -n 1 | grep '^${uppercase_name} v${version}$'",
        require => Sys::Fetch['download-${lowercase_name}'],
      }
    }
    'absent', 'uninstalled': {
      # Ensure the binaries are removed.
      $binaries = prefix(
        $package_contents,
        "${bin_dir}/"
      )

      file { $binaries:
        ensure => absent,
      }
    }
    default: {
      fail("Invalid ensure value for ${lowercase_name}: ${ensure}.\n")
    }
  }
}
}