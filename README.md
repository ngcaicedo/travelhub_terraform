# TravelHub - Infraestructura con Terraform

Infraestructura como código para TravelHub. Gestiona red, datos, registro de imágenes, cómputo (ECS Fargate + ALB) y CI/CD (CodeBuild / CodePipeline).

## Estructura del repositorio

```
travelhub_terraform/
├── stacks/<stack>/           # Configuración Terraform por capa
├── environments/<env>/<stack>/  # Variables por entorno (.tfvars)
└── modules/                  # Módulos reutilizables
```

- **`stacks/`** — Raíz Terraform de cada capa (`networking`, `registry`, `data`, `compute`, `cicd`). Cada stack tiene su propio backend de estado.
- **`environments/`** — Archivos `terraform.tfvars` y `backend.tfvars` por entorno (`development`, `production`). Los `.tfvars` reales no se versionan; usa los `.example` como plantilla.
- **`modules/`** — Módulos reutilizables (ALB, ECS, ECR, RDS, CodeBuild, CodePipeline, etc.).

## Orden de despliegue

Los stacks tienen dependencias entre sí. Deben desplegarse en este orden:

1. **networking** — VPC, subnets, security groups (ALB/ECS).
2. **registry** — Repositorios ECR (una imagen por microservicio).
3. **data** — RDS, Secrets Manager.
4. **compute** — Clúster ECS, ALB, target groups, servicios ECS.
5. **cicd** — CodeBuild, CodePipeline, conexión GitHub (CodeStar Connections).

> **Nota:** En el Makefile, `CI only` implica desplegar **registry** y **cicd** sin necesidad de **compute**. El flujo completo sigue el orden anterior.

## Uso rápido (Makefile)

```bash
make init   ENV=development STACK=networking
make plan   ENV=development STACK=networking
make apply  ENV=development STACK=networking
```

- `ENV`: `development` o `production`
- `STACK`: `networking`, `registry`, `data`, `compute` o `cicd`

Otros comandos: `fmt`, `validate`, `destroy`. Consulta `make help` para más detalles.

---

## Agregar un nuevo microservicio

Un microservicio necesita configuración en tres capas: **imagen (ECR)**, **runtime (ECS + ALB)** y **pipeline (CodeBuild + CodePipeline)**.

### Convenciones de nombres

| Concepto | Formato | Ejemplo |
|----------|---------|---------|
| Clave en Terraform | minúsculas, sin espacios | `orders` |
| Repositorio ECR | `travelhub-<clave>` | `travelhub-orders` |
| Ruta del buildspec (GitHub) | `services/<clave>/buildspec.yml` | `services/orders/buildspec.yml` |

### Paso 1 — Stack `registry`: crear repositorio ECR

Agrega el nombre del repositorio (ej. `travelhub-orders`) a la lista `repository_names` en `stacks/registry/variables.tf`.

```bash
make apply ENV=development STACK=registry
```

### Paso 2 — Stack `compute`: ALB + servicio ECS

Edita `stacks/compute/main.tf`:

**a) Reglas del ALB** — En `module.alb`, dentro de `services`, agrega una entrada con la clave del servicio:

```hcl
orders = {
  port              = 8080          # Debe coincidir con container_port
  health_check_path = "/health"
  priority          = 300           # Entero ÚNICO entre servicios
  path_patterns     = ["/api/v1/orders*"]
}
```

**b) Servicio ECS** — Crea un nuevo bloque de módulo:

```hcl
module "orders_service" {
  source = "../../modules/ecs_service"

  service_name     = "orders"
  ecr_image_url    = "${local.registry.repository_urls["travelhub-orders"]}:latest"
  target_group_arn = module.alb.target_group_arns["orders"]

  # Mismos valores que los servicios existentes:
  cluster_id         = ...
  subnet_ids         = ...
  security_group_id  = ...
  execution_role_arn = ...

  environment_variables = { ... }
  secrets               = { ... }  # Referencian local.data_state.*
}
```

**c) IAM** — Si el contenedor necesita nuevos secretos de Secrets Manager, amplía la política `aws_iam_role_policy.ecs_secrets_access` con los ARNs correspondientes.

**d) Output** — En `stacks/compute/outputs.tf`, agrega:

```hcl
output "orders_service_name" {
  value = module.orders_service.service_name
}
```

```bash
make apply ENV=development STACK=compute
```

### Paso 3 — Stack `cicd`: build y despliegue

Edita `stacks/cicd/main.tf`:

**a) CodeBuild:**

```hcl
module "codebuild_orders" {
  source = "../../modules/codebuild"

  service_name       = "orders"
  buildspec_path     = "services/orders/buildspec.yml"
  ecr_repository_url = local.registry.repository_urls["travelhub-orders"]
}
```

**b) CodePipeline:**

```hcl
module "pipeline_orders" {
  source = "../../modules/codepipeline"

  service_name             = "orders"
  codebuild_project_name   = module.codebuild_orders.project_name
  ecs_cluster_name         = local.compute.cluster_name
  ecs_service_name         = local.compute.orders_service_name

  # Mismos valores que los otros pipelines:
  project_name             = ...
  environment              = ...
  codestar_connection_arn  = ...
  github_repo_id           = ...
  branch_name              = ...
}
```

