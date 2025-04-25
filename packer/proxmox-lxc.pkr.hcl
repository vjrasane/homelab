packer {
  required_plugins {
    lxc = {
      source  = "github.com/hashicorp/lxc"
      version = "~> 1"
    }
  }
}

source "lxc" "lxc-k3s" {
  config_file = "lxc-server.conf"
  template_name = "ubuntu"
  template_environment_vars = ["SUITE=trusty"]
}

build {
    sources = ["source.lxc.lxc-k3s"]
}
