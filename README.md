# Base de datos de Red Bull Racing (F1)

TP integrador de Ingeniería de Datos I (segundo cuatrimestre 2026, prof. Alejandro Feichubuinm).

Es la base de datos para la gestión interna de una sola escudería de F1, Red Bull Racing, hecha en SQL Server. Guarda cuatro cosas:

- La parte deportiva: Grandes Premios, sesiones, resultados y puntos.
- El personal: empleados, pilotos y contratos.
- La parte técnica: chasis, piezas, cuánto se usó cada una y las penalizaciones por pasarse del límite
- Las finanzas: gastos, proveedores y el tope de gasto anual.

El modelo sirve para varias temporadas. Los datos de prueba son de la 2026.


## Equipo

| Integrante | Área |
|---|---|
| Joaquin Tiago Castellano Acuna | a definir |
| Juan Zeljkovich | a definir |
| Juan Pedro Sama | a definir |
| Santiago Ohoka | a definir |

Integrador (junta los scripts y se fija que corran en orden): a definir.

## Cómo está organizado

```
doc/        el documento del TP
doc/der/    el DER en draw.io y sus imagenes
doc/tablas/ el modelo de tablas en draw.io y su imagen
scripts/    los scripts SQL, numerados en el orden en que se ejecutan
```

El documento para entregar es [doc/TP_integrador_RedBull.docx](doc/TP_integrador_RedBull.docx). Tiene todas las secciones en el orden del enunciado, con carátula e índice. Faltan los legajos y quién hizo cada área (están marcados en amarillo).

## Cómo armar la base

En SQL Server 2019 o posterior, abrir `scripts/TP_completo.sql` en SSMS y apretar F5. Arma la base `EscuderiaF1` desde cero, con datos, objetos y seguridad, y se puede correr de nuevo cuando haga falta.

Después se pueden correr `scripts/08_consultas.sql` (las consultas del documento) y `scripts/09_pruebas.sql` (prueba cada regla y cada error). El detalle de cada script está en [scripts/README.md](scripts/README.md).
