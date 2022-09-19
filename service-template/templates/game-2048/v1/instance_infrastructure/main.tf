
resource "kubernetes_namespace" "game_2048" {
  metadata {
    name = var.service_instance.inputs.kubernetes_namespace
  }
}
resource "kubernetes_deployment" "game_2048" {
  metadata {
    name      = "game-2048"
    namespace = kubernetes_namespace.game-2048.name
    labels = {
      "app.kubernetes.io/name" = "app-2048"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "app-2048"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "app-2048"
        }
      }
      spec {
        container {
          image = join(":", ["public.ecr.aws/l6m2t8p7/docker-2048", var.service_instance.inputs.container_version])
          name  = "app-2048"
          resources {
            limits = {
              cpu    = var.service_instance.inputs.resource_cpu_limits    #"0.5m"
              memory = var.service_instance.inputs.resource_memory_limits #"512Mi"
            }
            requests = {
              cpu    = var.service_instance.inputs.resource_cpu_requests    #"250m"
              memory = var.service_instance.inputs.resource_memory_requests #"50Mi"
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "game_2048" {
  metadata {
    name      = "game-2048"
    namespace = kubernetes_namespace.game-2048.name
  }
  spec {
    port {
      port        = var.service_instance.inputs.port
      target_port = var.service_instance.inputs.target_port
      protocol    = "TCP"
    }
    type = "NodePort"
  }
}


resource "kubernetes_ingress" "game_2048" {
  wait_for_load_balancer = true
  metadata {
    name = "app-2048"
    annotations = {
      "alb.ingress.kubernetes.io/scheme" : "internet-facing"
      "alb.ingress.kubernetes.io/target-type" : "ip"
    }
  }
  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = kubernetes_service.game_2048.metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
}