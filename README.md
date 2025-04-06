
# GCP Event-Driven Pipeline con Terraform, GCP y Airflow

Este proyecto implementa una arquitectura en Google Cloud orientada a eventos. Usa Terraform para la infraestructura, Cloud Functions para procesamiento de archivos y un DAG en Apache Airflow para cargar y transformar datos en BigQuery.
La solución como tal recibe archivos CSV con datos (por ejemplo, paises.csv) que se pueden subir manualmente al Cloud Storage. Se procesa esos archivos con una Cloud Function, luego Airflow toma esos archivos y los carga a BigQuery y finalmente, transforma los datos y los guarda en una nueva tabla en BigQuery.

## Arquitectura General

1. Recepción de archivos en un bucket de GCS.
2. Cloud Function se dispara automáticamente al detectar un archivo nuevo.
3. La función procesa el archivo y guarda el resultado en una nueva ruta.
4. Un DAG de Airflow toma los archivos procesados y los carga a BigQuery.
5. Se realiza una transformación en BigQuery y se guarda en una tabla final.

## Estructura del proyecto

.
├── .github/workflows/deploy.yml
|
├── cloud_function/
│   ├── main.py
│   └── requirements.txt
|
├── dags/
│   └── gcs_to_bq_dag.py
|
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── outputs.tf
│   └── provider.tf
|
└── README.md


## Pre-requisitos

- Proyecto activo en Google Cloud
- APIs habilitadas: Cloud Functions, Storage, BigQuery, Composer
    
    gcloud services enable \
        storage.googleapis.com \
        bigquery.googleapis.com \
        cloudfunctions.googleapis.com \
        composer.googleapis.com \
        cloudbuild.googleapis.com \
        artifactregistry.googleapis.com \
        iam.googleapis.com
- Cuenta de servicio con rol "Editor" y key en JSON
- Ejecutar el binding para iam.serviceAccountUser
    gcloud iam service-accounts add-iam-policy-binding wom-p1@appspot.gserviceaccount.com \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --project=wom-p1
- Darle permisos a la cuenta que ejecutará el terraform (usuario@tudominio.com)
    gcloud iam service-accounts add-iam-policy-binding wom-p1@appspot.gserviceaccount.com \
    --member="user:usuario@tudominio.com" \
    --role="roles/iam.serviceAccountUser" \
    --project=wom-p1
- Otros permisos
    gcloud iam service-accounts add-iam-policy-binding wom-p1@appspot.gserviceaccount.com \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --project=wom-p1

    gcloud projects add-iam-policy-binding wom-p1 \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/cloudfunctions.developer"

    gcloud projects add-iam-policy-binding wom-p1 \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"

    gcloud projects add-iam-policy-binding wom-p1 \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/cloudfunctions.invoker"

    gcloud projects add-iam-policy-binding wom-p1 \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/cloudfunctions.developer"

    gcloud iam service-accounts add-iam-policy-binding wom-p1@appspot.gserviceaccount.com \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --project=wom-p1

    gcloud iam service-accounts add-iam-policy-binding \
    --role="roles/iam.serviceAccountUser" \
    --member="user:ruddyguerraarias@gmail.com" \
    projects/wom-p1/serviceAccounts/github-deployer@wom-p1.iam.gserviceaccount.com

    gcloud iam service-accounts add-iam-policy-binding \
    github-deployer@wom-p1.iam.gserviceaccount.com \
    --role="roles/iam.serviceAccountUser" \
    --member="user:ruddyguerraarias@gmail.com" \
    --project=wom-p1

    gcloud iam service-accounts add-iam-policy-binding \
    wom-gcs-trigger-function@$PROJECT_ID.iam.gserviceaccount.com \
    --member="serviceAccount:github-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --project=$PROJECT_ID

    gcloud projects add-iam-policy-binding wom-p1 \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

    gcloud iam service-accounts add-iam-policy-binding wom-gcs-trigger-function@wom-p1.iam.gserviceaccount.com \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --project=wom-p1



- Para pruebas en local instalar: Terraform, gcloud CLI, GitHub CLI

## 1. Empaquetar la Cloud Function
Ya se encuentra empaquetado pero si se actualiza el código se debe volver a generar manualmente el zip

cd cloud_function
zip -r ../cloud_function.zip .


## 2. Configuración de Terraform

Archivo terraform.tfvars:

project_id    = "wom-p1"
region        = "us-central1"
bucket_name   = "wom-bucket-demo"
function_name = "wom-gcs-trigger-function"
service_account = "github-deployer@wom-p1.iam.gserviceaccount.com"
service_account_cf = "wom-gcs-trigger-function@wom-p1.iam.gserviceaccount.com"

