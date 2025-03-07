#!/bin/bash
set -e

# Variables
IMAGE_NAME="appjs"
VERSION="1.0.0"
DATE_TAG=$(date "+%Y%m%d-%H%M")
CONTAINER_NAME="appjs-container"
PORT=8080
NODE_ENV=production

# Colores para los output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker no está instalado en este sistema.${NC}"
    echo -e "${YELLOW}Por favor, instala Docker antes de ejecutar este script.${NC}"
    exit 1
fi

echo "Iniciando construcción y despliegue de la aplicación Node.js"

# Construir la imagen con etiquetas apropiadas
echo "Construyendo imagen Docker..."
docker build \
  --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --build-arg VERSION="$VERSION" \
  -t "$IMAGE_NAME:$VERSION" \
  -t "$IMAGE_NAME:$VERSION-$DATE_TAG" \
  -t "$IMAGE_NAME:latest" \
  .

echo "Imagen etiquetada como:"
echo "  • $IMAGE_NAME:$VERSION"
echo "  • $IMAGE_NAME:$VERSION-$DATE_TAG ($(date '+%d %B %Y, %H:%M'))"
echo "  • $IMAGE_NAME:latest"

# Detener y eliminar el contenedor si ya existe
if docker ps -a | grep -q $CONTAINER_NAME; then
  echo "Eliminando contenedor anterior..."
  docker stop $CONTAINER_NAME >/dev/null 2>&1 || true
  docker rm $CONTAINER_NAME >/dev/null 2>&1 || true
fi

# Ejecutar el nuevo contenedor
echo "Ejecutando el contenedor..."
docker run -d \
  --name $CONTAINER_NAME \
  -p $PORT:$PORT \
  -e NODE_ENV=$NODE_ENV \
  -e PORT=$PORT \
  --restart unless-stopped \
  "$IMAGE_NAME:$VERSION-$DATE_TAG"

# Esperar a que la aplicación esté lista
echo "Esperando a que la aplicación esté lista..."
sleep 3

# Comprobar el estado de salud
echo "Verificando endpoint /health..."
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/health)

if [ "$HEALTH_CHECK" == "200" ]; then
  echo -e "${GREEN}La aplicación está en funcionamiento correctamente (status code: $HEALTH_CHECK)${NC}"
  echo "Acceso a la aplicación en: http://localhost:$PORT"
  echo "Información del contenedor:"
  docker ps --filter "name=$CONTAINER_NAME" --format "ID: {{.ID}}\nNombre: {{.Names}}\nEstado: {{.Status}}\nPuertos: {{.Ports}}\nImagen: {{.Image}}\nCreado: {{.CreatedAt}}"
else
  echo -e "${RED}Error: La aplicación no está respondiendo correctamente (status code: $HEALTH_CHECK)${NC}"
  echo "Mostrando logs del contenedor:"
  docker logs $CONTAINER_NAME
fi

echo "Proceso completo - $(date '+%d %B %Y, %H:%M')"