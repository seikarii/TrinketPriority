# Trinket Priority

Addon compatible con Retail (API 12.1+) y proyectos similares.

## Arquitectura

Los módulos activos se cargan exclusivamente desde `TrinketPriority.toc`, en el orden indicado por el manifiesto.

- `Core.lua`: namespace, base de datos por personaje, migración y acceso a perfiles.
- `Inventory.lua`: acceso a bolsas, cooldowns y equipamiento.
- `Config.lua`: operaciones sobre la prioridad/pasivo del perfil activo.
- `Priority.lua`: lógica de selección, timers y solicitudes diferidas.
- `Overlay.lua`: overlay móvil de iconos, trinket equipado y siguiente candidato.
- `UI.lua`: construcción y actualización de la interfaz.
- `Profiles.lua`: tres pestañas de perfil y notificación del perfil activo.
- `Commands.lua`: registro y despacho de comandos slash.
- `Main.lua`: eventos del addon y arranque.

## Perfiles y almacenamiento

Cada personaje almacena su configuración bajo su propia clave `Nombre-Reino` dentro de `TrinketPriorityDB`. La lista de uso, el pasivo y la configuración del overlay pertenecen al perfil activo.

Hay tres perfiles disponibles: **Perfil 1**, **Perfil 2** y **Perfil 3**. El menú muestra pestañas para cambiarlos. El cambio actualiza la lista, el overlay y muestra una notificación con el perfil activo.

## Migración

Los datos existentes de las versiones anteriores (`use`, `passive` y `overlay`) se copian una sola vez al **Perfil 1** del personaje que carga primero la migración. Los campos antiguos se eliminan después de la copia. Los perfiles adicionales empiezan vacíos y el resto de personajes no comparte los datos migrados.

## Configuración

Ejecuta `/trinket ui` o `/trinket options` para abrir la lista.

- Usa las pestañas Perfil 1/2/3 para cambiar de lista.
- **Añadir hueco 13/14:** añade el trinket equipado al perfil activo.
- Los botones del listado permiten subir, bajar o eliminar cada trinket.
- **Fallback pasivo:** usa el botón 13 o 14 para establecer el pasivo del perfil activo.

Puedes usar también:

- `/trinket profile 1|2|3`
- `/trinket profile` para mostrar el perfil activo
- `/trinket adduse 13` o `/trinket adduse 14`
- `/trinket passive 13` o `/trinket passive 14`
- `/trinket up N`, `/trinket down N`
- `/trinket removeuse N`
- `/trinket removepassive`
- `/trinket clear`
- `/trinket list`
- `/trinket overlay`: bloquea o desbloquea el movimiento del overlay.

## Macro recomendada

```text
#showtooltip 13
/use 13
/trinket
```

El cambio se realiza únicamente fuera de combate. Si el trinket del hueco 13 pertenece a la lista de uso activa, se espera a confirmar que ha entrado en cooldown antes de cambiarlo. Si está fuera de la lista activa, se pasa directamente a la selección de prioridades sin comprobar su estado de uso o cooldown. Si todos los trinkets de uso están en cooldown, equipa el pasivo configurado del perfil activo.
