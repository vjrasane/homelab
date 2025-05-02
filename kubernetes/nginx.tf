resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx"
  }
}

locals {
  nginx_namespace = kubernetes_namespace.nginx.metadata[0].name
  nginx_domain_name = "nginx.${var.cloudflare_domain_name}"
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx"
    namespace = local.nginx_namespace
    labels = {
      app = "nginx"
    }
  }


  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"

          port {
            container_port = 80
          }
        }
      }
    }
  }

}


resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx"
    namespace = local.nginx_namespace
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "nginx"
    }
    port {
      port = 80
    }
  }
}

variable "cloudflare_domain_name" {
  type = string
}

module "nginx_cert" {
  source = "./modules/tls_cert"

  domain_names = [local.nginx_domain_name]
  namespace    = local.nginx_namespace
  issuer_name  = local.cluster_issuer_manifest.metadata.name
  secret_name  = "nginx-cert"
}

# locals {
#   nginx_cert_manifest = {
#     apiVersion = "cert-manager.io/v1"
#     kind       = "Certificate"
#     metadata = {
#       name      = "nginx-cert"
#       namespace = kubernetes_namespace.nginx.metadata[0].name
#     }
#     spec = {
#       secretName = "nginx-cert"
#       issuerRef = {
#         kind = "ClusterIssuer"
#         name = local.cluster_issuer_manifest.metadata.name
#       }
#       dnsNames = ["nginx.${var.cloudflare_domain_name}"]
#     }
#   }
# }

# resource "kubectl_manifest" "nginx_certificate" {
#   yaml_body = yamlencode(local.nginx_cert_manifest)

#   depends_on = [kubectl_manifest.cluster_issuer]
# }

resource "kubernetes_ingress_v1" "nginx" {
  metadata {
    name      = "nginx-ingress"
    namespace = local.nginx_namespace
  }

  spec {
    rule {
      host = local.nginx_domain_name

      http {
        path {
          path = "/"

          backend {
            service {
              name = kubernetes_service.nginx.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    tls {
      secret_name = module.nginx_cert.secret_name 
      hosts       = module.nginx_cert.domain_names 
    }
  }
}
