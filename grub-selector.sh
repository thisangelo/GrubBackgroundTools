#!/bin/bash
#
# GRUB Wallpaper Selector v1.0
#
# Description / Descripcion:
#   Interactive script to select and apply GRUB wallpapers
#   Script interactivo para seleccionar y aplicar wallpapers en GRUB


# Color definitions / Definiciones de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color / Sin color
VERSION="1.0"


# Configuration Default / Configuracion por defecto

# Editar esta ruta por el destino antes elegido
WALLPAPER_DIR="/boot/grub/wallpapers"          # Wallpaper directory / Directorio de wallpapers

# No editar esta ruta si esta por defecto (NO TOCAR SI NO ES NECESARIO)
CONFIG_FILE="/etc/default/grub"                # GRUB configuration file / Archivo de configuracion de GRUB

# Verify wallpaper directory exists / Verificar que existe el directorio de wallpapers
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "ERROR: Directory not found / Directorio no encontrado: $WALLPAPER_DIR"
    exit 1
fi

# Get list of PNG images / Obtener lista de imagenes PNG
# mapfile -t images < <(ls "$WALLPAPER_DIR"/*.png 2>/dev/null | xargs -n1 basename)

# This version reads better name of  wallpapers that have one or more spaces empty or special characters inside name
images=()
while IFS= read -r -d '' file; do
    images+=("$(basename "$file")")
done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f -iname "*.png" -print0 2>/dev/null)

# Check if there are images / Verificar si hay imagenes
if [ ${#images[@]} -eq 0 ]; then
    echo "ERROR: No PNG images found in / No se encontraron imagenes PNG en: $WALLPAPER_DIR"
    exit 1
fi

# Display menu / Mostrar menu
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}       GRUB WALLPAPER SELECTOR v${VERSION}      ${NC}"
echo -e "${RED}                  thisangeloo                    ${NC}"   
echo -e "${BLUE}================================================${NC}"
echo ""

# List available wallpapers / Listar wallpapers disponibles
for i in "${!images[@]}"; do
    echo "  [$((i+1))] ${images[$i]}"
done

echo ""
echo "  [0] Exit / Salir"
echo "========================================="
echo ""

# Request user selection / Solicitar seleccion del usuario
read -p "Choose a wallpaper (number) / Elige un wallpaper (numero): " choice

# Exit option / Opcion de salida
if [ "$choice" -eq 0 ] 2>/dev/null; then
    echo "Exiting / Saliendo..."
    exit 0
fi

# Validate selection / Validar seleccion
if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#images[@]} ]; then
    selected="${images[$((choice-1))]}"
    fullpath="$WALLPAPER_DIR/$selected"
    
    echo ""
    echo "Selected / Seleccionado: $selected"
    
    # Update GRUB configuration / Actualizar configuracion de GRUB
    # Try to replace existing line / Intentar reemplazar linea existente
    sudo sed -i "s|^GRUB_BACKGROUND=.*|GRUB_BACKGROUND=\"$fullpath\"|" "$CONFIG_FILE" 2>/dev/null || true
    
    # If no line exists, add it / Si no existe la linea, agregarla
    if ! grep -q "^GRUB_BACKGROUND=" "$CONFIG_FILE"; then
        echo "GRUB_BACKGROUND=\"$fullpath\"" | sudo tee -a "$CONFIG_FILE" > /dev/null
    fi

    # Regenerate GRUB / Regenerar GRUB
    echo "Regenerating GRUB configuration / Regenerando configuracion de GRUB..."
    sudo update-grub
    
    echo ""
    echo "SUCCESS / EXITO: Wallpaper changed successfully"
    echo "Wallpaper cambiado correctamente"
    echo ""
    echo "Reboot to apply changes / Reinicia para aplicar los cambios:"
    echo "  sudo reboot"
else
    echo "ERROR: Invalid option / Opcion invalida"
    exit 1
fi