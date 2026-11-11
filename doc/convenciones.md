# Convenciones del equipo

> **Estado: propuesta, a confirmar por el equipo.**
>
> El objetivo es que los scripts de las cuatro áreas sigan un mismo estilo. Una vez confirmadas, no se cambian sin acordarlo entre todos.

## 1. Nombres

| Elemento | Criterio | Ejemplo |
|---|---|---|
| Base de datos | Un solo nombre para todos los scripts | `RedBullRacingF1` (a confirmar) |
| Esquema | Uno solo: `dbo` | `dbo.GranPremio` |
| Tablas | Singular, PascalCase, sin tildes ni eñes | `GranPremio`, `TipoComponente`, `Pais` |
| Columnas | snake_case, sin tildes ni eñes | `fecha_inicio`, `anio`, `km_acumulados` |
| Claves | Los nombres del modelo de datos acordado. Una FK se llama igual que la PK que referencia, salvo que el rol pida otro nombre | `id_gp`; `Inscripcion.id_piloto` → `Piloto.id_empleado` |
| Restricciones | Prefijo + tabla (+ columna o tabla referenciada) | `PK_GranPremio`, `FK_Sesion_GranPremio`, `UQ_Pais_codigo_iso`, `CK_Resultado_estado_posicion`, `DF_GranPremio_cerrado` |
| Índices | `IX_` para índices comunes y `UX_` para los únicos (incluidos los filtrados) | `UX_Resultado_sesion_posicion` |

Así el DER, los scripts y el documento usan los mismos nombres. Los identificadores van sin tildes ni eñes; los datos sí las llevan (ver tipos de datos).

## 2. Prefijos de objetos programables

| Objeto | Prefijo | Formato | Ejemplo |
|---|---|---|---|
| Vista | `vw_` | `vw_` + snake_case | `vw_situacion_tope` |
| Función | `fn_` | `fn_` + snake_case | `fn_contrato_vigente` |
| Procedimiento | `usp_` | `usp_` + snake_case | `usp_cargar_resultado` |
| Trigger | `tr_` | `tr_` + tabla + `_` + propósito | `tr_Gasto_control_tope` |

Se usa `usp_` y no `sp_`: SQL Server busca primero en la base `master` los procedimientos cuyo nombre empieza con `sp_`.

Los ejemplos son ilustrativos: el nombre definitivo de cada objeto se fija cuando se desarrolla.

## 3. Tipos de datos

| Dato | Tipo | Detalle |
|---|---|---|
| Texto | `NVARCHAR(n)` | Para tildes y eñes. Los literales se escriben con `N'...'` |
| Montos | `DECIMAL(14,2)` | Siempre en dólares (USD). La columna lleva el sufijo `_usd` |
| Fechas | `DATE` | A confirmar |
| Fecha y hora | `DATETIME2(0)` | A confirmar |
| Sí / no | `BIT` | A confirmar (`es_sprint`, `cerrado`, `computa_tope`) |

## 4. Errores

Todos los errores propios se lanzan con `THROW`, con un código del rango del área:

| Área | Rango de códigos |
|---|---|
| Deportiva | 50100 a 50199 |
| Personal | 50200 a 50299 |
| Técnica | 50300 a 50399 |
| Finanzas (incluida la seguridad) | 50400 a 50499 |

Así, con solo ver el número de un error se sabe de qué área es.

**Formato del mensaje:** `<objeto>: <descripción en minúscula, sin punto final> (RNxx)`. La referencia `(RNxx)` va cuando el error hace cumplir una regla de negocio. El estado es siempre `1`.

```sql
THROW 50401, N'tr_Gasto_control_tope: el gasto supera el tope presupuestario del año (RN19)', 1;
```

- Dentro de un `CATCH`, el error se relanza con `THROW;` (sin parámetros) para conservar el código original.
- Cada área numera sus códigos en orden dentro de su rango y lleva una lista (código, objeto, regla, situación). Esa lista alimenta la sección de manejo de errores del documento final.

## 5. Cabecera de cada bloque de SQL

Cada bloque de SQL (tabla, objeto programable, consulta) lleva el autor y la regla de negocio que implementa:

```sql
/* ============================================================
   Objeto : <nombre del objeto o descripción del bloque>
   Área   : <Deportiva | Personal | Técnica | Finanzas>
   Autor  : <nombre y apellido>
   Reglas : <RNxx, RNyy, o "—" si no implementa ninguna>
   Descr. : <qué hace y para qué existe>
   ============================================================ */
```

Cada `CHECK` no trivial lleva su regla en un comentario de una línea (`-- RN11`).

## 6. Archivos de scripts

- Los scripts van en `/scripts`, guardados en UTF-8.
- Cada `CREATE VIEW`, `FUNCTION`, `PROCEDURE` o `TRIGGER` va en su propio lote, separado con `GO`.

## 7. Git y GitHub

**Ramas**

| Rama | Uso |
|---|---|
| `main` | Versión integrada y estable. Se actualiza solo por pull request. |
| `<area>-<nombre>` | Una por integrante, para el trabajo de su área; por ejemplo, `deportiva-nombre`. |

El integrador revisa y mergea a `main` los pull requests de las ramas de área.

**Commits**

- Mensajes cortos en español, que digan qué cambia y en qué área. Por ejemplo: `Deportiva: tabla Resultado con índice filtrado`.
- No se versionan los backups (`.bak`) ni los archivos de datos de SQL Server (ver `.gitignore`).
