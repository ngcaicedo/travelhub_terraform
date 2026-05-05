## 5. Ejemplo de despliegue de alarmas CloudWatch con Terraform

Se ha incorporado un módulo reutilizable para crear alarmas de CloudWatch vía Terraform. Ejemplo de configuración para monitorear el uso de CPU en ECS:

```
alarms = [
   {
      name                = "ecs-cpu-utilization-high"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "CPUUtilization"
      namespace           = "AWS/ECS"
      period              = 60
      statistic           = "Average"
      threshold           = 70
      description         = "Alarma si el uso de CPU supera el 70% en el servicio ECS."
      actions_enabled     = true
      alarm_actions       = [] # Agregar ARN de SNS o AutoScaling si aplica
      ok_actions          = []
      dimensions = {
         ClusterName = "<nombre-cluster>"
         ServiceName = "<nombre-servicio-ecs>"
      }
      treat_missing_data = "missing"
   }
]
```

Agrega la variable `alarms` en tu archivo `terraform.tfvars` y personaliza los valores según tu entorno y servicios ECS.
# Reporte Técnico: Configuración de Escalado y Resiliencia en AWS

Este documento detalla la configuración técnica necesaria para cumplir con los criterios de aceptación de alta disponibilidad (800 TPM) y escalado automático en AWS ECS Fargate, utilizando Amazon SQS como amortiguador y CloudWatch como orquestador de métricas.

---

## 1. Configuración de Amazon CloudWatch y Auto Scaling

Para garantizar que el sistema responda al superar el 70% de uso de CPU y maneje la rampa de carga, se deben configurar los siguientes componentes.

### A. Alarma de CloudWatch (CPU Utilization)
1. **Métrica:** `AWS/ECS` > `ClusterName` > `ServiceName` > `CPUUtilization`.
2. **Estadística:** Promedio (Average).
3. **Periodo:** 1 minuto (para una reacción rápida ante la rampa de 150 a 800 TPM).
4. **Condición:** Umbral estático > 70.
5. **Datapoints to Alarm:** 1 de 1 (para máxima sensibilidad) o 2 de 2 (para evitar falsos positivos por picos momentáneos).

### B. Service Auto Scaling (Target Tracking)
Esta es la configuración recomendada para mantener el uso de CPU cerca del objetivo:
* **Target Value:** 70.0
* **Scale-out Cooldown:** 60 segundos.
* **Scale-in Cooldown:** 300 segundos (para evitar terminaciones prematuras durante fluctuaciones).

### C. Alarma para Amazon SQS (Backlog Per Task)
Dado que el CPU puede tardar en subir mientras los mensajes se acumulan, se recomienda una alarma adicional:
1. **Métrica personalizada:** Mensajes visibles en SQS divididos por el número de tareas en ejecución.
2. **Acción:** Escalar si el "Backlog por tarea" supera un umbral definido (ej. 50 mensajes pendientes por contenedor).

---

## 2. Configuración de Amazon SQS (Amortiguador de Pagos)

Para absorber los picos de hasta 800 TPM sin rechazar peticiones:

* **Visibilidad (Visibility Timeout):** Debe ser al menos 6 veces el tiempo promedio de procesamiento del microservicio para evitar que un mensaje se procese doblemente durante reintentos.
* **Retención de mensajes:** 4 días (estándar).
* **Redrive Policy:** Configurar una **Dead Letter Queue (DLQ)**. Si un pago falla 3 veces, se mueve a la DLQ para auditoría manual, manteniendo el 100% de éxito en la ingesta inicial.

---

## 3. Ajuste de Realidad: Implementación de Respuesta Asíncrona

El criterio de éxito del **100% (HTTP 2xx)** durante una rampa agresiva es virtualmente imposible de cumplir si el microservicio intenta procesar el pago de forma síncrona mientras ECS aprovisiona nuevas tareas. 

### Recomendación de Arquitectura Final
Para cumplir estrictamente los SLAs y el 100% de disponibilidad:

1. **Ingesta (Microservicio Productor):**
   - Recibe el POST del cliente.
   - Realiza una validación de esquema rápida.
   - Publica el evento de pago en **SQS**.
   - **Respuesta inmediata:** Retorna un `HTTP 202 Accepted` con un `transactionId`. 
   - *Resultado:* El sistema nunca rechaza la petición (100% 2xx) porque la capacidad de ingesta de SQS es prácticamente infinita.

2. **Procesamiento (Microservicio Consumidor):**
   - Las tareas de ECS Fargate consumen mensajes de SQS a su propio ritmo.
   - CloudWatch monitorea el tamaño de la cola y el CPU.
   - Si la cola crece, CloudWatch lanza más contenedores Fargate.
   - Una vez procesado, el estado se actualiza en la base de datos o se notifica vía WebSocket/Push al usuario.

3. **Scale-in Seguro:**
   - Durante el descenso de carga, configurar el `Deregistration Delay` en el Load Balancer a un valor que permita terminar las transacciones en vuelo (recomendado: 120-300s).

---

## 4. Resumen de Capacidades para 3,600 Usuarios

Con 600 usuarios por país (6 países), el sistema debe estar distribuido en al menos 3 zonas de disponibilidad (AZs) para cumplir con el SLA:

| Componente | Configuración |
| :--- | :--- |
| **ECS Tasks Mínimas** | 6 (1 por país para asegurar alta disponibilidad inicial) |
| **ECS Tasks Máximas** | Definir según pruebas de carga (estimado: 24-36 tareas) |
| **ALB Health Check** | `Interval: 30s`, `Timeout: 5s`, `Healthy Threshold: 2` |
| **SQS Throughput** | Ilimitado (Standard Queue) |

---

**Nota final:** El uso de SQS como "buffer" desacopla la recepción del procesamiento, lo que garantiza que los tiempos de respuesta del API se mantengan bajos y constantes, independientemente de si el backend está escalando o procesando los 800 TPM.
