
resource "helm_release" "traefik_crds" {
  name             = "traefik-crds"
  namespace        = "traefik"
  create_namespace = true
  repository       = "https://helm.traefik.io/traefik"
  chart            = "traefik-crds"
  version          = "v1.7.0"
}

resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = "traefik"
  create_namespace = true
  chart            = "traefik"
  version          = "v35.2.0"
  repository       = "https://helm.traefik.io/traefik"
  skip_crds        = true

  depends_on = [helm_release.traefik_crds]

  values = [
    <<-EOF
        service:
          spec:
            loadBalancerIP: "${local.traefik_ip}"
        ingressClass:
          enabled: true
          isDefaultClass: true
        dashboard:
          enabled: true
        ports:
          web:
            redirections:
              entryPoint:
                to: websecure
                scheme: https
                permanent: true
          websecure:
            tls:
              enabled: true
  EOF
  ]
}

resource "helm_release" "traefik_middleware" {
  name             = "traefik-middleware"
  namespace        = "traefik"
  create_namespace = true
  chart            = "${path.module}/charts/middleware"

  depends_on = [helm_release.traefik_crds]
}