Inicializa y aplica:

cd terraform
terraform init
terraform apply -auto-approve

## 3. CI/CD con GitHub Actions

El repositorio incluye un workflow en .github/workflows/deploy.yml que automatiza el despliegue de tu infraestructura al hacer push en la rama main. Este workflow ejecuta los comandos de Terraform para crear o actualizar los recursos en Google Cloud Platform (GCP).

Para que el pipeline funcione, necesitas configurar los secrets de autenticación en GitHub.

Crear un secreto en GitHub: Para que GitHub Actions pueda autenticarse con Google Cloud y ejecutar Terraform, necesitas agregar los secretos de Google Cloud a tu repositorio en GitHub. Sigue estos pasos:

1. **Ve a tu repositorio en GitHub**.
2. **Haz clic en "Settings"** (Configuración) en el menú superior.
3. En el menú lateral izquierdo, selecciona **"Secrets and variables"**.
4. Haz clic en Actions
5. Haz clic en el botón **"New repository secret"**.

Luego, agrega los siguientes secretos:

- **`GCP_PROJECT_ID`**: El ID de tu proyecto en Google Cloud.  
  Ejemplo: `wom-p1`.

- **`GCP_CREDENTIALS_JSON`**: El contenido del archivo JSON de la cuenta de servicio de Google Cloud.  
  Para obtener este archivo:
  a. Ve a la **Console de Google Cloud**.
  b. Accede a **IAM & Admin** > **Service Accounts**.
  c. Crea una nueva cuenta de servicio o usa una existente.
  d. Asígnale los roles necesarios: Cloud Functions Admin, Storage Admin, Service Account User
  e. Descarga la clave de la cuenta de servicio en formato JSON.
  f. Copia el contenido del archivo JSON y pégalo en el campo **Value** de GitHub Secrets.

   **Nota:** Hay que mantener este archivo seguro, ya que contiene las credenciales de acceso a tu proyecto de Google Cloud.

5. Haz clic en **"Add secret"** para cada secreto.

Una vez configurados estos secretos, GitHub Actions podrá autenticarse y ejecutar el pipeline de Terraform.

## Limpieza

terraform destroy -auto-approve

## TEST

1. Define una arquitectura orientada a eventos, en donde al recibir un archivo en un
bucket este se procese.
2. Desarrolle un pipeline de GitLab CI/CD o en GitHub que despliegue una Cloud
Function a través de terraform.
3. Construya un DAG de airflow que utilice operadores nativos para tomar un archivo
desde un bucket e inserte en BigQuery, posteriormente ejecutar una query que
transforme la información y guarde el resultado en una nueva tabla.

Las 3 primeras preguntas se resuelven con la solucion implementada.

4. Se necesita utilizar una API para que nuestro call center llame a nuestros clientes.
Esta API puede recibir un máximo de 10 request/segundo, además cada 1 hora se
generan en promedio 600 registros.
a. Indicar que preguntas realizarías como especialista técnico a las áreas de
negocio

¿Cuál es el volumen total de registros que se procesarán diariamente?
Esto es importante para estimar la carga sobre el sistema y la cantidad de solicitudes API necesarias.

¿Cuántos clientes se deben contactar por hora/día?
Es esencial para comprender los requisitos de escalabilidad y optimización del uso de la API.

¿Hay algún tipo de prioridad o segmentación de clientes que deba tenerse en cuenta al realizar las llamadas?
Esto podría influir en la forma en que se gestionan las solicitudes a la API (por ejemplo, en lotes de alta prioridad).

¿Cuál es el nivel de criticidad de las llamadas realizadas?
Algunas llamadas pueden ser más críticas que otras, por lo que puede haber diferentes niveles de importancia en la ejecución.

¿Existe una ventana de tiempo para realizar todas las llamadas o pueden realizarse de forma continua?
Entender si las llamadas pueden distribuirse de forma flexible o si deben realizarse dentro de un período específico de tiempo.

¿Qué tipo de información se debe enviar en la solicitud y qué datos se necesitan en la respuesta de la API?
Ayuda a entender mejor el payload de las solicitudes y la estructura de las respuestas.

¿Qué pasa si se alcanza el límite de 10 solicitudes por segundo?
¿Hay alguna estrategia de reintento o espera entre solicitudes, o debemos gestionar el error de alguna manera específica?

¿Existen tiempos de inactividad o mantenimiento programados para la API del proveedor?
Esto puede ayudar a planificar posibles períodos de inactividad y evitar interrupciones en el servicio.
¿Hay alguna ventana de tiempo o período específico en el que las llamadas a los clientes deben realizarse, o pueden distribuirse durante todo el día?

