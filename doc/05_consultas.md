# Consultas y subconsultas

Están en [scripts/08_consultas.sql](../scripts/08_consultas.sql). Cada una responde una pregunta que alguien de la escudería se haría de verdad, y están agrupadas por área.

Se corren con la base recién armada (scripts 01 a 07), y los resultados que ponemos son con esos datos. El script de pruebas los cambia (cierra Grandes Premios, carga compras), así que si se corre antes los números no van a ser los mismos.

## Qué tiene cada una

| Lo que tenía que aparecer | Dónde |
|---|---|
| SELECT con WHERE y ORDER BY | Consultas 1, 6, 8 y casi todas las demás |
| JOIN entre tres o más tablas | Consultas 1, 2, 3, 8, 9 y 13 |
| LEFT, RIGHT o FULL JOIN | Consulta 2 (LEFT) y consulta 4 (RIGHT) |
| GROUP BY con funciones de agregación | Consultas 3, 5, 7, 9, 10, 11 y 12 |
| HAVING | Consultas 3, 9 y 12 |
| Subconsulta con IN o NOT IN | Subconsultas 8 (IN) y 9 (NOT IN). La 3 también usa NOT IN |
| Subconsulta correlacionada o con EXISTS | Subconsultas 4 (EXISTS) y 5 (NOT EXISTS), y 6, 7 y 10 (correlacionadas) |
| Subconsulta con ANY o ALL | Subconsultas 3 (ANY) y 7 (ALL) |
| Subconsulta en el FROM o en el SELECT | Subconsultas 1 (FROM) y 2 (SELECT) |

Por área quedan así: Deportiva tiene las consultas 1 a 4 y las subconsultas 1 y 2, Personal las consultas 5 a 7 y las subconsultas 3 y 4, Técnica las consultas 8 a 10 y las subconsultas 5 a 8, y Finanzas las consultas 11 a 13 y las subconsultas 9 y 10.

## Consultas

### Deportiva

#### Consulta 1. ¿Cómo es el calendario 2026?

Junta GranPremio, Circuito y Pais, filtra por año y ordena por ronda. Los dos `case` muestran en palabras si el fin de semana es sprint y si el Gran Premio ya se cerró, en vez de un 0 o un 1.

```sql
select g.ronda, g.nombre as gran_premio, c.nombre as circuito, p.nombre as pais,
       g.fecha_inicio, g.fecha_fin,
       case when g.es_sprint = 1 then 'si' else 'no' end as sprint,
       case when g.cerrado = 1 then 'cerrado' else 'abierto' end as estado
from GranPremio g
inner join Circuito c on c.id_circuito = g.id_circuito
inner join Pais p on p.id_pais = c.id_pais
where g.anio = 2026
order by g.ronda
```

Con los datos de prueba devuelve los 7 Grandes Premios cargados. Mónaco y Barcelona todavía están abiertos.

#### Consulta 2. ¿Qué hizo cada piloto en las carreras y sprints de 2026, y cuántos puntos sacó en cada una?

Son seis tablas con `inner join` y Puntaje con `left join`. Un abandono, o una posición que no da puntos, no tiene fila en Puntaje, y con `inner join` desaparecería del listado. Con `left join` la fila queda y el `isnull` la muestra con 0. Solo trae las sesiones que reparten puntos (`otorga_puntos = 1`).

```sql
select g.ronda, g.nombre as gran_premio, ts.nombre as sesion, e.apellido as piloto,
       r.estado, r.posicion, isnull(pu.puntos, 0) as puntos
from Resultado r
inner join Sesion s on s.id_sesion = r.id_sesion
inner join TipoSesion ts on ts.id_tipo_sesion = s.id_tipo_sesion
inner join GranPremio g on g.id_gp = s.id_gp
inner join Inscripcion i on i.id_inscripcion = r.id_inscripcion
inner join Empleado e on e.id_empleado = i.id_piloto
left join Puntaje pu on pu.anio = g.anio
                    and pu.id_tipo_sesion = s.id_tipo_sesion
                    and pu.posicion = r.posicion
where g.anio = 2026
  and ts.otorga_puntos = 1
order by g.ronda, ts.nombre, r.posicion
```

Con los datos de prueba: 18 filas. El abandono de Hadjar en Australia y la descalificación de Verstappen en Miami aparecen con 0 puntos.

