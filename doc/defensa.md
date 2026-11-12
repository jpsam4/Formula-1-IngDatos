# Preparación de la defensa

No es parte del documento que se entrega. Es para nosotros.

En la defensa le pueden preguntar a cualquiera por cualquier parte, así que todos tenemos que entender todo. Lo que mejor funciona es el ensayo cruzado: cada uno le explica a otro un área que no es la suya, y donde se traba hay algo para repasar.

## Antes de la defensa

Cada uno, en su máquina:

1. Abrir `scripts/TP_completo.sql` en SSMS y apretar F5. Tiene que terminar sin errores.
2. Correr `scripts/08_consultas.sql` y comparar dos o tres resultados con el documento.
3. Correr `scripts/99_pruebas.sql` y buscar `MAL` en los mensajes. No tiene que aparecer nunca.
4. Volver a correr `TP_completo.sql`, así la base queda limpia para mostrar.

Si piden mostrar algo en vivo, se abre `99_pruebas.sql`, se seleccionan las líneas desde el principio hasta el final de la parte que pregunten y F5. Cada parte dice con un `print` qué tiene que pasar. Hay que arrancar siempre desde el principio y con la base recién armada, porque cada parte usa lo que dejaron las anteriores: el GP de Mónaco se cierra en la parte 3, y las inscripciones de Barcelona y las variables `@inscver` e `@inschad` se cargan en la 4.

## Lo que cada uno tiene que poder explicar de cada área

- Deportiva: por qué los puntos no se guardan, cómo funciona el CHECK de posición con el índice filtrado, el trigger de sesiones y la vista con la suma acumulada.
- Personal: Piloto como especialización de Empleado, cómo `fn_contrato_vigente` resuelve el contrato de una fecha, el trigger de contratos (superposición, titular o reserva, auditoría) y por qué el director puede ver `vw_nomina` aunque tenga DENY sobre Contrato.
- Técnica: la inscripción como centro, el trigger de uso de piezas (sobre todo las penalizaciones de 10 y 5), el cierre de Gran Premio con el cursor y por qué los km se guardan.
- Finanzas: el gasto computable, el trigger del tope (rechazo y alerta), la compra de una pieza como ejemplo de transacción y toda la seguridad.

## Preguntas probables

¿Por qué no guardan los puntos en Resultado?
Porque dependen de la posición, el tipo de sesión y la temporada, no del piloto. Guardarlos sería repetir un dato que se puede calcular con Puntaje, y si cambia el reglamento habría que corregir todos los resultados.

¿Por qué guardan los km si se pueden calcular?
Es una desnormalización a propósito. Se consultan todo el tiempo y el cierre de Gran Premio decide con ellos si retira una pieza. Para que no queden mal, solo los modifica `usp_cerrar_gp` y ningún rol tiene UPDATE sobre Componente. Al final del script de pruebas hay una consulta que compara los km guardados con la suma de los usos, y no devuelve filas.

¿En qué forma normal está la base?
En 3FN, salvo los km acumulados. GranPremio no está en FNBC porque `fecha_inicio` determina `anio` y no es superclave, pero sí está en 3FN porque `anio` es parte de la clave candidata (`anio`, `ronda`). Para que no se contradiga hay un CHECK: `year(fecha_inicio) = anio`.

¿Por qué Resultado no tiene `id_gp` para asegurar que la sesión y la inscripción son del mismo Gran Premio?
Porque `id_gp` ya se deduce de la sesión. Agregarlo sería una dependencia transitiva y rompería la 3FN. Lo valida `usp_cargar_resultado`, y los permisos hacen que sea la única forma de cargar un resultado.

¿Por qué Piloto es una tabla aparte?
Porque un piloto es un empleado con datos que los demás no tienen, como el número de auto. Es una especialización y comparte la clave con Empleado.

¿Por qué algunas reglas están en procedimientos y otras en triggers?
Si la regla tiene que valer siempre, venga de donde venga el cambio, va en un trigger. Si es parte de una operación con varios pasos o necesita validar antes de tocar nada, va en un procedimiento, y los permisos obligan a usarlo. Y si se puede escribir como restricción, es una restricción.

¿Por qué un cursor y no un UPDATE?
Porque para cada pieza que llega a su vida útil hay que ejecutar otro procedimiento, el de retiro, y mirar lo que devuelve. Un UPDATE no puede hacer un EXEC por cada fila.

