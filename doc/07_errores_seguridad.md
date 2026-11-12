# Manejo de errores, seguridad y centralización

## Manejo de errores

### Cómo se manejan

Hay tres lugares donde un error se frena, y cada uno lo hace a su manera.

Las restricciones de las tablas (CHECK, UNIQUE, FK e índices únicos filtrados) son la primera barrera. No hay que programar nada: si un dato no cumple, SQL Server rechaza la instrucción con un mensaje que nombra la restricción (por eso todas tienen nombre).

Los procedimientos siguen la estructura que vimos en clase. Validan todo antes de abrir la transacción y, si algo no cierra, cortan con `raiserror('mensaje', 16, 1)`. La severidad 16 es la de un error que el usuario puede corregir, y hace saltar al `catch`. Lo que modifica datos va dentro de `begin transaction` y `commit`, con `set xact_abort on`. En el `catch` se deshace la transacción si quedó abierta (`if xact_state() <> 0 rollback transaction`), se muestra el error con `print 'error: ' + error_message()` y el procedimiento devuelve 1. Si sale bien devuelve 0. Así, el que llama al procedimiento puede preguntar por el valor de retorno, que es lo que hace el cierre de Gran Premio con el retiro de cada pieza.

Los triggers no tienen `try`. Cuando una regla no se cumple hacen `rollback transaction`, `raiserror` con nuestro mensaje y `return`. El rollback deshace la instrucción que los disparó, así que nunca queda nada a medias. Si la instrucción venía de un procedimiento o de un bloque `try`, el `catch` recibe nuestro mensaje. Si alguien la corre suelta en SSMS, ve nuestro mensaje y abajo el error 3609 de SQL Server ("The transaction ended in the trigger. The batch has been aborted."), que solo avisa que el lote se cortó. En los dos casos los datos quedan como estaban.

Los mensajes propios van en castellano y en minúscula, dicen qué pasó y, si hacen cumplir una regla, terminan con su número: "el Gran Premio 7 ya tiene dos pilotos inscriptos (RN03)".

### Las seis situaciones

Son las que pide el enunciado. Todos los ejemplos están en [scripts/99_pruebas.sql](../scripts/99_pruebas.sql), y el mensaje es el que se ve al correrlo.

| Situación | Ejemplo | Quién lo frena | Mensaje |
|---|---|---|---|
| Datos inválidos | Un resultado 'Finalizo' sin posición | CHECK `CK_Resultado_posicion` | The INSERT statement conflicted with the CHECK constraint "CK_Resultado_posicion" |
| | Una compra con monto negativo | Validación de `usp_registrar_compra` | el monto de la compra tiene que ser mayor a 0 |
| | Una sesión fuera del fin de semana del Gran Premio | Trigger de Sesion | la fecha de la sesion esta fuera del fin de semana del Gran Premio (RN02) |
| Violaciones de restricciones | Dos pilotos en la misma posición de una sesión | Índice único filtrado `UX_Resultado_posicion` | Cannot insert duplicate key row in object 'dbo.Resultado' with unique index 'UX_Resultado_posicion' |
| | El mismo chasis para dos pilotos | UNIQUE `UQ_Inscripcion_gp_chasis` | Violation of UNIQUE KEY constraint 'UQ_Inscripcion_gp_chasis' |
| | Un número de serie repetido | UNIQUE `UQ_Componente_serie` | Violation of UNIQUE KEY constraint 'UQ_Componente_serie' |
| | Dos gastos de compra para la misma pieza | Índice único filtrado `UX_Gasto_componente` | Cannot insert duplicate key row in object 'dbo.Gasto' with unique index 'UX_Gasto_componente' |
| Registros inexistentes | Cerrar el Gran Premio 99 | Validación de `usp_cerrar_gp` | el Gran Premio 99 no existe |
| | Cargar un resultado en la sesión 999 | Validación de `usp_cargar_resultado` | la sesion 999 no existe |
| | Un gasto de un proveedor que no existe | Validación de `usp_registrar_gasto` | el proveedor 99 no existe |
| Parámetros incorrectos | Inscribir con un chasis de 2025 en un Gran Premio de 2026 | Validación de `usp_inscribir_piloto` | el chasis 1 no existe o no es de la temporada del Gran Premio (RN06) |
| | Cargar el resultado de una inscripción de otro Gran Premio | Validación de `usp_cargar_resultado` | la inscripcion 11 no es del Gran Premio de la sesion 33 (RN10) |
| Operaciones no permitidas | Inscribir un tercer piloto | Validación de `usp_inscribir_piloto` | el Gran Premio 7 ya tiene dos pilotos inscriptos (RN03) |
| | Cerrar dos veces el mismo Gran Premio | Validación de `usp_cerrar_gp` | el Gran Premio 6 ya estaba cerrado (RN15) |
| | Usar una pieza retirada | Trigger de UsoComponente | no se puede usar una pieza retirada o danada (RN16) |
| | Un contrato superpuesto con otro | Trigger de Contrato | el empleado ya tiene un contrato que se superpone con esas fechas (RN07) |
| | Escribir directo en Resultado sin pasar por el procedimiento | Permisos (DENY) | The INSERT permission was denied on the object 'Resultado' |
| Errores durante transacciones | Comprar una pieza cuyo gasto pasa el tope | El trigger de Gasto rechaza y el `catch` del procedimiento deshace todo | el gasto hace pasar el tope presupuestario del anio (RN19) |

