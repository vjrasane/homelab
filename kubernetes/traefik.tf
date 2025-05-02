
resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
}

variable "traefik_ip" {
  type = string
  default = "192.168.1.220"
}

resource "helm_release" "traefik" {
  name      = "traefik"
  namespace = kubernetes_namespace.traefik.metadata[0].name

  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"

  set {
    name  = "ingressClass.enabled"
    value = "true"
  }

  set {
    name  = "ingressClass.isDefaultClass"
    value = "true"
  }

  set {
    name = "ports.web.redirections.entrypoints.entryPoint.scheme"
    value = "https"
  }

  set {
    name = "ports.web.redirections.entrypoints.entryPoint.permanent"
    value = "true"
  }

  set {
    name = "ports.web.redirections.entrypoints.entryPoint.to"
    value = "websecure"
  }

  set {
    name  = "ports.websecure.tls.enabled"
    value = "true"
  }

  set {
    name = "service.spec.loadBalancerIP"
    value = var.traefik_ip
  }
}