Esto es importante para planificar cómo distribuir las solicitudes a la API sin sobrecargarla, y si existe alguna preferencia sobre los horarios o urgencia de las llamadas.

b. Indicar que preguntas realizarías como especialista técnico al proveedor de la
API
¿Cuál es el comportamiento de la API si se excede el límite de 10 solicitudes por segundo?
¿Se devuelve un error, se coloca la solicitud en una cola o se aplican políticas de retraso?

¿Existe algún mecanismo para gestionar los límites de tasa, como el uso de tokens o backoff exponencial?
Esto ayuda a entender cómo manejar adecuadamente las solicitudes sin violar los límites.

¿Cuáles son los tiempos de respuesta promedio de la API para una solicitud normal?
Para dimensionar correctamente la infraestructura y los tiempos de espera.

¿Existen límites en cuanto al número de registros que se pueden procesar en un período de tiempo específico (por ejemplo, por minuto, hora, día)?
Para evitar alcanzar el límite de capacidad de la API y mejorar el diseño de la solución.

¿Qué formato tienen las respuestas de la API y cómo debemos procesarlas?
Es importante comprender cómo interpretar las respuestas y manejar los errores.

¿La API permite la paginación en caso de que se obtengan grandes volúmenes de datos?
Esto es útil si el call center requiere obtener una lista extensa de clientes y realizar múltiples solicitudes.

¿Existen limitaciones de latencia en las respuestas de la API que debamos tener en cuenta?
Para asegurar que la arquitectura de la solución funcione correctamente dentro de las expectativas de tiempo.

¿Hay algún mecanismo para hacer llamadas en lote (batch calls) o alguna forma de optimizar múltiples solicitudes a la vez?
Esto permitiría realizar menos llamadas si la API lo permite y mejorar la eficiencia.

¿Cómo se manejan los registros duplicados o problemas de sincronización en los registros de llamadas?
Para asegurarse de que no se realicen llamadas innecesarias o duplicadas.

c. Diseñe y diagrame una arquitectura
API Gateway (Ej. Google API Gateway, AWS API Gateway):

Función: Limitar las solicitudes a la API para cumplir con el límite de 10 requests por segundo, manejar la autenticación y enrutamiento de las solicitudes.
Razón: Proteger la API backend de ser sobrecargada y aplicar políticas de acceso.

Cola de Mensajes (Ej. Google Pub/Sub, AWS SQS):

Función: Almacenar los registros que necesitan ser procesados y gestionar el flujo de trabajo sin exceder el límite de la API.
Razón: Esto ayuda a desacoplar la recepción de datos de la ejecución de la API, permitiendo un procesamiento escalable y controlado.

Servicio de Consumo (Ej. Google Cloud Functions, AWS Lambda):

Función: Procesar las solicitudes a la API en lotes o de manera controlada, asegurando que no se superen los límites de solicitud de la API (10 requests/segundo).
Razón: Las funciones en la nube permiten el escalado automático y permiten ejecutar lógica sin preocuparse por la infraestructura subyacente.

Base de Datos:

Función: Almacenar los registros generados por el sistema, incluyendo detalles de las llamadas realizadas y los estados de éxito o error.
Razón: Para hacer un seguimiento y auditoría, y proporcionar información a los equipos de negocio sobre el desempeño de las llamadas.

Sistema de Monitoreo (Ej. Stackdriver, CloudWatch, Prometheus):

Función: Monitorear el flujo de mensajes, la cantidad de solicitudes realizadas, tiempos de respuesta de la API y el estado de la cola.
Razón: Para detectar fallas o cuellos de botella y asegurar que todo esté funcionando dentro de los parámetros esperados.

+-------------------+     +--------------------+     +-------------------+
|   Generación de   |     |    Cola de Mensajes|     |    Monitoreo      |
|    Registros      |---->|    (Pub/Sub/SQS)   |<----|  (CloudWatch,     |
|    (Backend)      |     |                    |     |   Stackdriver)    |
+-------------------+     +--------------------+     +-------------------+
                                |
                                v
                     +--------------------------+
                     |   Función de Consumo      | 
                     |   (Cloud Function/Lambda) |
                     +--------------------------+
                                |
                                v
                     +--------------------------+
                     |  API de Call Center      |
                     |  (Con límite de 10 req/s)|
                     +--------------------------+
                                |
                                v
                     +--------------------------+
                     |    Base de Datos         |
                     |  (Almacenamiento de      |
                     |   registros y estado)    |
                     +--------------------------+


d. Justifique adecuadamente su arquitectura

1. Escalabilidad:
Uso de Cola de Mensajes (Pub/Sub/SQS):

Justificación: La cola de mensajes desacopla la generación de registros del procesamiento de la API. Esto permite que los registros se almacenen temporalmente hasta que haya capacidad para procesarlos, evitando sobrecargar la API.

