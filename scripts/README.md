# Scripts

Están numerados en el orden en que se ejecutan.

| Script | Qué hace |
|---|---|
| `01_estructura.sql` | Borra la base si existe, la crea de nuevo y arma las 25 tablas con sus restricciones |
| `02_datos.sql` | Carga los datos de prueba (temporadas 2025 y 2026) |
| `03_funciones.sql` | Las cinco funciones |
| `04_vistas.sql` | Las cuatro vistas |
| `05_procedimientos.sql` | Los seis procedimientos, con el cursor del cierre de Gran Premio |
| `06_triggers.sql` | Los cuatro triggers |
| `07_seguridad.sql` | Logins, usuarios, roles y permisos |
| `08_consultas.sql` | Las consultas y subconsultas del documento |
| `99_pruebas.sql` | Prueba cada regla de negocio, cada error y los permisos de cada rol |
| `TP_completo.sql` | Del 01 al 07 en un solo archivo |

## Cómo se corren

Lo más rápido es abrir `TP_completo.sql` en SSMS y apretar F5. Arma la base entera desde cero, y se puede correr las veces que haga falta porque empieza borrando la base.

También se pueden correr del 01 al 07 de a uno, en orden. Es lo que conviene mientras se trabaja en un área.

Después, con la base recién armada, `08_consultas.sql` muestra las consultas con los resultados que figuran en el documento. `99_pruebas.sql` va al final porque cambia los datos (cierra Grandes Premios, carga compras). Cada prueba avisa con un `print` qué tiene que pasar, y si algo se acepta cuando no debería, imprime `MAL`.

## TP_completo.sql

Es el 01 al 07 pegados en orden. Solo lleva `GO` donde SQL Server lo obliga: después del `create database` y antes de cada función, vista, procedimiento o trigger. El `use EscuderiaF1` del principio de cada script se saca, porque a esa altura ya se está parado en la base.

No se edita a mano. Si se cambia alguno de los scripts del 01 al 07, se vuelve a armar pegándolos de nuevo, y se prueba corriéndolo dos veces seguidas.
