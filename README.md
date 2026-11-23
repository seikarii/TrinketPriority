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

- El botón **Automático: ON/OFF** activa el cambio automático al salir de combate o al revivir.
- También puedes activarlo o desactivarlo con `/trinket on` y `/trinket off` (o `/trinket ui on|off`). La preferencia se guarda por personaje.

- Usa las pestañas Perfil 1/2/3 para cambiar de lista.
- **Añadir hueco 13/14:** añade el trinket equipado al perfil activo.
- Los botones del listado permiten subir, bajar o eliminar cada trinket.
- **Fallback pasivo:** usa el botón 13 o 14 para establecer el pasivo del perfil activo.

Puedes usar también:

- `/trinket profile 1|2|3`
- `/trinket on` o `/trinket off`
- `/trinket profile` para mostrar el perfil activo
- `/trinket adduse 13` o `/trinket adduse 14`
- `/trinket passive 13` o `/trinket passive 14`
- `/trinket up N`, `/trinket down N`
- `/trinket removeuse N`
- `/trinket removepassive`
- `/trinket clear`
- `/trinket list`
- `/trinket overlay`: bloquea o desbloquea el movimiento del overlay.

## Icono minimapa

El addon añade un icono persistente junto al minimapa:

- **Clic izquierdo:** abre/cierra `/trinket ui`.
- **Mayús-clic izquierdo:** permite arrastrar el icono alrededor de todo el borde del minimapa.
- La posición se guarda por personaje y se restaura al iniciar sesión.

También puedes restablecerla con `/trinket minimap reset`.

## Macro recomendada

```text
#showtooltip 13
/use 13
/trinket
```

## Tests locales

Los harness Lua están separados del addon y no se cargan desde el `.toc`. Desde la raíz del addon, ejecuta `lua tests/ProfileTests.lua`, `lua tests/MinimapTests.lua`, `lua tests/ConfigTests.lua`, `lua tests/InventoryTests.lua`, `lua tests/PriorityTests.lua`, `lua tests/OverlayTests.lua` y `lua tests/MainEventTests.lua`.

El cambio se realiza únicamente fuera de combate. Si el trinket del hueco 13 pertenece a la lista de uso activa, se espera a confirmar que ha entrado en cooldown antes de cambiarlo. Si está fuera de la lista activa, se pasa directamente a la selección de prioridades sin comprobar su estado de uso o cooldown. Si todos los trinkets de uso están en cooldown, equipa el pasivo configurado del perfil activo.