```bash
make apply ENV=development STACK=cicd
```

### Paso 4 — Repositorio de la aplicación

En el repo de GitHub (el referenciado en `github_repo_id`), crea:
- `services/orders/buildspec.yml`
- El Dockerfile correspondiente

### Paso 5 — CodeStar Connections

La primera vez, la conexión GitHub en AWS puede quedar en estado **Pending** hasta completar la autorización en la consola de AWS. Sin esto, el stage Source del pipeline no funcionará.

### Checklist resumen

- [ ] Nombre ECR `travelhub-<servicio>` agregado en **registry**.
- [ ] Entrada en `module.alb.services` con prioridad única y paths correctos.
- [ ] Módulo `ecs_service` con imagen ECR, variables, secretos e IAM.
- [ ] Output `<servicio>_service_name` en **compute**.
- [ ] Módulos `codebuild` + `codepipeline` en **cicd** enlazados al clúster y servicio ECS.
- [ ] `buildspec.yml` y Dockerfile en el repo de la app bajo `services/<servicio>/`.

> **Nota:** El módulo `ecs_service` ignora cambios en `task_definition` y `desired_count` en el ciclo de vida del recurso. Las actualizaciones de imagen las maneja el pipeline, no `terraform apply`.

---

## SES — Verificar destinatarios en sandbox

El módulo `modules/email` crea la identidad del **remitente** (`ses_sender_email`) y le manda un link de verificación. Mientras la cuenta AWS esté en **SES sandbox**, también hay que verificar cada **destinatario** antes de poder enviarle correo (de lo contrario SES rechaza el envío con `MessageRejected: Email address is not verified`).

### Verificar un destinatario

```bash
aws ses verify-email-identity \
  --email-address <correo-destinatario> \
  --region us-east-1
```

AWS envía un link de confirmación al buzón. Al hacer clic, la identidad queda en estado `Success` y ya puede recibir correos.

### Consultar el estado de verificación

```bash
aws ses get-identity-verification-attributes \
  --identities <correo-destinatario> \
  --region us-east-1
```

Devuelve `"VerificationStatus": "Success"` cuando la identidad está lista.

### Listar todas las identidades verificadas

```bash
aws ses list-identities --identity-type EmailAddress --region us-east-1
```

### Quitar una identidad

```bash
aws ses delete-identity --identity <correo> --region us-east-1
```

### Truco útil en desarrollo

Gmail trata `cuenta+algo@gmail.com` como la misma bandeja, pero SES lo registra como identidad distinta. Así puedes verificar varios "usuarios" contra el mismo inbox:

```bash
aws ses verify-email-identity --email-address cuenta+viajero1@gmail.com --region us-east-1
aws ses verify-email-identity --email-address cuenta+viajero2@gmail.com --region us-east-1
```

### Salir del sandbox

Para no tener que verificar cada destinatario, hay que solicitar acceso a producción:

1. Consola AWS → **Amazon SES** → **Account dashboard**.
2. Botón **Request production access**.
3. Llenar caso de uso (tipo de correo, volumen estimado, proceso anti-abuse).
4. AWS responde típicamente en < 24h.

Una vez aprobado, SES acepta cualquier destinatario sin verificación previa.

---

## RDS — Extensión `unaccent` (filtro de búsqueda accent-insensitive)

El microservicio `properties` filtra por ciudad usando `unaccent(LOWER(location))` para que `?city=Bogota` haga match con `Bogotá, Colombia`. La extensión `unaccent` viene incluida con Postgres pero hay que habilitarla por DB.

Se gestiona desde Terraform en el stack **data** mediante el provider [`cyrilgdn/postgresql`](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest):

```hcl
# stacks/data/main.tf
resource "postgresql_extension" "unaccent" {
  name = "unaccent"
}
```

El `terraform apply` del stack data instala (o no toca, si ya existe) la extensión idempotentemente.

### Requisito: conectividad al RDS al momento del apply

El provider abre una conexión TCP al endpoint del RDS:

- **Development**: el RDS está marcado `publicly_accessible = true` y el SG abre el puerto 5432 a `db_public_access_cidrs`. `terraform apply` desde la máquina del operador funciona directamente.
- **Production**: el RDS está privado (`publicly_accessible = false`). Hay que correr el apply desde dentro de la VPC. Opciones:
  - CodeBuild con `vpc_config` apuntando a las subnets privadas y SG con egreso al RDS (recomendado para CI).
  - Cloud9/EC2 bastion temporal en la VPC.
  - VPN/Direct Connect si existe.

### Verificar manualmente

```bash
psql "host=<rds-endpoint> user=<RDS_USERNAME> dbname=<RDS_DB_NAME>" \
  -c "SELECT unaccent('Bogotá');"
# unaccent
# ----------
# Bogota
```

Si la extensión no está, `GET /api/v1/properties/search?city=...` devuelve 500 (la query usa `func.unaccent` que no existiría).