#### Consulta 3. ¿Qué pilotos sumaron más de 50 puntos en 2026?

Agrupa por piloto y filtra con `having`, porque la condición es sobre la suma y no sobre cada fila. Acá Puntaje va con `inner join` a propósito: lo que no da puntos no tiene nada que sumar.

```sql
select e.apellido, sum(p.puntos) as puntos
from Resultado r
inner join Sesion s on s.id_sesion = r.id_sesion
inner join GranPremio g on g.id_gp = s.id_gp
inner join Inscripcion i on i.id_inscripcion = r.id_inscripcion
inner join Empleado e on e.id_empleado = i.id_piloto
inner join Puntaje p on p.anio = g.anio
                    and p.id_tipo_sesion = s.id_tipo_sesion
                    and p.posicion = r.posicion
where g.anio = 2026
group by e.apellido
having sum(p.puntos) > 50
order by puntos desc
```

Con los datos de prueba: Verstappen, con 111. Hadjar tiene 35 y queda afuera.

#### Consulta 4. ¿Qué circuitos tenemos cargados que no están en el calendario 2026?

Con `right join` vienen todos los circuitos, tengan o no Gran Premio. La condición del año va en el `on` y no en el `where`: si estuviera en el `where`, las filas sin Gran Premio (que tienen `g.anio` en null) se descartarían y el `right join` no serviría de nada. Después el `where g.id_gp is null` deja solo los que no tienen.

```sql
select c.nombre as circuito, c.ciudad
from GranPremio g
right join Circuito c on c.id_circuito = g.id_circuito and g.anio = 2026
where g.id_gp is null
```

Con los datos de prueba devuelve el Red Bull Ring, que está cargado pero no tiene Gran Premio en 2026.

### Personal

#### Consulta 5. ¿Cuánta gente hay en cada departamento y cuánto se paga de sueldos?

Cuenta solo los contratos vigentes hoy y usa `count`, `sum` y `avg`. El promedio de un decimal sale con un montón de decimales, por eso el `cast`. Es una consulta para Recursos Humanos: por los permisos, nadie más puede leer Contrato.

```sql
select pu.departamento, count(*) as empleados, sum(c.sueldo_mensual_usd) as sueldos_mensuales_usd,
       cast(avg(c.sueldo_mensual_usd) as decimal(14,2)) as sueldo_promedio_usd
from Empleado e
inner join Puesto pu on pu.id_puesto = e.id_puesto
inner join Contrato c on c.id_empleado = e.id_empleado
where c.fecha_inicio <= getdate()
  and (c.fecha_fin is null or c.fecha_fin >= getdate())
group by pu.departamento
order by sueldos_mensuales_usd desc
```

Con los datos de prueba devuelve cuatro departamentos. Deportivo es el que más cuesta, por los sueldos de los pilotos.

#### Consulta 6. ¿Qué contratos se vencen en los próximos 6 meses?

Para que Recursos Humanos sepa a quién tiene que renovar. Compara `fecha_fin` con la fecha de hoy, así que el resultado depende del día en que se corra.

```sql
select e.apellido, e.nombre, pu.nombre as puesto, c.fecha_fin,
       datediff(day, getdate(), c.fecha_fin) as dias_que_faltan
from Contrato c
inner join Empleado e on e.id_empleado = c.id_empleado
inner join Puesto pu on pu.id_puesto = e.id_puesto
where c.fecha_fin between cast(getdate() as date) and dateadd(month, 6, getdate())
order by c.fecha_fin
```

Con los datos de prueba: Tsunoda y Bernardi (corrida el 11/11/2026). Los dos vencen el 31/12/2026.

#### Consulta 7. ¿Cuántos años lleva cada empleado en la escudería?

Toma el primer contrato de cada uno con `min`, porque hay empleados con más de un contrato (Tsunoda, de Vries). Los años salen de `datediff(year, ...)`, igual que la edad en el ejemplo de funciones de clase. Cuenta cambios de año calendario, así que es aproximado: alguien que entró en julio de 2025 ya figura con 1.

