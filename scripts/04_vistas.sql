use EscuderiaF1
go

create or alter view vw_puntos_equipo_por_gp
as
select x.anio, x.ronda, x.gran_premio, x.puntos,
       sum(x.puntos) over (partition by x.anio order by x.ronda) as acumulado
from (
    select g.anio, g.ronda, g.nombre as gran_premio, isnull(sum(p.puntos), 0) as puntos
    from GranPremio g
    inner join Sesion s on s.id_gp = g.id_gp
    inner join Resultado r on r.id_sesion = s.id_sesion
    left join Puntaje p on p.anio = g.anio
                       and p.id_tipo_sesion = s.id_tipo_sesion
                       and p.posicion = r.posicion
    group by g.anio, g.ronda, g.nombre
) x
go

create or alter view vw_nomina
as
select e.id_empleado, e.apellido, e.nombre,
       p.nombre as puesto, p.departamento,
       pa.nombre as nacionalidad,
       c.fecha_inicio as contrato_desde,
       c.fecha_fin as contrato_hasta,
       c.condicion
from Empleado e
inner join Puesto p on p.id_puesto = e.id_puesto
inner join Pais pa on pa.id_pais = e.id_pais
inner join Contrato c on c.id_contrato = dbo.fn_contrato_vigente(e.id_empleado, cast(getdate() as date))
go

create or alter view vw_estado_piezas
as
select c.id_componente, c.numero_serie, t.nombre as tipo, c.estado,
       c.km_acumulados, t.vida_util_km,
       dbo.fn_km_restantes(c.id_componente) as km_restantes,
       cast(c.km_acumulados * 100 / t.vida_util_km as decimal(5,1)) as pct_usado,
       (select top 1 e.apellido
        from UsoComponente u
        inner join Inscripcion i on i.id_inscripcion = u.id_inscripcion
        inner join Empleado e on e.id_empleado = i.id_piloto
        where u.id_componente = c.id_componente
        order by i.id_inscripcion desc) as ultimo_piloto
from Componente c
inner join TipoComponente t on t.id_tipo = c.id_tipo
go

create or alter view vw_situacion_tope
as
select t.anio,
       t.monto_usd as tope_usd,
       dbo.fn_gasto_computable(t.anio) as gastado_usd,
       t.monto_usd - dbo.fn_gasto_computable(t.anio) as disponible_usd,
       cast(dbo.fn_gasto_computable(t.anio) * 100 / t.monto_usd as decimal(5,2)) as pct_usado,
       t.umbral_alerta_pct,
       (select count(*)
        from AlertaTope a
        inner join Gasto g on g.id_gasto = a.id_gasto
        where year(g.fecha) = t.anio) as alertas
from TopePresupuestario t
