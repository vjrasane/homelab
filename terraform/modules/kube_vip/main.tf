terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

variable "k3s_vip" {
  type = string
}

resource "kubectl_manifest" "kube_vip_rbac" {
  yaml_body = file("${path.module}/manifests/kube-vip-rbac.yml") 
}

resource "kubectl_manifest" "kube_vip" {
  yaml_body = templatefile("${path.module}/templates/kube-vip-ds.yml.tftpl", {
    k3s_vip   = var.k3s_vip
  })
}

# resource "kubernetes_daemonset" "kube_vip" {
#   metadata {
#     name      = "kube-vip-ds"
#     namespace = "kube-system"
#   }

#   spec {
#     selector {
#       match_labels = {
#         name = "kube-vip-ds"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           name = "kube-vip-ds"
#         }
#       }

#       spec {
#         host_network         = true
#         service_account_name = kubernetes_service_account.kube_vip.metadata[0].name

#         container {
#           name              = "kube-vip"
#           image             = "ghcr.io/kube-vip/kube-vip:latest"
#           image_pull_policy = "Always"
#           args              = ["manager"]

#           resources {
#           }

#           security_context {
#             capabilities {
#               add = ["NET_ADMIN", "NET_RAW", "SYS_TIME"]
#             }
#           }

#           env {
#             name  = "vip_arp"
#             value = "true"
#           }
#           env {
#             name  = "bgp_enable"
#             value = "false"
#           }
#           env {
#             name  = "port"
#             value = "6443"
#           }
#           env {
#             name  = "vip_interfave"
#             value = "eth0"
#           }
#           env {
#             name  = "vip_cidr"
#             value = "32"
#           }
#           env {
#             name  = "cp_enable"
#             value = "true"
#           }
#           env {
#             name  = "cp_namespace"
#             value = "kube-system"
#           }
#           env {
#             name  = "vip_ddns"
#             value = "false"
#           }
#           env {
#             name  = "svc_enable"
#             value = "false"
#           }
#           env {
#             name  = "vip_leaderelection"
#             value = "true"
#           }
#           env {
#             name  = "vip_leaseduration"
#             value = "15"
#           }
#           env {
#             name  = "vip_renewdeadline"
#             value = "10"
#           }
#           env {
#             name  = "vip_retryperiod"
#             value = "2"
#           }
#           env {
#             name  = "address"
#             value = var.k3s_vip
#           }
#         }

#         affinity {
#           node_affinity {
#             required_during_scheduling_ignored_during_execution {
#               node_selector_term {
#                 match_expressions {
#                   key      = "node-role.kubernetes.io/master"
#                   operator = "Exists"
#                 }
#               }

#               node_selector_term {
#                 match_expressions {
#                   key      = "node-role.kubernetes.io/control-plane"
#                   operator = "Exists"
#                 }
#               }
#             }
#           }
#         }

#         toleration {
#           effect   = "NoSchedule"
#           operator = "Exists"
#         }

#         toleration {
#           effect   = "NoExecute"
#           operator = "Exists"
#         }
#       }
#     }

#     strategy {

#     }
#   }
# }
