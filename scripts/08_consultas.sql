use EscuderiaF1


print 'consulta 1: calendario 2026'

select g.ronda, g.nombre as gran_premio, c.nombre as circuito, p.nombre as pais,
       g.fecha_inicio, g.fecha_fin,
       case when g.es_sprint = 1 then 'si' else 'no' end as sprint,
       case when g.cerrado = 1 then 'cerrado' else 'abierto' end as estado
from GranPremio g
inner join Circuito c on c.id_circuito = g.id_circuito
inner join Pais p on p.id_pais = c.id_pais
where g.anio = 2026
order by g.ronda


print 'consulta 2: resultados de carrera y sprint de cada piloto en 2026, con los puntos'

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


print 'consulta 3: pilotos que sumaron mas de 50 puntos en 2026'

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


print 'consulta 4: gente y sueldos por departamento, con contrato vigente hoy'

select pu.departamento, count(*) as empleados, sum(c.sueldo_mensual_usd) as sueldos_mensuales_usd,
       cast(avg(c.sueldo_mensual_usd) as decimal(14,2)) as sueldo_promedio_usd
from Empleado e
inner join Puesto pu on pu.id_puesto = e.id_puesto
inner join Contrato c on c.id_empleado = e.id_empleado
where c.fecha_inicio <= getdate()
  and (c.fecha_fin is null or c.fecha_fin >= getdate())
group by pu.departamento
order by sueldos_mensuales_usd desc


print 'consulta 5: contratos que se vencen en los proximos 6 meses'

select e.apellido, e.nombre, pu.nombre as puesto, c.fecha_fin,
       datediff(day, getdate(), c.fecha_fin) as dias_que_faltan
from Contrato c
inner join Empleado e on e.id_empleado = c.id_empleado
inner join Puesto pu on pu.id_puesto = e.id_puesto
where c.fecha_fin between cast(getdate() as date) and dateadd(month, 6, getdate())
order by c.fecha_fin


print 'consulta 6: cuantos anios lleva cada empleado en la escuderia'

select e.apellido, e.nombre, min(c.fecha_inicio) as primer_contrato,
       datediff(year, min(c.fecha_inicio), getdate()) as anios
from Empleado e
inner join Contrato c on c.id_empleado = e.id_empleado
group by e.id_empleado, e.apellido, e.nombre
order by primer_contrato


print 'consulta 7: penalizaciones de grilla de 2026'

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


print 'consulta 8: pilotos que en 2026 estan a una pieza del limite de algun tipo o ya lo pasaron'

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


print 'consulta 9: circuitos que no estan en el calendario 2026'

select c.nombre as circuito, c.ciudad
from GranPremio g
right join Circuito c on c.id_circuito = g.id_circuito and g.anio = 2026
where g.id_gp is null


print 'consulta 10: gasto por categoria en 2026 y si cuenta para el tope'

select cg.nombre as categoria,
       case when cg.computa_tope = 1 then 'si' else 'no' end as cuenta_tope,
       count(*) as gastos, sum(g.monto_usd) as total_usd
from Gasto g
inner join CategoriaGasto cg on cg.id_categoria = g.id_categoria
where year(g.fecha) = 2026
group by cg.nombre, cg.computa_tope
order by total_usd desc


print 'consulta 11: proveedores a los que les compramos mas de 10 millones en 2026'

select pr.razon_social, pa.nombre as pais, count(*) as compras, sum(g.monto_usd) as total_usd
from Gasto g
inner join Proveedor pr on pr.id_proveedor = g.id_proveedor
inner join Pais pa on pa.id_pais = pr.id_pais
where year(g.fecha) = 2026
group by pr.razon_social, pa.nombre
having sum(g.monto_usd) > 10000000
order by total_usd desc


print 'consulta 12: alertas del tope, con el gasto que las disparo'

select year(g.fecha) as anio, a.fecha as fecha_alerta, g.descripcion, pr.razon_social,
       g.monto_usd, a.gasto_acumulado_usd, t.monto_usd as tope_usd
from AlertaTope a
inner join Gasto g on g.id_gasto = a.id_gasto
inner join Proveedor pr on pr.id_proveedor = g.id_proveedor
inner join TopePresupuestario t on t.anio = year(g.fecha)
order by anio



print 'subconsulta 1: pilotos que no corrieron ningun GP en 2026'

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


print 'subconsulta 2: puntos promedio por fin de semana de cada piloto en 2026'

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


print 'subconsulta 3: cada piloto con su contrato vigente, los GP que corrio y sus puntos'

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


print 'subconsulta 4: empleados que no son pilotos y cobran mas que alguno de los pilotos'

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


print 'subconsulta 5: empleados a los que se les cambio el sueldo en 2026'

select e.apellido, e.nombre, c.sueldo_mensual_usd as sueldo_actual
from Empleado e
inner join Contrato c on c.id_empleado = e.id_empleado
where exists (
    select 1
    from AuditoriaContrato a
    where a.id_contrato = c.id_contrato
      and year(a.fecha) = 2026
)


print 'subconsulta 6: piezas que llevan mas km que el promedio de su tipo'

select c.numero_serie, t.nombre as tipo, c.km_acumulados
from Componente c
inner join TipoComponente t on t.id_tipo = c.id_tipo
where c.km_acumulados > (
    select avg(c2.km_acumulados)
    from Componente c2
    where c2.id_tipo = c.id_tipo
)
order by t.nombre, c.km_acumulados desc


print 'subconsulta 7: la pieza mas gastada de cada tipo'

select t.nombre as tipo, c.numero_serie, c.km_acumulados, c.estado
from Componente c
inner join TipoComponente t on t.id_tipo = c.id_tipo
where c.km_acumulados >= all (
    select c2.km_acumulados
    from Componente c2
    where c2.id_tipo = c.id_tipo
)
order by t.nombre


print 'subconsulta 8: piezas que tienen km de un GP que todavia no se cerro'

select c.numero_serie, c.estado, c.km_acumulados
from Componente c
where c.id_componente in (
    select u.id_componente
    from UsoComponente u
    inner join Inscripcion i on i.id_inscripcion = u.id_inscripcion
    inner join GranPremio g on g.id_gp = i.id_gp
    where g.cerrado = 0
)


print 'subconsulta 9: proveedores a los que no les compramos nada en 2026'

select pr.razon_social, pr.identificacion_fiscal
from Proveedor pr
where pr.id_proveedor not in (
    select g.id_proveedor
    from Gasto g
    where year(g.fecha) = 2026
)
