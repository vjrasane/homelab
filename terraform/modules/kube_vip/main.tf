terraform {
  required_version = ">= 0.13"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

variable "k3s_vip" {
  type = string
}

resource "kubernetes_service_account" "kube_vip" {
  metadata {
    name      = "kube-vip"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role" "kube_vip_role" {
  metadata {
    annotations = {
      "rbac.authorization.kubernetes.io/autoupdate" = "true"
    }
    name = "system:kube-vip-role"
  }

  rule {
    api_groups = [""]
    resources  = ["services/status"]
    verbs      = ["update"]
  }
  rule {
    api_groups = [""]
    resources  = ["services", "endpoints"]
    verbs      = ["list", "get", "watch", "update"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list", "get", "watch", "update", "patch"]
  }
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["list", "get", "watch", "update", "create"]
  }
  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["list", "get", "watch", "update"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["list"]
  }
}

resource "kubernetes_cluster_role_binding" "kube_vip_role_binding" {
  metadata {
    name = "system:kube-vip-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.kube_vip_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.kube_vip.metadata[0].name
    namespace = kubernetes_service_account.kube_vip.metadata[0].namespace
  }
}

resource "kubectl_manifest" "kube_vip" {
  yaml_body = templatefile("${path.module}/templates/kube-vip-ds.yml.tftpl", {
    namespace = kubernetes_service_account.kube_vip.metadata[0].namespace
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