```sql
select e.apellido, e.nombre, min(c.fecha_inicio) as primer_contrato,
       datediff(year, min(c.fecha_inicio), getdate()) as anios
from Empleado e
inner join Contrato c on c.id_empleado = e.id_empleado
group by e.id_empleado, e.apellido, e.nombre
order by primer_contrato
```

Con los datos de prueba devuelve los 17 empleados, del más antiguo (Brandt, desde 2021) al más nuevo (Hadjar, que entró en 2026).

### Técnica

#### Consulta 8. ¿Qué penalizaciones de grilla hubo en 2026 y por qué?

Junta seis tablas para mostrar el Gran Premio, el piloto y la pieza de cada penalización.

```sql
select g.ronda, g.nombre as gran_premio, e.apellido as piloto, t.nombre as tipo_pieza,
       c.numero_serie, p.puestos_grilla, p.motivo
from Penalizacion p
inner join Inscripcion i on i.id_inscripcion = p.id_inscripcion
inner join GranPremio g on g.id_gp = i.id_gp
inner join Empleado e on e.id_empleado = i.id_piloto
inner join Componente c on c.id_componente = p.id_componente
inner join TipoComponente t on t.id_tipo = c.id_tipo
where g.anio = 2026
order by g.ronda
```

Con los datos de prueba devuelve la de Verstappen en Mónaco: cuarto MGU-K de la temporada con límite de 3, 10 puestos.

#### Consulta 9. ¿Qué pilotos están a una pieza del límite de algún tipo, o ya lo pasaron?

Le sirve al ingeniero para saber cuándo cambiar una pieza le va a costar puestos al piloto. Cuenta con `count(distinct ...)` porque una misma pieza se usa en varios Grandes Premios y tiene una fila de uso por cada uno. El límite sale de LimiteComponente y entra en el `group by` para poder compararlo en el `having`.

```sql
select e.apellido as piloto, t.nombre as tipo_pieza, l.cantidad_max as limite,
       count(distinct u.id_componente) as piezas_usadas, sum(u.km_recorridos) as km
from UsoComponente u
inner join Componente c on c.id_componente = u.id_componente
inner join TipoComponente t on t.id_tipo = c.id_tipo
inner join Inscripcion i on i.id_inscripcion = u.id_inscripcion
inner join GranPremio g on g.id_gp = i.id_gp
inner join Empleado e on e.id_empleado = i.id_piloto
inner join LimiteComponente l on l.anio = g.anio and l.id_tipo = c.id_tipo
where g.anio = 2026
group by e.apellido, t.nombre, l.cantidad_max
having count(distinct u.id_componente) >= l.cantidad_max - 1
order by piezas_usadas desc
```

Con los datos de prueba: Verstappen (4 MGU-K con límite de 3, ya penalizado) y Hadjar (2 de 3, así que el próximo MGU-K es el último sin penalización).

#### Consulta 10. ¿Cuántas piezas hay de cada tipo y en qué estado?

Es el stock de piezas. Agrupa por tipo y estado y suma los km de cada grupo.

```sql
select t.nombre as tipo, c.estado, count(*) as piezas,
       sum(c.km_acumulados) as km_totales
from Componente c
inner join TipoComponente t on t.id_tipo = c.id_tipo
group by t.nombre, c.estado
order by t.nombre, c.estado
```

Con los datos de prueba: 9 grupos. Por ejemplo, hay 4 MGU-K nuevos para usar y 4 dañados.

### Finanzas

#### Consulta 11. ¿En qué se gastó la plata en 2026, y qué parte cuenta para el tope?

Agrupa los gastos del año por categoría y muestra si cada categoría computa para el tope.

```sql
select cg.nombre as categoria,
       case when cg.computa_tope = 1 then 'si' else 'no' end as cuenta_tope,
       count(*) as gastos, sum(g.monto_usd) as total_usd
from Gasto g
inner join CategoriaGasto cg on cg.id_categoria = g.id_categoria
where year(g.fecha) = 2026
group by cg.nombre, cg.computa_tope
order by total_usd desc
```

Con los datos de prueba devuelve seis categorías. La más grande es Investigación y desarrollo (69,5 millones). Hospitalidad y marketing (6,3 millones) no cuenta para el tope.

#### Consulta 12. ¿A qué proveedores les compramos más de 10 millones en 2026?

Agrupa por proveedor y filtra la suma con `having`.