¿Qué significan `local` y `fast_forward` en el cursor?
`local` hace que el cursor exista solo dentro del procedimiento. `fast_forward` es de solo lectura y solo para adelante, que es lo único que necesitamos y lo más liviano.

¿Qué pasa si se insertan varias filas a la vez y salta un trigger?
Los triggers trabajan con toda la tabla `inserted`. Si una sola fila rompe la regla, se rechaza el INSERT completo.

¿Cómo calcula el trigger las penalizaciones de 10 y 5 puestos?
Guarda en `@nuevas` las piezas que se usan por primera vez. Para cada una cuenta cuántas piezas de ese tipo tenía el piloto en la temporada y le suma su orden entre las nuevas (`row_number`). Si ese número es el límite más uno, son 10 puestos; si es más, 5.

¿Qué pasa si un procedimiento falla a la mitad?
La transacción se deshace entera. El ejemplo es la compra de una pieza: si el gasto pasa el tope, la pieza tampoco queda creada.

¿Para qué sirve `set xact_abort on`?
Hace que cualquier error deje la transacción marcada para deshacerse entera. Sin eso, algunos errores cortan solo la instrucción que falló y la transacción podría seguir con la mitad de los cambios.

¿Por qué `raiserror` y no `throw`?
Es lo que vimos en clase, y con `raiserror`, `try/catch` y `print error_message()` alcanza. Los dos hacen saltar al `catch`. La diferencia es que `throw` sin parámetros relanza el error original con su número, y que `raiserror` deja armar el mensaje con `%d`.

¿Por qué cuando un trigger rechaza algo aparece también el error 3609?
Porque el trigger hizo rollback de la transacción. SQL Server avisa con el 3609 que la transacción terminó dentro del trigger y corta el lote. Nuestro mensaje es el que sale antes. Si la instrucción estaba dentro de un `try`, el `catch` recibe nuestro mensaje y el 3609 no se ve.

¿Se puede pasar el tope cargando el gasto directo en la tabla?
No. El control está en un trigger, así que vale por cualquier camino. Además Finanzas no tiene permiso para escribir en Gasto, solo para ejecutar los procedimientos.

¿Cómo puede el director cargar un resultado si tiene DENY de INSERT sobre Resultado?
Por el encadenamiento de propiedad. El procedimiento y la tabla son del mismo dueño (`dbo`), así que cuando el procedimiento inserta, SQL Server no vuelve a revisar los permisos del que lo ejecuta. Lo que se controla es el permiso de EXECUTE.

¿Para qué ponen DENY si nunca le dieron el permiso?
Porque DENY gana sobre cualquier GRANT. Si mañana alguien queda en dos roles o se le da un permiso de más, la restricción sigue valiendo.

¿Por qué un índice único filtrado y no un UNIQUE común?
Un UNIQUE en SQL Server acepta un solo NULL. En Gasto hay muchos gastos sin pieza (`id_componente` en NULL) y en Resultado muchos pilotos sin posición. El índice filtrado (`where ... is not null`) controla que no se repitan los valores y deja pasar todos los NULL.

¿Por qué el CHECK de posición dice `posicion is not null`?
Porque un CHECK solo falla si la condición da falso, y con NULL da desconocido. Sin esa parte, un resultado 'Finalizo' sin posición pasaba.

¿Por qué `scope_identity()` y no `@@identity`?
`@@identity` devuelve el último id generado en la conexión, aunque lo haya generado un trigger. Como el trigger de Gasto puede insertar una alerta, `@@identity` podría devolver el id de la alerta. `scope_identity()` devuelve el del procedimiento.

¿Por qué hay `GO` solo en algunos lugares?
Porque solo donde SQL Server lo obliga. Después del `create database`, porque si no el `use` falla (la base todavía no existe cuando se compila el lote). Y antes de cada función, vista, procedimiento y trigger, porque el `create` tiene que ser lo primero de su lote.

¿Qué pasa si se corre el script dos veces?
Nada. El 01 borra la base si existe y la crea de nuevo, y los logins se crean solo si no existen.

¿Para qué hay datos de 2025?
Para probar lo que cambia de una temporada a otra: Tsunoda pasó de titular a reserva, Ferraro tuvo contrato solo en 2025, hay chasis de 2025 que no se pueden inscribir en 2026 y una alerta del tope que ya saltó.
