#!/bin/bash
#
# GRUB Wallpaper Processor v1.0
# Procesamiento de fondos de pantallas compatibles con el
# gestor de arranque de Grub version (2.12-1ubuntu7.3).
#
# Usado en mi PC, el cual usa el Dualboot. 

set -uo pipefail

# Color definitions / Definiciones de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color / Sin color
VERSION="1.1"

# Default configuration / Configuracion por defecto (IMPORTANTE EDITAR)

# Editar esta carpeta por la que se usara como origen 
CARPETA_DEFECTO="$HOME/Wallpapers0"
ORIGEN="${1:-$CARPETA_DEFECTO}"

# Editar esta carpeta por la que se usara como destino
DESTINO="${2:-/boot/grub/wallpapers}"

# Display header / Mostrar encabezado
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}      GRUB WALLPAPER PROCESSOR v${VERSION}      ${NC}"
echo -e "${RED}                  thisangeloo                   ${NC}"
echo -e "${BLUE}================================================${NC}"

echo "Se requiere permisos para escribir/sobreescribir en ${DESTINO} "
sudo -v || exit 1

echo -e "${BLUE} Identificando la resolucion de su pantalla ${NC}"
sleep 5
## Buscar la resolucion exacta de la pantalla
inicializar_resolucion() {
    # Default resolution
    RESOLUCION="1366x768"

    # Init all commands detection display resolution
    local detected=$(xrandr --current 2>/dev/null | grep '*' | head -1 | awk '{print $1}')
    [[ -z "$detected" ]] && detected=$(xdpyinfo 2>/dev/null | grep dimensions | awk '{print $2}')
    [[ -z "$detected" ]] && detected=$(wlr-randr 2>/dev/null | grep -A1 "current" | grep -v "current" | head -1 | awk '{print $1}')

    # Si hay detección, actualizar
    [[ -n "$detected" ]] && RESOLUCION="$detected"

    # Validate resolution format
    if ! [[ "$RESOLUCION" =~ ^[0-9]+x[0-9]+$ ]]; then
        echo -e "${RED}ERROR: Invalid resolution format / Formato de resolucion invalido: $RESOLUCION${NC}"
        exit 1
    fi

    # Calcular ancho y alto
    ANCHO=${RESOLUCION%x*}
    ALTO=${RESOLUCION#*x}
}

# Ejecutar detección
inicializar_resolucion
echo ""
echo "DISPLAY RESOLUTION DETECTED"
echo "Resolución: $RESOLUCION"
echo "Ancho: $ANCHO px"
echo "Alto:  $ALTO px"
echo ""

# Check dependencies / Verificar dependencias
for dep in convert identify; do
    if ! command -v "$dep" &>/dev/null; then
        echo -e "${RED}ERROR: ImageMagick not found / ImageMagick no encontrado${NC}"
        echo -e "${YELLOW}Installation / Instalacion: sudo apt install imagemagick${NC}"
        exit 1
    fi
done

## Crear el directorio de origen si fuera necesario
if [ ! -d "$ORIGEN" ]; then
    mkdir -p "$ORIGEN"
fi

# Validate source directory / Validar directorio origen
if [ ! -d "$ORIGEN" ]; then
    echo -e "${RED}ERROR: Source directory does not exist / Directorio origen no existe${NC}"
    exit 1
fi
ORIGEN="$(cd "$ORIGEN" && pwd)"

# Create destination directory if needed / Crear directorio destino si es necesario
if [ ! -d "$DESTINO" ]; then
    sudo mkdir -p "$DESTINO"
fi

# Validate source directory / Validar directorio origen
if [ ! -d "$DESTINO" ]; then
    echo -e "${RED}ERROR: Destination directory does not exist / Directorio destino no existe${NC}"
    exit 1
fi
DESTINO="$(cd "$DESTINO" && pwd)"


# Check if sudo is needed for destination / Verificar si se necesita sudo para destino
USAR_SUDO=0
if [ ! -w "$DESTINO" ]; then
    USAR_SUDO=1
fi
DESTINO="$(cd "$DESTINO" && pwd)"

# Display configuration / Mostrar configuracion
echo -e "\n${BLUE}Source / Origen:${NC}     $ORIGEN"
echo -e "${BLUE}Destination / Destino:${NC}    $DESTINO"
echo -e "${BLUE}Resolution / Resolucion:${NC} $RESOLUCION\n"

# Change to source directory / Cambiar al directorio origen
cd "$ORIGEN" || exit 1
shopt -s nullglob

## Pausa
read -p "Presiona Enter para continuar..."

# Initialize counters / Inicializar contadores
PROCESADAS=0
EXISTENTES=0
ERRORES=0

# Get image information / Obtener informacion de la imagen
obtener_info_imagen() {
    identify -format "%m|%[type]|%[colorspace]|%wx%h" "$1" 2>/dev/null
}

# Check if image is GRUB compatible / Verificar si la imagen es compatible con GRUB
es_compatible_grub() {
    local fmt tipo cs geo
    IFS='|' read -r fmt tipo cs geo <<< "$1"
    [[ "$fmt" == "PNG" ]] && [[ "$tipo" == TrueColor* ]] && [[ "$cs" == "sRGB" ]] && [[ "$geo" == "$RESOLUCION" ]]
}

# Convert image to GRUB compatible format / Convertir imagen a formato compatible con GRUB
convertir_imagen() {
    local src="$1" dst="$2"
    local CMD=(convert "$src" -resize "${ANCHO}x${ALTO}>" \
        -background black -gravity center -extent "${RESOLUCION}" \
        -alpha remove -colorspace sRGB -type TrueColor \
        -define png:color-type=2 -define png:compression-level=6 "$dst")

    if [ "$USAR_SUDO" -eq 1 ]; then
        sudo "${CMD[@]}"
    else
        "${CMD[@]}"
    fi
}

# Install file to destination with proper permissions / Instalar archivo en destino con permisos adecuados
instalar_en_destino() {
    local src="$1" dst="$2" modo="$3"
    if [ "$USAR_SUDO" -eq 1 ]; then
        sudo "$modo" "$src" "$dst"
    else
        "$modo" "$src" "$dst"
    fi
}

# Process images / Procesar imagenes
for img in *; do
    # Skip if not a regular file / Saltar si no es un archivo regular
    [ -f "$img" ] || continue

    # Get image info / Obtener informacion de la imagen
    INFO=$(obtener_info_imagen "$img") || continue
    [ -z "$INFO" ] && continue

    # Build destination filename / Construir nombre de archivo destino
    nombre_base="${img%.*}"
    [ -z "$nombre_base" ] && nombre_base="$img"
    destino_img="$DESTINO/${nombre_base}_grub.png"

    # Skip if already exists / Saltar si ya existe
    if [ -f "$destino_img" ]; then
        echo -e "${YELLOW}SKIP / OMITIR: Already exists / Ya existe:${NC} $img"
        EXISTENTES=$((EXISTENTES + 1))
        continue
    fi

    # Copy directly if compatible / Copiar directamente si es compatible
    if es_compatible_grub "$INFO"; then
        echo -e "${BLUE}COPY / COPIAR: Already compatible / Ya compatible:${NC} $img"
        if instalar_en_destino "$img" "$destino_img" "cp"; then
            echo -e "${GREEN}SUCCESS / EXITO: Copied / Copiada:${NC} $img"
            PROCESADAS=$((PROCESADAS + 1))
        else
            ERRORES=$((ERRORES + 1))
        fi
        continue
    fi

    # Process image / Procesar imagen
    echo -e "${BLUE}PROCESS / PROCESAR: $img${NC}"
    TEMP_FILE="${img%.*}_temp_grub.png"

    # Convert and install / Convertir e instalar
    if convertir_imagen "$img" "$TEMP_FILE"; then
        if instalar_en_destino "$TEMP_FILE" "$destino_img" "mv"; then
            echo -e "${GREEN}SUCCESS / EXITO: Processed / Procesada:${NC} $img"
            PROCESADAS=$((PROCESADAS + 1))
        else
            echo -e "${RED}ERROR: Failed to move / Error al mover:${NC} $img"
            rm -f "$TEMP_FILE"
            ERRORES=$((ERRORES + 1))
        fi
    else
        echo -e "${RED}ERROR: Processing failed / Error en procesamiento:${NC} $img"
        rm -f "$TEMP_FILE"
        ERRORES=$((ERRORES + 1))
    fi
    rm -f "$TEMP_FILE" 2>/dev/null
done

# Display summary / Mostrar resumen
echo -e "\n${BLUE}SUMMARY / RESUMEN:${NC}"
echo -e "Processed / Procesadas:     ${GREEN}$PROCESADAS${NC}"
echo -e "Already exists / Ya existentes: ${YELLOW}$EXISTENTES${NC}"
[ "$ERRORES" -gt 0 ] && echo -e "Errors / Errores:        ${RED}$ERRORES${NC}"

echo -e "\n${GREEN}DONE / COMPLETADO.${NC}"