```sql
select pr.razon_social, pa.nombre as pais, count(*) as compras, sum(g.monto_usd) as total_usd
from Gasto g
inner join Proveedor pr on pr.id_proveedor = g.id_proveedor
inner join Pais pa on pa.id_pais = pr.id_pais
where year(g.fecha) = 2026
group by pr.razon_social, pa.nombre
having sum(g.monto_usd) > 10000000
order by total_usd desc
```

Con los datos de prueba devuelve cuatro proveedores. El más grande es Milton Composites, con 90,55 millones.

#### Consulta 13. ¿Qué alertas de tope saltaron y qué gasto las disparó?

TopePresupuestario se une por el año de la fecha del gasto (`year(g.fecha)`) y no por una clave foránea, porque Gasto no guarda el año.

```sql
select year(g.fecha) as anio, a.fecha as fecha_alerta, g.descripcion, pr.razon_social,
       g.monto_usd, a.gasto_acumulado_usd, t.monto_usd as tope_usd
from AlertaTope a
inner join Gasto g on g.id_gasto = a.id_gasto
inner join Proveedor pr on pr.id_proveedor = g.id_proveedor
inner join TopePresupuestario t on t.anio = year(g.fecha)
order by anio
```

Con los datos de prueba devuelve la de 2025: el gasto de frenos de fin de temporada llevó el acumulado a 123,7 millones sobre un tope de 135. En 2026 todavía no saltó ninguna, el año está en 89,47 % del tope, justo abajo del 90 %. El script de pruebas la hace saltar.

## Subconsultas

Para cada una ponemos las tres cosas que pide el enunciado: qué información se busca, qué hace la subconsulta y por qué es adecuada.

### Deportiva

#### Subconsulta 1. ¿Cuántos puntos saca cada piloto en promedio por fin de semana?

```sql
select x.piloto, count(*) as grandes_premios, sum(x.puntos) as puntos,
       cast(avg(x.puntos * 1.0) as decimal(5,2)) as promedio
from (
    select e.apellido as piloto, g.id_gp, isnull(sum(pu.puntos), 0) as puntos
    from Resultado r
    inner join Sesion s on s.id_sesion = r.id_sesion
    inner join GranPremio g on g.id_gp = s.id_gp
    inner join Inscripcion i on i.id_inscripcion = r.id_inscripcion
    inner join Empleado e on e.id_empleado = i.id_piloto
    left join Puntaje pu on pu.anio = g.anio
                        and pu.id_tipo_sesion = s.id_tipo_sesion
                        and pu.posicion = r.posicion
    where g.anio = 2026
    group by e.apellido, g.id_gp
) x
group by x.piloto
order by promedio desc
```

- Qué queremos saber: el rendimiento promedio de cada piloto por Gran Premio en 2026, con carrera y sprint juntos.
- Qué hace la subconsulta: está en el `from`. Arma una fila por piloto y Gran Premio con los puntos de ese fin de semana, y la consulta de afuera promedia esas filas.
- Por qué sirve: hay que agregar dos veces: primero sumar por Gran Premio y después promediar. Eso no se puede hacer en un solo nivel (`avg(sum(...))` da error), así que la primera agregación va adentro. El `* 1.0` es para que `avg` no haga división entera.

Con los datos de prueba: Verstappen promedia 18,50 puntos por fin de semana y Hadjar 5,83.

#### Subconsulta 2. ¿Cómo está hoy cada piloto: con qué contrato, cuántos Grandes Premios corrió y cuántos puntos tiene?

```sql
select e.apellido, p.numero_auto,
       (select c.condicion from Contrato c
        where c.id_contrato = dbo.fn_contrato_vigente(p.id_empleado, cast(getdate() as date))) as condicion_hoy,
       (select count(*) from Inscripcion i
        inner join GranPremio g on g.id_gp = i.id_gp
        where i.id_piloto = p.id_empleado and g.anio = 2026) as gp_corridos_2026,
       dbo.fn_puntos_piloto(p.id_empleado, 2026) as puntos_2026
from Piloto p
inner join Empleado e on e.id_empleado = p.id_empleado
order by puntos_2026 desc
```

