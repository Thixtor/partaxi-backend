#!/bin/bash
# =========================================================================
# SCRIPT DE DESPLIEGUE CONTINUO (CD) - PROYECTO PARTAXÍ
# Empresa: "RÁPIDO Y SEGURO"
# Autor: Sebastian Acosta Sanchez
# =========================================================================

# Mensaje inicial para registrar el inicio de la automatización en la consola
echo "Iniciando proceso de Entrega Continua en Entorno de Staging..."

# -------------------------------------------------------------------------
# STEP 1: DEFINICIÓN DE VARIABLES DE CONTROL Y VERSIONAMIENTO
# -------------------------------------------------------------------------
# Centralizar los parámetros permite modificar el entorno de forma rápida sin alterar la lógica del script.
IMAGE_NAME="partaxi-backend"          # Nombre de la imagen Docker empaquetada en la fase de CI
TAG="latest"                          # Etiqueta de la versión que se va a desplegar
CONTAINER_NAME="contenedor_partaxi_staging" # Nombre único que recibirá el contenedor en el servidor local
PORT="8000"                           # Puerto local y del contenedor asignado para la API del backend
NETWORK="partaxi_network"             # Red virtual de Docker para permitir la comunicación segura entre servicios

# -------------------------------------------------------------------------
# STEP 2: CONTROL DE FAILOVER (DETENCIÓN Y LIMPIEZA AUTOMATIZADA)
# -------------------------------------------------------------------------
# Esta condicional evita errores de colisión de nombres o puertos ocupados en Docker.
# Explicación del comando interno:
#   docker ps: Lista contenedores.
#   -a: Incluye contenedores activos e inactivos.
#   -q: Retorna únicamente el ID del contenedor (modo silencioso).
#   -f name=...: Filtra los resultados buscando exactamente el nombre de nuestro contenedor de staging.

if [ $(docker ps -a -q -f name=$CONTAINER_NAME) ]; then
    echo "🔄 Detectado contenedor previo operativo. Procediendo a detención controlada..."
    
    # Detiene el contenedor antiguo enviando una señal SIGTERM para cerrar conexiones de forma segura
    docker stop $CONTAINER_NAME
    
    # Remueve el contenedor antiguo liberando el nombre y el puerto 8000 del host local
    docker rm $CONTAINER_NAME
fi
# 'fi' cierra el bloque condicional del control de Failover

# -------------------------------------------------------------------------
# STEP 3: LANZAMIENTO AUTOMATIZADO DE LA NUEVA VERSIÓN EMPAQUETADA
# -------------------------------------------------------------------------
echo "Desplegando la nueva imagen empaquetada $IMAGE_NAME:$TAG..."

# Ejecución automatizada del contenedor con parámetros estrictos de infraestructura:
#   -d: Modo "detached", ejecuta el contenedor en segundo plano para liberar la consola del pipeline.
#   --name: Asigna el identificador de texto predefinido al contenedor.
#   -p: Mapea el puerto 8000 del host local al puerto 8000 interno del contenedor.
#   --network: Conecta el backend a la red de aislamiento de la flota.
docker run -d \
  --name $CONTAINER_NAME \
  -p $PORT:$PORT \
  --network $NETWORK \
  $IMAGE_NAME:$TAG

# -------------------------------------------------------------------------
# STEP 4: VERIFICACIÓN DE SALUD AUTOMATIZADA (HEALTHCHECK / SMOKE TEST)
# -------------------------------------------------------------------------
# Práctica fundamental de Entrega Continua para asegurar que el servicio está respondiendo HTTP antes de notificar éxito.

echo "Esperando estabilización del servicio (5 segundos)..."
# Pausa prudencial para dar tiempo a que los servicios internos del backend (como Django/FastAPI) terminen de inicializarse
sleep 5

echo "Ejecutando verificación de salud automática de la API..."

# Explicación del comando curl para el Healthcheck:
#   -s: Modo silencioso, oculta la barra de progreso de la descarga.
#   -o /dev/null: Descarta el cuerpo de la respuesta JSON para no ensuciar la consola del script.
#   -w "%{http_code}": Instruye a curl para que únicamente nos devuelva el código de estado HTTP (ej. 200, 404, 500).
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/health/)

# Evaluación condicional del estado del despliegue:
# Si el código HTTP es exactamente 200 (OK), significa que el backend está respondiendo exitosamente.
if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Despliegue Continuo Exitoso. Backend de ParTaxí operativo y listo para asignar servicios."
else
    # Si devuelve cualquier otro código (ej. 500 por error de base de datos o 000 si el servidor no levantó)
    echo "Error en el despliegue. El servicio respondió con estado HTTP: $HTTP_STATUS"
    
    # Forzar la salida con código de error 1 para romper el pipeline e indicar que la Entrega Continua falló
    exit 1
fi
# 'fi' finaliza formalmente el bloque condicional del Healthcheck