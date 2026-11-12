# Base de datos de Red Bull Racing (F1)

TP integrador de Ingeniería de Datos I (segundo cuatrimestre 2026, prof. Alejandro Feichubuinm).

Es la base de datos para la gestión interna de una sola escudería de F1, Red Bull Racing, hecha en SQL Server. Guarda cuatro cosas:

- La parte deportiva: Grandes Premios, sesiones, resultados y puntos.
- El personal: empleados, pilotos y contratos.
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
doc/tablas/ el modelo de tablas en draw.io y su imagen
scripts/    los scripts SQL, numerados en el orden en que se ejecutan
```

Avance del documento:

| Sección | Archivo | Estado |
|---|---|---|
| Descripción, alcance y reglas de negocio | [doc/01_alcance.md](doc/01_alcance.md) | listo para revisar |
| DER | [doc/02_der.md](doc/02_der.md) | listo para revisar |
| Normalización | [doc/03_normalizacion.md](doc/03_normalizacion.md) | listo para revisar |
| Modelo de tablas y diccionario de datos | [doc/04_tablas.md](doc/04_tablas.md) | listo para revisar |
| Consultas y subconsultas | [doc/05_consultas.md](doc/05_consultas.md) | listo para revisar |
| Vistas, procedimientos, triggers, cursor y funciones | [doc/06_objetos.md](doc/06_objetos.md) | listo para revisar |
| Manejo de errores, seguridad y centralización | [doc/07_errores_seguridad.md](doc/07_errores_seguridad.md) | listo para revisar |
| Conclusiones | [doc/08_conclusiones.md](doc/08_conclusiones.md) | listo para revisar |

El documento completo para entregar es [doc/TP_integrador_RedBull.docx](doc/TP_integrador_RedBull.docx). Junta todas las secciones en el orden del enunciado, con carátula e índice. Faltan los legajos y quién hizo cada área (están marcados en amarillo). Si se cambia alguna sección, el cambio también se pasa al .docx.

Las convenciones de nombres, tipos y manejo de errores estan en [doc/convenciones.md](doc/convenciones.md). Leerlas antes de escribir la primera tabla porfa.

## Cómo trabajamos con Git

1. Cada uno trabaja en su branch, con el área y su nombre: `tecnica-juan`, `finanzas-joaquin`.
2. Se commitea a medida que se avanza, no todo junto al final. El enunciado pide que cada integrante tenga trabajo real en su branch.
3. Cuando algo funciona se abre un pull request a `main`. El integrador lo revisa y lo mergea.
4. En `main` solo entra lo que corre.


## Cómo armar la base

En SQL Server 2019 o posterior, abrir `scripts/TP_completo.sql` en SSMS y apretar F5. Arma la base `EscuderiaF1` desde cero, con datos, objetos y seguridad, y se puede correr de nuevo cuando haga falta.

Después se pueden correr `scripts/08_consultas.sql` (las consultas del documento) y `scripts/99_pruebas.sql` (prueba cada regla y cada error). El detalle de cada script está en [scripts/README.md](scripts/README.md).
