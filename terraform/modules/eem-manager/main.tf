# ========================================================================
# STAGE 1: PRE-REQS (Namespaces & Secrets)
# ========================================================================

# Create the Namespace
resource "kubernetes_namespace_v1" "eem_namespace" {
  metadata {
    name = var.namespace
  }
}

# Create the Image Pull Secret for IBM Entitled Registry
resource "kubernetes_secret_v1" "ibm_entitlement_key" {
  metadata {
    name      = "ibm-entitlement-key"
    namespace = kubernetes_namespace_v1.eem_namespace.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        # Update this line to use the private server variable!
        (var.private_registry_server) = { 
          username = var.registry_user
          password = var.registry_password
          auth     = base64encode("${var.registry_user}:${var.registry_password}")
        }
      }
    })
  }
}

# ========================================================================
# STAGE 2: DEPLOY OPERATOR
# ========================================================================

# Install the CRDs
# This prevents Helm ownership lockouts in multi-tenant clusters
resource "null_resource" "eem_crds" {
  triggers = {
    crd_version = var.crd_chart_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      helm repo add ${var.helm_repo_name} ${var.helm_repo_url}
      helm repo update
      helm template eem-crds ${var.helm_repo_name}/${var.crd_chart_name} --version ${var.crd_chart_version} | kubectl apply --kubeconfig ${var.kubeconfig_path} --context ${var.kube_context} -f -
    EOT
  }
}

# Install the Operator
resource "helm_release" "eem_operator" {
  name       = var.operator_chart_name
  repository = var.helm_repo_url
  chart      = var.operator_chart_name
  version    = var.operator_chart_version
  namespace  = kubernetes_namespace_v1.eem_namespace.metadata[0].name

  wait = true

# Inject the custom values.yaml for air-gapped registries
  values = [
    templatefile("${path.module}/templates/values.yaml.tftpl", {
      PUBLIC_REGISTRY_SERVER  = var.public_registry_server
      PRIVATE_REGISTRY_SERVER = var.private_registry_server    
      PUBLIC_REGISTRY_PATH  = var.public_registry_path
      PRIVATE_REGISTRY_PATH = var.private_registry_path
      OPERATOR_VERSION = var.operator_chart_version
      # Dynamically grab the name of the secret we created in step 1
      PULL_SECRET_NAME = kubernetes_secret_v1.ibm_entitlement_key.metadata[0].name 
    })
  ]

  # Ensure CRDs are fully deployed before the Operator starts
  depends_on = [null_resource.eem_crds]
}

# ========================================================================
# STAGE 3: DEPLOY INSTANCE (The Magic Templating Step)
# ========================================================================

resource "kubectl_manifest" "eem_manager_instance" {
  yaml_body = templatefile("${path.module}/templates/eem-manager.yaml.tftpl", {
    NAMESPACE        = kubernetes_namespace_v1.eem_namespace.metadata[0].name
    UI_HOSTNAME      = var.ui_hostname
    ADMIN_HOSTNAME   = var.admin_hostname
    GATEWAY_HOSTNAME = var.gateway_hostname
    SERVER_HOSTNAME  = var.server_hostname
    INGRESS_CLASS    = var.ingress_class
    ALB_SCHEME       = var.alb_scheme
    ALB_GROUP_NAME   = var.alb_group_name
    ACM_ARN          = var.acm_arn
  })

  # Ensure the Operator is fully running before we try to create an EventEndpointManagement CR
  depends_on = [helm_release.eem_operator]
}

# ========================================================================
# STAGE 4: CONFIGURE ROLES
# ========================================================================

# Because the IBM Operator auto-generates the role secrets *after* the instance 
# starts, we use a null_resource to run your exact patching commands against them.
resource "null_resource" "patch_eem_roles" {
  # This triggers the patch every time the Manager instance YAML changes
  triggers = {
    manager_manifest_sha = sha256(kubectl_manifest.eem_manager_instance.yaml_body)
  }

  depends_on = [kubectl_manifest.eem_manager_instance]

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for Operator to generate default secrets..."
      
      TIMEOUT=300 # 5 minute maximum wait time
      INTERVAL=5  # Check every 5 seconds
      ELAPSED=0
      
      # Actively poll the Kubernetes API until the secret is found
      while ! kubectl get secret eem-manager-ibm-eem-user-credentials \
        --namespace ${var.namespace} \
        --kubeconfig ${var.kubeconfig_path} \
        --context ${var.kube_context} >/dev/null 2>&1; do
        
        if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
          echo "ERROR: Timeout reached! The Operator failed to create the secrets."
          exit 1
        fi
        
        echo "Secrets not ready yet. Waiting $INTERVAL seconds... ($ELAPSED/$TIMEOUT)"
        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
      done

      echo "Secrets generated successfully!"
      
      echo "Patching user credentials..."
      kubectl patch secret eem-manager-ibm-eem-user-credentials \
        --namespace ${var.namespace} \
        --kubeconfig ${var.kubeconfig_path} \
        --context ${var.kube_context} \
        --type='json' \
        -p="[{\"op\" : \"replace\" ,\"path\" : \"/data/user-credentials.json\" ,\"value\" : \"$(cat ${path.module}/config/myusers.json | base64 -w 0)\"}]"

      echo "Patching role mappings..."
      kubectl patch secret eem-manager-ibm-eem-user-roles \
        --namespace ${var.namespace} \
        --kubeconfig ${var.kubeconfig_path} \
        --context ${var.kube_context} \
        --type='json' \
        -p="[{\"op\" : \"replace\" ,\"path\" : \"/data/user-mapping.json\" ,\"value\" : \"$(cat ${path.module}/config/myroles.json | base64 -w 0)\"}]"
    EOT
  }
}