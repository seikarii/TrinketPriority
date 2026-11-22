# Trinket Priority

Addon compatible con clientes Vanilla/Forever 1.12.

## Configuración

Ejecuta `/trinket ui` o `/trinket options` para abrir la lista.

- **Añadir hueco 13/14:** añade el trinket equipado a la lista de uso.
- Los botones del listado permiten subir, bajar o eliminar cada trinket.
- **Fallback pasivo:** usa el botón 13 o 14 para establecer el pasivo del hueco correspondiente.

Puedes usar también:

- `/trinket adduse 13` o `/trinket adduse 14`
- `/trinket passive 13` o `/trinket passive 14`
- `/trinket up N`, `/trinket down N`
- `/trinket removeuse N`
- `/trinket removepassive`
- `/trinket clear`
- `/trinket list`

## Macro recomendada

```text
#showtooltip 13
/use 13
/trinket
```

El cambio se realiza únicamente fuera de combate y después de confirmar que el trinket del hueco 13 se ha puesto en cooldown. Si todos los trinkets de uso están en cooldown, equipa el pasivo configurado.
