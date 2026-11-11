# Convenciones

las acordamos antes de escribir SQL para que el script final no parezca escrito por cuatro personas distintas. Si alguien necesita cambiar una lo charlamos y se actualiza acá.

## Motor

SQL Server 2019 o posterior. lo pedimos así porque usamos `CREATE OR ALTER` y `DROP ... IF EXISTS`, que no existen en versiones mas viejas.

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
| Restricciones | tipo, tabla y qué controla | `CK_GranPremio_fechas`, `UQ_Inscripcion_gp_chasis`, `FK_Sesion_GranPremio` |
| Índices | `IX_`, o `UX_` si es único | `UX_Resultado_posicion` |

usamos `usp_` y no `sp_` porque SQL Server busca primero en la base `master` los procedimientos que empiezan con `sp_`.

Las restricciones siempre llevan nombre, así cuando una falla el mensaje de error dice cuál fue.

Hay tablas cuya clave no es un `id_` inventado. Temporada y TopePresupuestario usan el año (`anio`), y las tablas que resuelven una relación (Puntaje, LimiteComponente, Resultado, UsoComponente) usan una clave compuesta.

las variables dentro de procedimientos y triggers van en minúscula y cortas (`@idgp`, `@cant`, `@tot`). No hace falta que sean perfectas, que se entienda alcanza.



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

Los textos fijos van con N adelante (`N'Finalizó'`) para que no se rompan las tildes.

todo es `NOT NULL` salvo que el dato de verdad pueda faltar. los casos estan en el diccionario de datos de cada tabla.

## Códigos de error

Cada área tiene su rango para los `THROW`. Si salta un error en la defensa, por el número sabemos de quién es.

| Área | Rango |
|---|---|
| Deportiva | 50100 a 50199 |
| Personal | 50200 a 50299 |
| Técnica | 50300 a 50399 |
| Finanzas | 50400 a 50499 |

Los mensajes van en castellano y dicen qué pasó, no qué hacer: "El Gran Premio ya tiene dos pilotos inscriptos."

## Comentarios

no ponemos comentarios en el código. Qué hace cada objeto y qué regla de negocio cumple (RN13, etc) va en el documento, en la sección de ese objeto.

## Scripts

- Cada script tiene que poder correrse dos veces seguidas sin errores.
- antes de cada `CREATE VIEW`, `FUNCTION`, `PROCEDURE` o `TRIGGER` va un `GO`, porque tienen que ser lo primero de su lote.
- Las tablas se crean por niveles de dependencia (primero las que no apuntan a ninguna otra), no por área.