- Qué queremos saber: una ficha de cada piloto.
- Qué hace la subconsulta: hay dos en el `select` y cada una devuelve un solo valor por piloto. La primera trae la condición (titular o reserva) del contrato que devuelve `fn_contrato_vigente`. La segunda cuenta sus inscripciones de 2026. Los puntos salen de `fn_puntos_piloto`.
- Por qué sirve: cada dato viene de una tabla distinta. Si se juntara todo con JOIN, las filas se multiplicarían y el conteo daría cualquier cosa. Con una subconsulta por columna, cada número se calcula por separado.

Con los datos de prueba devuelve los cuatro pilotos. Ferraro aparece con condición NULL porque hoy no tiene contrato.

### Personal

#### Subconsulta 3. ¿Qué empleados que no son pilotos cobran más que alguno de los pilotos?

```sql
select e.apellido, e.nombre, pu.nombre as puesto, c.sueldo_mensual_usd
from Empleado e
inner join Puesto pu on pu.id_puesto = e.id_puesto
inner join Contrato c on c.id_contrato = dbo.fn_contrato_vigente(e.id_empleado, cast(getdate() as date))
where e.id_empleado not in (select id_empleado from Piloto)
  and c.sueldo_mensual_usd > any (
      select c2.sueldo_mensual_usd
      from Contrato c2
      inner join Piloto p2 on p2.id_empleado = c2.id_empleado
      where c2.id_contrato = dbo.fn_contrato_vigente(p2.id_empleado, cast(getdate() as date))
  )
```

- Qué queremos saber: si hay gente del equipo que cobra más que algún piloto.
- Qué hace la subconsulta: devuelve el sueldo vigente de cada piloto, y `> any` se cumple si el sueldo del empleado es mayor que al menos uno de esa lista. Además hay un `not in` para dejar afuera a los pilotos.
- Por qué sirve: es una comparación contra un conjunto de valores. `> any` equivale a ser mayor que el mínimo de la lista, pero escrito así se lee igual que la pregunta.

Con los datos de prueba: Lenoir, el director de equipo (95.000 por mes), que cobra más que Tsunoda como reserva (90.000).

#### Subconsulta 4. ¿A quién se le cambió el sueldo en 2026?

```sql
select e.apellido, e.nombre, c.sueldo_mensual_usd as sueldo_actual
from Empleado e
inner join Contrato c on c.id_empleado = e.id_empleado
where exists (
    select 1
    from AuditoriaContrato a
    where a.id_contrato = c.id_contrato
      and year(a.fecha) = 2026
)
```

- Qué queremos saber: qué empleados tuvieron algún cambio de sueldo este año.
- Qué hace la subconsulta: para cada contrato busca si hay un registro de 2026 en AuditoriaContrato. Es correlacionada por `id_contrato`.
- Por qué sirve: solo importa si hubo al menos un cambio, no cuántos. Con un JOIN, un contrato con dos cambios saldría dos veces.

Con los datos de prueba: Verstappen y Bernardi.

### Técnica

#### Subconsulta 5. ¿Qué pilotos no corrieron ningún Gran Premio en 2026?

```sql
select e.nombre, e.apellido, p.numero_auto
from Piloto p
inner join Empleado e on e.id_empleado = p.id_empleado
where not exists (
    select 1
    from Inscripcion i
    inner join GranPremio g on g.id_gp = i.id_gp
    where i.id_piloto = p.id_empleado
      and g.anio = 2026
)
```

- Qué queremos saber: los pilotos que no se usaron en la temporada, como el de reserva.
- Qué hace la subconsulta: para cada piloto busca alguna inscripción en un Gran Premio de 2026. Es correlacionada: usa el `id_empleado` de la fila de afuera.
- Por qué sirve: la pregunta es justamente que algo no exista. `not exists` no tiene el problema de `not in` con los nulos, y se lee más claro que un `left join` buscando nulos.

Con los datos de prueba: Tsunoda (reserva) y Ferraro (su contrato terminó en 2025).

#### Subconsulta 6. ¿Qué piezas llevan más km que el promedio de su tipo?

```sql
select c.numero_serie, t.nombre as tipo, c.km_acumulados
from Componente c
inner join TipoComponente t on t.id_tipo = c.id_tipo
where c.km_acumulados > (
    select avg(c2.km_acumulados)
    from Componente c2
    where c2.id_tipo = c.id_tipo
)
order by t.nombre, c.km_acumulados desc
```

