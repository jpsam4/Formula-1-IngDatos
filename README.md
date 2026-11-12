# Base de datos de Red Bull Racing (F1)

TP integrador de Ingeniería de Datos I (segundo cuatrimestre 2026, prof. Alejandro Feichubuinm).

es la base de datos para la gestión interna de una sola escudería de F1, Red Bull Racing, hecha en SQL Server. guarda cuatro cosas:

- La parte deportiva: Grandes Premios, sesiones, resultados y puntos.
- el personal: empleados, pilotos y contratos.
- La parte técnica: chasis, piezas, cuánto se usó cada una y las penalizaciones por pasarse del límite
- Las finanzas: gastos, proveedores y el tope de gasto anual.

El modelo sirve para varias temporadas. Los datos de prueba son de la 2026.


## Equipo

| Integrante | Área | Branch |
|---|---|---|
| a definir | Deportiva | |
| a definir | Personal | |
| a definir | Técnica | |
| a definir | Finanzas y seguridad | |

Integrador (junta los scripts y se fija que corran en orden): a definir.

## Cómo está organizado el repo

```
doc/        el documento del TP, seccion por seccion
doc/der/    el DER en draw.io y sus imagenes
scripts/    los scripts SQL, numerados en el orden en que se ejecutan
```

avance del documento:

| Sección | Archivo | Estado |
|---|---|---|
| Descripción, alcance y reglas de negocio | [doc/01_alcance.md](doc/01_alcance.md) | listo para revisar |
| DER | [doc/02_der.md](doc/02_der.md) | listo para revisar |
| Normalización | [doc/03_normalizacion.md](doc/03_normalizacion.md) | listo para revisar |
| Modelo de tablas, diccionario de datos | | pendiente |
| Consultas, vistas, procedimientos, triggers, cursor, funciones | | pendiente |
| Manejo de errores, seguridad, conclusiones | | pendiente |

Las convenciones de nombres, tipos y códigos de error estan en [doc/convenciones.md](doc/convenciones.md). leerlas antes de escribir la primera tabla porfa.

## Cómo trabajamos con Git

1. Cada uno trabaja en su branch, con el área y su nombre: `tecnica-juan`, `finanzas-joaquin`.
2. Se commitea a medida que se avanza, no todo junto al final. el enunciado pide que cada integrante tenga trabajo real en su branch.
3. Cuando algo funciona se abre un pull request a `main`. El integrador lo revisa y lo mergea.
4. En `main` solo entra lo que corre.


## Cómo armar la base

todavía no hay scripts. Cuando estén, se ejecutan en este orden sobre SQL Server 2019 o posterior:

1. `scripts/01_estructura.sql`
2. `scripts/02_datos.sql`
3. `scripts/03_funciones.sql`
4. `scripts/04_vistas.sql`
5. `scripts/05_procedimientos.sql`
6. `scripts/06_triggers.sql`
7. `scripts/07_seguridad.sql`
8. `scripts/99_pruebas.sql` (opcional, muestra cada objeto funcionando y cada error saltando)

También va a haber un `TP_completo.sql` con los scripts 01 a 07 pegados en orden, para armar todo de una.
