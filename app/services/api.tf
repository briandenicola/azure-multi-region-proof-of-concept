resource "azurerm_container_app" "api" {
  name                         = "api"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = data.azurerm_resource_group.cqrs_regional.name
  revision_mode                = "Multiple"
  workload_profile_name        = "default"

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.app_identity
    ]
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = false
    target_port                = 8080
    transport                  = "auto"

    custom_domain {
      certificate_binding_type = "SniEnabled"
      certificate_id           = data.azurerm_container_app_environment_certificate.this.id
      name                     = "api.ingress.${var.custom_domain}"
    }

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  registry {
    server   = local.acr_name
    identity = var.app_identity
  }

  template {
    # Init Container
    # - name: init-region
    #   image: bjd145/utils:latest
    #   command: ['sh', '-c', 'REGION=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/location?api-version=2017-08-01&format=text"`; echo export REGION=${REGION} >> /env/metadata']
    #   volumeMounts:
    #   - name: config-data
    #     mountPath: /env

    #       command: ['/bin/busybox', 'sh', '-c', 'source /env/metadata; ./main']
    # volumeMounts:
    # - name: config-data
    #   mountPath: /env
    #   readOnly: true

    # livenessProbe:
    #   httpGet:
    #     path: /healthz
    #     port: 8080
    #   initialDelaySeconds: 3
    #   periodSeconds: 3

    # resources:
    #   limits:
    #     cpu: "1"
    #     memory: 256Mi
    #   requests:
    #     cpu: "0.5"
    #     memory: 128Mi

    # ports:
    # - containerPort: 8080
    # envFrom:
    # - secretRef:
    #     name: cqrssecrets

    container {
      name   = "api"
      image  = local.api_image
      cpu    = 0.5
      memory = "1Gi"
    }
  }
}