- Qué queremos saber: qué piezas se están gastando más rápido que las demás de su tipo.
- Qué hace la subconsulta: calcula el promedio de km de las piezas del mismo tipo que la pieza de la fila actual.
- Por qué sirve: el promedio cambia según el tipo, así que no se puede calcular una sola vez para toda la consulta.

Con los datos de prueba: 9 piezas. Las que más preocupan son las cajas GBX-26-01 y GBX-26-02, que están cerca de su vida útil.

#### Subconsulta 7. ¿Cuál es la pieza más gastada de cada tipo?

```sql
select t.nombre as tipo, c.numero_serie, c.km_acumulados, c.estado
from Componente c
inner join TipoComponente t on t.id_tipo = c.id_tipo
where c.km_acumulados >= all (
    select c2.km_acumulados
    from Componente c2
    where c2.id_tipo = c.id_tipo
)
order by t.nombre
```

- Qué queremos saber: la pieza con más km de cada tipo, con su número de serie y su estado.
- Qué hace la subconsulta: trae los km de todas las piezas del mismo tipo, y `>= all` deja la que tiene tantos km o más que todas.
- Por qué sirve: con `group by` y `max` se saca el máximo, pero no a qué pieza corresponde. Con `>= all` sale la fila entera. Si hubiera empate saldrían las dos.

Con los datos de prueba devuelve una por tipo. La caja GBX-26-01 tiene 3200 de sus 3500 km, y es la que se retira cuando se cierra Mónaco.

#### Subconsulta 8. ¿Qué piezas tienen km de un Gran Premio que todavía no se cerró?

```sql
select c.numero_serie, c.estado, c.km_acumulados
from Componente c
where c.id_componente in (
    select u.id_componente
    from UsoComponente u
    inner join Inscripcion i on i.id_inscripcion = u.id_inscripcion
    inner join GranPremio g on g.id_gp = i.id_gp
    where g.cerrado = 0
)
```

- Qué queremos saber: las piezas cuyo `km_acumulados` todavía no incluye su último uso, o sea las que van a cambiar cuando se cierre el Gran Premio.
- Qué hace la subconsulta: devuelve los ids de las piezas usadas en Grandes Premios con `cerrado = 0`, y el `in` filtra Componente con esa lista.
- Por qué sirve: es una lista de ids que no depende de la fila de afuera, así que `in` es lo más directo.

Con los datos de prueba devuelve las 8 piezas que se usaron en Mónaco.

### Finanzas

#### Subconsulta 9. ¿A qué proveedores no les compramos nada en 2026?

```sql
select pr.razon_social, pr.identificacion_fiscal
from Proveedor pr
where pr.id_proveedor not in (
    select g.id_proveedor
    from Gasto g
    where year(g.fecha) = 2026
)
```

- Qué queremos saber: los proveedores sin compras en el año, por ejemplo para revisar si conviene seguir con ellos.
- Qué hace la subconsulta: devuelve los proveedores que tienen algún gasto en 2026, y `not in` deja los demás.
- Por qué sirve: es una lista sin correlación. Como `id_proveedor` es NOT NULL en Gasto no aparece el problema de `not in` con los nulos (si la lista tuviera un NULL, la consulta no devolvería nada).

Con los datos de prueba: Hydra Fluidos.

#### Subconsulta 10. ¿Qué gastos se llevaron, solos, más del 10 % del tope de su año?

```sql
select year(g.fecha) as anio, g.fecha, g.descripcion, g.monto_usd
from Gasto g
where g.monto_usd > (
    select t.monto_usd * 0.10
    from TopePresupuestario t
    where t.anio = year(g.fecha)
)
order by g.monto_usd desc
```

- Qué queremos saber: los gastos más grandes, los que más mueven el tope.
- Qué hace la subconsulta: para cada gasto busca el tope de su año y calcula el 10 %. Es correlacionada por el año del gasto.
- Por qué sirve: el tope es distinto cada año (135 millones en 2025 y 215 en 2026), así que el límite cambia de fila a fila y no se puede poner un número fijo.

Con los datos de prueba: 7 gastos, 4 de 2025 y 3 de 2026. El más grande es el desarrollo aerodinámico del RB21, de 45 millones.
