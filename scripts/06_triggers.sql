use EscuderiaF1
go

create or alter trigger tr_Sesion_validar
on Sesion
after insert, update
as
begin
    set nocount on

    if exists (
        select 1
        from inserted i
        inner join TipoSesion t on t.id_tipo_sesion = i.id_tipo_sesion
        inner join GranPremio g on g.id_gp = i.id_gp
        where t.es_sprint = 1 and g.es_sprint = 0
    )
    begin
        rollback transaction
        raiserror('no se puede cargar una sesion sprint en un Gran Premio sin formato sprint', 16, 1)
        return
    end

    if exists (
        select 1
        from inserted i
        inner join GranPremio g on g.id_gp = i.id_gp
        where cast(i.fecha_hora as date) not between g.fecha_inicio and g.fecha_fin
    )
    begin
        rollback transaction
        raiserror('la fecha de la sesion esta fuera del fin de semana del Gran Premio', 16, 1)
        return
    end
end
go

create or alter trigger tr_Contrato
on Contrato
after insert, update
as
begin
    set nocount on

    if exists (
        select 1
        from inserted i
        inner join Contrato c on c.id_empleado = i.id_empleado and c.id_contrato <> i.id_contrato
        where c.fecha_inicio <= isnull(i.fecha_fin, '9999-12-31')
          and i.fecha_inicio <= isnull(c.fecha_fin, '9999-12-31')
    )
    begin
        rollback transaction
        raiserror('el empleado ya tiene un contrato que se superpone con esas fechas', 16, 1)
        return
    end

    if exists (select 1 from inserted i left join Piloto p on p.id_empleado = i.id_empleado
        where (p.id_empleado is null and i.condicion is not null) or (p.id_empleado is not null and i.condicion is null))
    begin
        rollback transaction
        raiserror('titular o reserva va en los contratos de pilotos y solo en esos', 16, 1)
        return
    end

    insert into AuditoriaContrato (id_contrato, sueldo_anterior, sueldo_nuevo)
    select d.id_contrato, d.sueldo_mensual_usd, i.sueldo_mensual_usd
    from inserted i
    inner join deleted d on d.id_contrato = i.id_contrato
    where i.sueldo_mensual_usd <> d.sueldo_mensual_usd
end
go

create or alter trigger tr_UsoComponente
on UsoComponente
after insert
as
begin
    set nocount on

    if exists (
        select 1
        from inserted i
        inner join Componente c on c.id_componente = i.id_componente
        where c.estado in ('Retirado', 'Danado')
    )
    begin
        rollback transaction
        raiserror('no se puede usar una pieza retirada o danada', 16, 1)
        return
    end

    if exists (
        select 1
        from inserted i
        inner join Inscripcion ins on ins.id_inscripcion = i.id_inscripcion
        inner join GranPremio g on g.id_gp = ins.id_gp
        where g.cerrado = 1
    )
    begin
        rollback transaction
        raiserror('el Gran Premio ya esta cerrado y no acepta mas usos de piezas', 16, 1)
        return
    end

    insert into Penalizacion (id_inscripcion, id_componente, puestos_grilla, motivo)
    select x.id_inscripcion, x.id_componente,
           case when x.usadas = x.cantidad_max + 1 then 10 else 5 end,
           cast(x.usadas as varchar(5)) + ' ' + x.tipo + ' usados en la temporada y el limite es ' + cast(x.cantidad_max as varchar(5))
    from (
        select i.id_inscripcion, i.id_componente, t.nombre as tipo, l.cantidad_max,
               (select count(distinct u.id_componente)
                from UsoComponente u
                inner join Inscripcion i2 on i2.id_inscripcion = u.id_inscripcion
                inner join GranPremio g2 on g2.id_gp = i2.id_gp
                inner join Componente c2 on c2.id_componente = u.id_componente
                where i2.id_piloto = ins.id_piloto and g2.anio = g.anio and c2.id_tipo = c.id_tipo
                and (u.id_componente <= i.id_componente or u.id_componente not in (select id_componente from inserted))) as usadas
        from inserted i
        inner join Inscripcion ins on ins.id_inscripcion = i.id_inscripcion
        inner join GranPremio g on g.id_gp = ins.id_gp
        inner join Componente c on c.id_componente = i.id_componente
        inner join TipoComponente t on t.id_tipo = c.id_tipo
        inner join LimiteComponente l on l.anio = g.anio and l.id_tipo = c.id_tipo
        where (select count(*) from UsoComponente u where u.id_componente = i.id_componente) = 1
    ) x
    where x.usadas > x.cantidad_max
end
go

create or alter trigger tr_Gasto_tope
on Gasto
after insert, update
as
begin
    set nocount on

    if exists (select 1 from inserted where year(fecha) not in (select anio from TopePresupuestario))
    begin
        rollback transaction
        raiserror('no hay tope presupuestario cargado para el anio del gasto', 16, 1)
        return
    end

    if exists (
        select 1
        from inserted i
        inner join Gasto g on g.id_componente = i.id_componente and g.id_gasto <> i.id_gasto
    )
    begin
        rollback transaction
        raiserror('esa pieza ya tiene un gasto de compra', 16, 1)
        return
    end

    if exists (
        select 1
        from TopePresupuestario t
        where t.anio in (select year(fecha) from inserted)
          and dbo.fn_gasto_computable(t.anio) > t.monto_usd
    )
    begin
        rollback transaction
        raiserror('el gasto hace pasar el tope presupuestario del anio', 16, 1)
        return
    end

    insert into AlertaTope (id_gasto, gasto_acumulado_usd)
    select max(i.id_gasto), dbo.fn_gasto_computable(t.anio)
    from inserted i
    inner join TopePresupuestario t on t.anio = year(i.fecha)
    where dbo.fn_gasto_computable(t.anio) >= t.monto_usd * t.umbral_alerta_pct / 100
      and not exists (select 1 from AlertaTope a inner join Gasto g on g.id_gasto = a.id_gasto where year(g.fecha) = t.anio)
    group by t.anio
end
