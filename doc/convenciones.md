# Convenciones

Las acordamos antes de escribir SQL para que el script final no parezca escrito por cuatro personas distintas. Si alguien necesita cambiar una lo charlamos y se actualiza acá.

## Motor

SQL Server 2019 o posterior.

La base se llama `EscuderiaF1`.

## Nombres

| Qué | Cómo | Ejemplo |
|---|---|---|
| Tablas | PascalCase, en singular | `GranPremio`, `UsoComponente` |
| Columnas | snake_case | `fecha_inicio`, `km_acumulados` |
| Claves primarias | `id_` más el nombre corto de la tabla | `id_gp`, `id_componente` |
| Claves foráneas | el mismo nombre que la columna a la que apuntan | `id_gp` en Sesion apunta a `GranPremio.id_gp` |
| Funciones | `fn_` | `fn_contrato_vigente` |
| Vistas | `vw_` | `vw_nomina` |
| Procedimientos | `usp_` | `usp_inscribir_piloto` |
| Triggers | `tr_` más la tabla | `tr_Contrato` |
| Cursores | `cur_` | `cur_usos` |
| Roles, usuarios y logins | `rol_`, `usr_`, `login_` | `rol_finanzas`, `usr_finanzas`, `login_finanzas` |
| Restricciones | tipo, tabla y qué controla | `CK_GranPremio_fechas`, `UQ_Inscripcion_gp_chasis`, `FK_Sesion_GranPremio` |
| Índices | `IX_`, o `UX_` si es único | `UX_Resultado_posicion` |

Usamos `usp_` y no `sp_` porque SQL Server busca primero en la base `master` los procedimientos que empiezan con `sp_`.

Las restricciones siempre llevan nombre, así cuando una falla el mensaje de error dice cuál fue.

Hay tablas cuya clave no es un `id_` inventado. Temporada y TopePresupuestario usan el año (`anio`), y las tablas que resuelven una relación (Puntaje, LimiteComponente, Resultado, UsoComponente) usan una clave compuesta.

Las variables y los parámetros de procedimientos y funciones van en minúscula y cortos (`@idgp`, `@cant`, `@monto`). No hace falta que sean perfectos, que se entienda alcanza.

El código SQL va en minúscula (`select`, `inner join`, `create or alter procedure`). Los nombres de tablas y columnas se escriben igual que como se crearon.



## Tipos de datos

| Dato | Tipo |
|---|---|
| Identificadores | `INT IDENTITY(1,1)` |
| Año | `SMALLINT` |
| Texto | `NVARCHAR(n)`: 80 para nombres, 200 para descripciones |
| Fecha | `DATE` |
| Fecha con hora | `DATETIME2(0)` |
| Montos | `DECIMAL(14,2)`, siempre en dólares |
| Kilómetros | `DECIMAL(10,2)` |
| Sí o no | `BIT` |
| Números chicos (ronda, posición) | `TINYINT` |

En la base no usamos tildes ni eñes, ni en los datos ni en los mensajes de error: `'Finalizo'`, `'Danado'`, `anio`. Así no se rompe nada si alguien abre el script con otra codificación.

Todo es `NOT NULL` salvo que el dato de verdad pueda faltar. Los casos estan en el diccionario de datos de cada tabla.

## Errores

Hacemos como en clase. Los procedimientos validan primero y, si algo no cierra, cortan con `raiserror('mensaje', 16, 1)`. Lo que modifica datos va dentro de una transacción, con `set xact_abort on` y `begin try`. En el `catch` se deshace la transacción si quedó abierta (`if xact_state() <> 0 rollback transaction`), se muestra el error con `print 'error: ' + error_message()` y el procedimiento devuelve 1. Si salió todo bien devuelve 0.

Los triggers no tienen `try`. Cuando un trigger rechaza algo hace `rollback transaction`, después `raiserror` y `return`, en ese orden. Así se deshace la operación que lo disparó y el mensaje que llega es el nuestro.

Los mensajes van en castellano, en minúscula, y dicen qué pasó y qué regla se rompió: "el Gran Premio 7 ya tiene dos pilotos inscriptos (RN03)".

## Comentarios

No ponemos comentarios en el código. Qué hace cada objeto y qué regla de negocio cumple (RN13, etc) va en el documento, en la sección de ese objeto.

## Scripts

- Los scripts se corren en orden, del 01 al 07, apretando F5 en cada uno. El 01 borra la base y la crea de nuevo, así que la secuencia completa se puede correr las veces que haga falta.
- `GO` solo donde es obligatorio: después del `CREATE DATABASE` (si no, el `USE` falla porque la base todavía no existe) y antes de cada `create or alter` de una función, vista, procedimiento o trigger, porque tienen que ser lo primero de su lote. En ningún otro lado.
- Las tablas se crean por niveles de dependencia (primero las que no apuntan a ninguna otra), no por área.