El último caso es el que muestra para qué sirve la transacción. `usp_registrar_compra` inserta la pieza y después el gasto. El gasto pasa el tope, el trigger lo rechaza y la pieza, que ya estaba insertada, también se deshace: después de la prueba, la caja GBX-26-04 no existe. Lo mismo pasa con el cierre de Gran Premio: si el retiro de una pieza falla, no queda ningún km sumado ni el Gran Premio cerrado.

## Seguridad

Está en [scripts/07_seguridad.sql](../scripts/07_seguridad.sql).

### Usuarios y roles

Cada actor del alcance es un rol de la base. Hay un login por rol en el servidor y un usuario en la base para cada login. Los permisos se dan a los roles, nunca a los usuarios, así que para sumar a alguien alcanza con agregarlo al rol.

| Rol | Usuario y login | Quién es |
|---|---|---|
| `rol_director_deportivo` | `usr_director`, `login_director` | Arma el calendario, inscribe a los pilotos y carga los resultados |
| `rol_ingeniero_pista` | `usr_ingeniero`, `login_ingeniero` | Registra el uso de piezas y cierra los Grandes Premios |
| `rol_rrhh` | `usr_rrhh`, `login_rrhh` | Empleados, contratos y sueldos |
| `rol_finanzas` | `usr_finanzas`, `login_finanzas` | Compras, gastos y el tope |
| `rol_consulta` | `usr_consulta`, `login_consulta` | Solo mira información general |

Los datos fijos (países, circuitos, tipos de sesión, tabla de puntos, tipos de pieza, límites y topes) los carga el administrador de la base, así que ningún rol puede modificarlos.

Las contraseñas están escritas en el script porque es un trabajo práctico y hay que poder probarlo. En una base de verdad irían con autenticación de Windows o se pedirían al crear el login.

### Permisos de cada rol

| Rol | Puede | No puede |
|---|---|---|
| Director deportivo | Leer el calendario y los catálogos deportivos. Cargar Grandes Premios y sesiones. Ejecutar `usp_cargar_resultado` y `usp_inscribir_piloto`. Ver las vistas de puntos, nómina y piezas | Modificar `cerrado` en GranPremio. Escribir directo en Resultado o Inscripcion. Ver Contrato, AuditoriaContrato o Gasto |
| Ingeniero de pista | Leer Grandes Premios, inscripciones, chasis y piezas. Cargar usos de piezas. Ejecutar `usp_cerrar_gp` y `usp_retirar_componente`. Ver `vw_estado_piezas` y `fn_piezas_piloto` | Modificar o borrar usos. Escribir en Componente o Penalizacion. Modificar `cerrado`. Ver Contrato o Gasto |
| Recursos Humanos | Cargar y modificar empleados, pilotos y contratos. Leer la auditoría de sueldos | Borrar contratos. Escribir en AuditoriaContrato. Ver Gasto |
| Finanzas | Leer gastos, piezas, topes y alertas. Cargar y modificar proveedores. Ejecutar `usp_registrar_compra` y `usp_registrar_gasto`. Ver `vw_situacion_tope` | Escribir directo en Gasto, AlertaTope o Componente. Ver Contrato o AuditoriaContrato |
| Consulta | Leer el calendario, los circuitos y las sesiones. Ver `vw_puntos_equipo_por_gp` y `vw_nomina` | Ver Contrato, AuditoriaContrato, Gasto o `vw_situacion_tope` |

