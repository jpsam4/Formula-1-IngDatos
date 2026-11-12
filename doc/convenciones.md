# Convenciones

Las acordamos antes de escribir SQL para que el script final no parezca escrito por cuatro personas distintas. Si alguien necesita cambiar una lo charlamos y se actualiza acá.

## Motor

Microsoft SQL Server 2025. Todos escribimos y probamos los scripts en esa versión. Usamos `CREATE OR ALTER` y `DROP ... IF EXISTS` para que los scripts se puedan correr dos veces seguidas.

La base se llama `EscuderiaF1` y usa un solo esquema, `dbo`.

## Nombres

| Qué | Cómo | Ejemplo |
|---|---|---|
| Tablas | PascalCase, en singular | `GranPremio`, `UsoComponente` |
| Columnas | snake_case | `fecha_inicio`, `km_acumulados` |
| Claves primarias | `id_` más el nombre corto de la tabla | `id_gp`, `id_componente` |
| Claves foráneas | el mismo nombre que la columna a la que apuntan, salvo que el rol pida otro | `id_gp` en Sesion apunta a `GranPremio.id_gp`; `id_piloto` en Inscripcion apunta a `Piloto.id_empleado` |
| Funciones | `fn_` | `fn_contrato_vigente` |
| Vistas | `vw_` | `vw_nomina` |
| Procedimientos | `usp_` | `usp_inscribir_piloto` |
| Triggers | `tr_` más la tabla | `tr_Contrato` |
| Restricciones | tipo, tabla y qué controla | `CK_GranPremio_fechas`, `UQ_Inscripcion_gp_chasis`, `FK_Sesion_GranPremio`, `DF_GranPremio_cerrado` |
| Índices | `IX_`, o `UX_` si es único | `UX_Resultado_posicion` |

Usamos `usp_` y no `sp_` porque SQL Server busca primero en la base `master` los procedimientos que empiezan con `sp_`.

Los nombres de tablas y columnas van sin tildes ni eñes (`anio`, `Pais`). Los datos sí las llevan.

Las restricciones siempre llevan nombre, así cuando una falla el mensaje de error dice cuál fue.

Hay tablas cuya clave no es un `id_` inventado. Temporada y TopePresupuestario usan el año (`anio`), y las tablas que resuelven una relación (Puntaje, LimiteComponente, Resultado, UsoComponente) usan una clave compuesta.

Las variables dentro de procedimientos y triggers van en minúscula y cortas (`@idgp`, `@cant`, `@tot`). No hace falta que sean perfectas, que se entienda alcanza.

## Tipos de datos

| Dato | Tipo |
|---|---|
| Identificadores | `INT IDENTITY(1,1)` |
| Año | `SMALLINT` |
| Texto | `NVARCHAR(n)`: 80 para nombres, 200 para descripciones |
| Fecha | `DATE` |
| Fecha con hora | `DATETIME2(0)` |
| Montos | `DECIMAL(14,2)`, siempre en dólares. La columna lleva el sufijo `_usd` (`monto_usd`) |
| Kilómetros | `DECIMAL(10,2)` |
| Sí o no | `BIT` |
| Números chicos (ronda, posición) | `TINYINT` |

Los textos fijos van con N adelante (`N'Finalizó'`) para que no se rompan las tildes.

Todo es `NOT NULL` salvo que el dato de verdad pueda faltar. Los casos estan en el diccionario de datos de cada tabla.

## Códigos de error

Cada área tiene su rango para los `THROW`. Por el número de un error sabemos de qué área es.

| Área | Rango |
|---|---|
| Deportiva | 50100 a 50199 |
| Personal | 50200 a 50299 |
| Técnica | 50300 a 50399 |
| Finanzas (incluida la seguridad) | 50400 a 50499 |

Los mensajes van en castellano y dicen qué pasó, no qué hacer. Si el error hace cumplir una regla de negocio, el mensaje empieza con la regla entre corchetes. El estado es siempre `1`:

```sql
THROW 50201, N'[RN03] El Gran Premio ya tiene dos pilotos inscriptos.', 1;
```

- Dentro de un `CATCH`, el error se relanza con `THROW;` (sin parámetros) para no perder el código original.
- Cada área numera sus códigos en orden dentro de su rango y lleva la lista (código, objeto, regla, situación) en la sección de manejo de errores del documento.

## Comentarios

El código no se explica línea por línea: qué hace cada objeto y por qué va en el documento, en la sección de ese objeto.

Lo único que lleva cada tabla y cada objeto es una cabecera de una línea con el autor y las reglas que implementa. Como la entrega no se hace por GitHub, es la forma de que en el script se vea quién hizo cada parte:

```sql
/* Autor: Nombre Apellido | Área: Personal | Reglas: RN07, RN08, RN09 */
```

Cada `CHECK` que no sea obvio lleva su regla al lado: `-- RN11`.

## Scripts

- Cada script tiene que poder correrse dos veces seguidas sin errores.
- Antes de cada `CREATE VIEW`, `FUNCTION`, `PROCEDURE` o `TRIGGER` va un `GO`, porque tienen que ser lo primero de su lote.
- Las tablas se crean por niveles de dependencia (primero las que no apuntan a ninguna otra), no por área.
- Los archivos se guardan en UTF-8, para que no se rompan las tildes.
