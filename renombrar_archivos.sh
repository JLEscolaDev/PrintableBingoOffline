#!/bin/bash

# Ruta absoluta a la carpeta donde están los archivos
DIRECTORIO="/Users/jle/projects/Projects/PrintableBingoOffline/PrintableBingoOffline/Resources/Voice/DirtyComments"

# Verificar si la carpeta existe
if [ ! -d "$DIRECTORIO" ]; then
    echo "El directorio $DIRECTORIO no existe. Verifica la ruta."
    exit 1
fi

# Recorrer todos los archivos .mp3 en la carpeta
for archivo in "$DIRECTORIO"/*.mp3; do
    # Verificar si existen archivos
    if [ ! -e "$archivo" ]; then
        echo "No se encontraron archivos .mp3 en el directorio $DIRECTORIO."
        exit 1
    fi

    # Obtener el nombre base del archivo sin la ruta ni la extensión
    nombre_base=$(basename "$archivo" .mp3)
    
    # Definir el nuevo nombre del archivo
    nuevo_nombre="${nombre_base}-Spanish.mp3"
    
    # Renombrar el archivo
    mv "$archivo" "$DIRECTORIO/$nuevo_nombre"
    echo "Renombrado: $archivo -> $nuevo_nombre"
done

echo "Todos los archivos han sido renombrados correctamente."
