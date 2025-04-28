
module "ssh_cmd" {
  source = "../ssh_cmd"

  hostname        = "192.168.1.80"
  private_key_pem = "${path.module}/192.168.1.80.pem"
  command         = "cat /var/lib/rancher/k3s/server/token"
}