Lo que un rol no puede hacer está con DENY explícito, aunque no se le haya dado el permiso. DENY gana siempre sobre GRANT, así que si mañana alguien queda en dos roles o se le da un permiso de más, la restricción sigue valiendo.

### Los dos patrones

Para escribir datos hay dos caminos, y cada tabla usa uno.

Solo por procedimiento. En Resultado, Inscripcion, Gasto y Componente el rol tiene EXECUTE sobre el procedimiento y DENY de INSERT, UPDATE y DELETE sobre la tabla (RN22). Funciona porque el procedimiento y la tabla tienen el mismo dueño (`dbo`): cuando el procedimiento escribe en la tabla, SQL Server no vuelve a revisar los permisos de quien lo ejecuta. Eso se llama encadenamiento de propiedad, y es lo que deja escribir por el procedimiento y no por fuera. Lo usamos cuando la operación tiene validaciones que una restricción no puede hacer (RN03, RN04, RN06, RN10) o varios pasos que tienen que salir juntos (la pieza y su gasto).

Escritura directa controlada por trigger. En Sesion, Contrato y UsoComponente el rol tiene permiso de INSERT o UPDATE sobre la tabla, y el trigger controla las reglas. Lo usamos cuando la operación es una carga simple pero la regla tiene que valer igual por cualquier camino.

### Información sensible

- Sueldos. Están en Contrato y AuditoriaContrato, y solo Recursos Humanos puede leerlas (RN21). Los demás ven el plantel por `vw_nomina`, que no tiene sueldos. La vista puede leer Contrato aunque el rol tenga DENY por el mismo encadenamiento de propiedad.
- Montos. Los gastos y el tope los ve Finanzas. El rol de consulta tiene DENY sobre `vw_situacion_tope`.
- La auditoría de sueldos no la puede modificar nadie. La llena el trigger de Contrato y Recursos Humanos tiene DENY de INSERT, UPDATE y DELETE.
- Los km de las piezas y el cierre de Gran Premio. Nadie tiene UPDATE sobre Componente, y el director y el ingeniero tienen DENY de UPDATE sobre la columna `cerrado`. Solo `usp_cerrar_gp` los cambia, así que el dato desnormalizado no se puede tocar a mano.

### Cómo se probó

La sección 10 del script de pruebas se hace pasar por cada usuario con `execute as user = '...'` y vuelve con `revert`. Para cada rol prueba algo que tiene que poder hacer y algo que no:

| Usuario | Prueba | Resultado |
|---|---|---|
| `usr_director` | INSERT directo en Resultado | Rechazado: The INSERT permission was denied on the object 'Resultado' |
| | El mismo resultado con `usp_cargar_resultado` | Se carga |
| | Leer Contrato | Rechazado |
| | Leer `vw_nomina` | Ve el plantel sin sueldos |
| | Marcar un Gran Premio como cerrado | Rechazado: The UPDATE permission was denied on the column 'cerrado' |
| `usr_ingeniero` | Poner en 0 los km de una pieza | Rechazado |
| | Cargar un uso de pieza y cerrar Barcelona | Se cargan, y el cierre retira dos piezas |
| `usr_rrhh` | Cambiar un sueldo | Se cambia y la auditoría guarda `login_rrhh` como usuario |
| | Borrar la auditoría | Rechazado |
| `usr_finanzas` | INSERT directo en Gasto | Rechazado |
| | El mismo gasto con `usp_registrar_gasto` | Se carga |
| | Leer Contrato | Rechazado |
| `usr_consulta` | Leer `vw_puntos_equipo_por_gp` | La ve |
| | Leer `vw_situacion_tope` | Rechazado |

## Centralización en la capa de datos

Todas las reglas de negocio viven en la base. Esta tabla dice para cada una qué parte de la base la hace cumplir y en qué sección del script de pruebas se ve funcionando.