Beneficio: Al utilizar una cola, el sistema puede manejar picos de carga y acumular mensajes durante periodos de alta demanda sin afectar el rendimiento de la API.

Funciones en la Nube (Cloud Functions / AWS Lambda):

Justificación: Las funciones en la nube son escalables y se ejecutan bajo demanda. Pueden manejar una cantidad de registros variable sin la necesidad de gestionar servidores físicos. Esta arquitectura de "serverless" se adapta automáticamente al volumen de registros que se generen, garantizando que no haya sobrecarga en los procesos de llamada a la API.

Beneficio: Las funciones son rentables ya que solo se pagan por la ejecución real, y se pueden escalar automáticamente si el volumen de registros aumenta.

2. Control de la Carga y Limitación de la API:
Regulación de las Solicitudes a la API:

Justificación: La API tiene un límite de 10 solicitudes por segundo. Al usar una cola de mensajes, el procesamiento de los registros se puede controlar de manera que las funciones en la nube consuman los registros a una velocidad que no exceda este límite. Se puede configurar la cola y la función para que el procesamiento ocurra en intervalos definidos, respetando el límite de la API.

Beneficio: Esto previene que la API sea saturada y evita que se generen errores o problemas de rendimiento por exceder el límite de solicitudes.

Retries y Manejo de Errores:

Justificación: En caso de que alguna solicitud a la API falle (por ejemplo, si hay un problema temporal de red o si la API está sobrecargada), el sistema puede reintentar el procesamiento automáticamente. La cola de mensajes permite almacenar los registros fallidos y reintentarlos más tarde, garantizando la entrega eventual.

Beneficio: Esto asegura que no se pierdan registros, y que la carga en la API sea manejada de manera eficiente sin intervención manual constante.

3. Persistencia y Auditoría:
Base de Datos:

Justificación: La base de datos almacena el estado de cada registro procesado, permitiendo realizar un seguimiento completo del proceso de cada llamada (por ejemplo, si la llamada fue exitosa o fallida). Esto es crucial tanto para auditoría como para generar informes de desempeño.

Beneficio: Mantener un registro persistente de las solicitudes permite a los equipos de negocio y a los operadores del call center revisar el historial de llamadas, identificar patrones de fallos o cuellos de botella y tomar decisiones informadas para mejorar el sistema.

4. Monitoreo y Gestión Proactiva:
Sistema de Monitoreo (Stackdriver, CloudWatch, Prometheus):

Justificación: La arquitectura incluye un sistema de monitoreo que detecta problemas de forma proactiva. Se monitorean tanto los registros en la cola como los tiempos de respuesta de la API, las funciones en la nube y el estado general del flujo de trabajo. Las alertas pueden configurarse para notificar a los administradores cuando un componente no esté funcionando según lo esperado (por ejemplo, si la cola se llena o si hay fallas recurrentes en las funciones).

Beneficio: El monitoreo proactivo permite intervenir antes de que los problemas se conviertan en fallas críticas, asegurando una operación continua y sin interrupciones en el call center.

5. Flexibilidad y Adaptabilidad:
Desacoplamiento con la Cola de Mensajes:

Justificación: La cola de mensajes desacopla los componentes del sistema, lo que significa que la generación de registros y su procesamiento son independientes. Esto hace que el sistema sea más flexible y fácil de modificar, ya que se pueden ajustar las funciones de procesamiento o la lógica de la cola sin afectar la generación de los registros o el flujo general del sistema.

Beneficio: Esta flexibilidad facilita futuras modificaciones, como cambios en el tipo de registro, la lógica de procesamiento o incluso la integración con otras APIs o servicios, sin necesidad de grandes reestructuraciones del sistema.

Escalabilidad Automática de las Funciones:

Justificación: Las funciones en la nube (Cloud Functions o Lambda) escalan automáticamente según la demanda. Si el número de registros crece o la frecuencia de llamadas aumenta, las funciones se pueden ejecutar más rápidamente y en paralelo para procesar los datos sin intervención manual.

Beneficio: La arquitectura se adapta sin problemas al crecimiento del volumen de registros y solicitudes, evitando la necesidad de ajustar manualmente la infraestructura.

6. Resiliencia y Tolerancia a Fallos:
Reintentos Automáticos:

Justificación: En caso de fallos, los registros pueden ser reintentados sin perder datos, lo cual se maneja a través de la cola de mensajes y las configuraciones de reintento automáticas en las funciones en la nube.

Beneficio: Esto asegura que el sistema sea resiliente ante errores transitorios sin intervención manual, mejorando la confiabilidad y la disponibilidad del sistema.