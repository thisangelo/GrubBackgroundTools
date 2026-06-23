# GrubBackgroundTools - thisangelo

Herramientas personales para personalizar el fondo de pantalla de GRUB en Linux Mint 22.3.  
Útil si usas Dualboot y quieres cambiar la imagen que aparece al arrancar el sistema.

## Scripts incluidos

- **grub-processor.sh** — Convierte una imagen al formato compatible con GRUB
- **grub-selector.sh** — Interfaz interactiva para seleccionar el wallpaper

## Requisitos

- Linux Mint 22.3 (o derivados de Ubuntu/Debian)
- [ImageMagick](https://imagemagick.org/) instalado

```bash
sudo apt install imagemagick
```

## Instalación

```bash
git clone https://github.com/thisangelo/GrubBackgroundTools.git
cd GrubBackgroundTools
chmod +x *.sh
```

## Uso

### 1. Convertir las imagenes a wallpapers compatibles con `grub-processor.sh`

Este script convierte tus imagenes al formato y resolución que GRUB necesita.

```bash
./grub-processor.sh <imagen>
```

O si quieres que se procese toda la carpeta (sin el argumento):

```bash
./grub-processor.sh 
```

> **Importante:** El script está configurado por defecto para una resolución de `1366x768`.  
> Si tu pantalla tiene una resolución diferente, debes editarlo antes de usarlo.

**¿Cómo saber tu resolución de GRUB?**

Ejecuta esto en la terminal:

```bash
sudo cat /etc/default/grub
```

Busca la línea que dice `GRUB_GFXMODE`, debería verse algo así:

```
GRUB_GFXMODE="1366x768,auto"
```

Ese valor es tu resolución. Luego abre `grub-processor.sh`, ve a la línea 29 y cámbiala:

```bash
# Línea 29 — Editar con tu resolución
RESOLUCION="${3:-1366x768}"   # Reemplaza 1366x768 por la tuya
```

### 2. Seleccionar el wallpaper con `grub-selector.sh`

Una vez procesada la imagen, ejecuta este script para aplicarla:

```bash
./grub-selector.sh
```

Sigue las instrucciones en pantalla para elegir y aplicar el fondo.

## Notas

- Los cambios en GRUB requieren permisos de superusuario, es posible que los scripts te pidan tu contraseña.
- Si algo sale mal, puedes restaurar GRUB con `sudo update-grub`.