| Regla | Qué dice | Mecanismo | Prueba |
|---|---|---|---|
| RN01 | Sesiones sprint solo en Grandes Premios sprint | Trigger `tr_Sesion_validar` | Sección 6 |
| RN02 | La sesión cae dentro del fin de semana | Trigger `tr_Sesion_validar` | Sección 6 |
| RN03 | Como mucho dos pilotos por Gran Premio | `usp_inscribir_piloto` | Sección 4 |
| RN04 | Solo pilotos con contrato vigente | `usp_inscribir_piloto` con `fn_contrato_vigente` | Sección 4 |
| RN05 | Un chasis no se repite en un Gran Premio | UNIQUE `UQ_Inscripcion_gp_chasis` | Sección 4 |
| RN06 | El chasis es de la temporada del Gran Premio | `usp_inscribir_piloto` | Sección 4 |
| RN07 | Sin contratos superpuestos | Trigger `tr_Contrato` | Sección 9 |
| RN08 | Titular o reserva solo en contratos de pilotos | Trigger `tr_Contrato` | Sección 9 |
| RN09 | Todo cambio de sueldo queda registrado | Trigger `tr_Contrato` y defaults de AuditoriaContrato | Secciones 9 y 10 |
| RN10 | El resultado es de un piloto inscripto en ese Gran Premio | `usp_cargar_resultado` | Sección 5 |
| RN11 | Posición solo si terminó, y sin repetirse | CHECK `CK_Resultado_posicion` e índice `UX_Resultado_posicion` | Sección 5 |
| RN12 | Los puntos se calculan, no se guardan | Tabla Puntaje, `fn_puntos_piloto` y `vw_puntos_equipo_por_gp` | Secciones 1 y 2 |
| RN13 | Penalización por pasarse del límite de piezas | Trigger `tr_UsoComponente` | Sección 7 |
| RN14 | El cierre suma km y retira piezas gastadas | `usp_cerrar_gp` con el cursor | Secciones 3 y 10 |
| RN15 | Un Gran Premio se cierra una vez y cerrado no acepta usos | `usp_cerrar_gp` y trigger `tr_UsoComponente` | Secciones 3 y 7 |
| RN16 | Una pieza retirada o dañada no se usa más | Trigger `tr_UsoComponente` | Sección 7 |
| RN17 | Una pieza tiene como mucho un gasto de compra | Índice `UX_Gasto_componente` | Sección 8 |
| RN18 | Para el tope solo cuentan ciertas categorías | `fn_gasto_computable` | Sección 8 |
| RN19 | No se puede pasar el tope ni gastar en un año sin tope | Trigger `tr_Gasto_tope` | Sección 8 |
| RN20 | El gasto que cruza el umbral deja una alerta | Trigger `tr_Gasto_tope` | Sección 8 |
| RN21 | Los sueldos solo los ve Recursos Humanos | DENY sobre Contrato y `vw_nomina` | Sección 10 |
| RN22 | Resultado, Inscripcion, Gasto y Componente solo por procedimiento | DENY sobre las tablas y EXECUTE sobre los procedimientos | Sección 10 |

Además de las reglas, en la base también quedan:

- Las validaciones de cada dato, con tipos, NOT NULL, CHECK, UNIQUE y claves foráneas.
- Los valores que no tiene que cargar nadie a mano, con defaults: la fecha y el usuario de la auditoría, el estado inicial de una pieza, el umbral del 90 %.
- Los cálculos que se usan en más de un lugar, en funciones: puntos, contrato vigente, km restantes, gasto computable.
- Las operaciones de varios pasos, en procedimientos con transacción.
- El manejo de errores y la seguridad.

¿Por qué en la base y no en una aplicación? Porque así valen para cualquiera que use los datos, por el camino que sea: SSMS, una aplicación, un script de carga o un usuario con permisos. Si el control del tope estuviera en una aplicación, alguien que cargara un gasto desde SSMS se lo saltearía. En la base está escrito una sola vez, y los permisos cierran los caminos que no pasan por los controles. Una aplicación que se haga después no tiene que repetir ninguna regla, solo llamar a los procedimientos y mostrar los mensajes.
