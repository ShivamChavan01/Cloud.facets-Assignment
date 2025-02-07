terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}


locals {
  applications = jsondecode(file("${path.module}/apps.json")).applications
}


resource "kubernetes_deployment_v1" "apps" {
  for_each = { for app in local.applications : app.name => app }

  metadata {
    name = "${each.value.name}-deployment"
    labels = {
      app = each.value.name
    }
  }

  spec {
    replicas = each.value.replicas

    selector {
      match_labels = {
        app = each.value.name
      }
    }

    template {
      metadata {
        labels = {
          app = each.value.name
        }
      }

      spec {
        container {
          image = each.value.image
          name  = each.value.name
          
          # Pass args as a single string
          args = ["-listen=:${each.value.port}", "-text=\"I am ${each.value.name}\""]

          port {
            container_port = each.value.port
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "apps" {
  for_each = { for app in local.applications : app.name => app }

  metadata {
    name = "${each.value.name}-service"
  }

  spec {
    selector = {
      app = each.value.name
    }

    port {
      port        = each.value.port
      target_port = each.value.port
    }

    type = "ClusterIP"
  }
}


resource "kubernetes_ingress_v1" "base_ingress" {
  metadata {
    name = "base-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      http {
        dynamic "path" {
          for_each = local.applications
          content {
            path = "/${path.value.name}"
            path_type = "Prefix"
            backend {
              service {
                name = "${path.value.name}-service"
                port {
                  number = path.value.port
                }
              }
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_ingress_v1" "canary_ingresses" {
  for_each = { for app in local.applications : app.name => app }

  metadata {
    name = "${each.value.name}-canary"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "nginx.ingress.kubernetes.io/canary" = "true"
      "nginx.ingress.kubernetes.io/canary-weight" = each.value.traffic_weight
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/${each.value.name}"
          path_type = "Prefix"
          backend {
            service {
              name = "${each.value.name}-service"
              port {
                number = each.value.port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_ingress_v1.base_ingress]
}

