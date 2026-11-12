use EscuderiaF1
go

create or alter function dbo.fn_puntos_piloto (@idpiloto int, @anio smallint)
returns int
as
begin
    declare @pts int

    select @pts = sum(p.puntos)
    from Resultado r
    inner join Sesion s on s.id_sesion = r.id_sesion
    inner join GranPremio g on g.id_gp = s.id_gp
    inner join Inscripcion i on i.id_inscripcion = r.id_inscripcion
    inner join Puntaje p on p.anio = g.anio and p.id_tipo_sesion = s.id_tipo_sesion and p.posicion = r.posicion
    where i.id_piloto = @idpiloto
      and g.anio = @anio

    return isnull(@pts, 0)
end
go

create or alter function dbo.fn_contrato_vigente (@idemp int, @fecha date)
returns int
as
begin
    declare @idc int

    select @idc = id_contrato
    from Contrato
    where id_empleado = @idemp
      and fecha_inicio <= @fecha
      and (fecha_fin is null or fecha_fin >= @fecha)

    return @idc
end
go

create or alter function dbo.fn_km_restantes (@idcomp int)
returns decimal(10,2)
as
begin
    declare @resto decimal(10,2)

    select @resto = t.vida_util_km - c.km_acumulados
    from Componente c
    inner join TipoComponente t on t.id_tipo = c.id_tipo
    where c.id_componente = @idcomp

    if @resto < 0
        set @resto = 0

    return @resto
end
go

create or alter function dbo.fn_gasto_computable (@anio smallint)
returns decimal(14,2)
as
begin
    return (
        select isnull(sum(g.monto_usd), 0)
        from Gasto g
        inner join CategoriaGasto c on c.id_categoria = g.id_categoria
        where c.computa_tope = 1
          and year(g.fecha) = @anio
    )
end
go

create or alter function dbo.fn_piezas_piloto (@idpiloto int, @anio smallint)
returns table
as
return (
    select t.nombre as tipo,
           l.cantidad_max as limite,
           isnull(x.usadas, 0) as usadas,
           l.cantidad_max - isnull(x.usadas, 0) as disponibles
    from LimiteComponente l
    inner join TipoComponente t on t.id_tipo = l.id_tipo
    left join (
        select c.id_tipo, count(distinct u.id_componente) as usadas
        from UsoComponente u
        inner join Componente c on c.id_componente = u.id_componente
        inner join Inscripcion i on i.id_inscripcion = u.id_inscripcion
        inner join GranPremio g on g.id_gp = i.id_gp
        where i.id_piloto = @idpiloto
          and g.anio = @anio
        group by c.id_tipo
    ) x on x.id_tipo = l.id_tipo
    where l.anio = @anio
)
