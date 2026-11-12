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
        raiserror('no se puede cargar una sesion sprint en un Gran Premio sin formato sprint (RN01)', 16, 1)
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
        raiserror('la fecha de la sesion esta fuera del fin de semana del Gran Premio (RN02)', 16, 1)
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
        inner join Contrato c on c.id_empleado = i.id_empleado
                             and c.id_contrato <> i.id_contrato
        where c.fecha_inicio <= isnull(i.fecha_fin, '9999-12-31')
          and i.fecha_inicio <= isnull(c.fecha_fin, '9999-12-31')
    )
    begin
        rollback transaction
        raiserror('el empleado ya tiene un contrato que se superpone con esas fechas (RN07)', 16, 1)
        return
    end

    if exists (select 1 from inserted i
               where i.condicion is not null
                 and not exists (select 1 from Piloto p where p.id_empleado = i.id_empleado))
    begin
        rollback transaction
        raiserror('solo el contrato de un piloto dice si es titular o reserva (RN08)', 16, 1)
        return
    end

    if exists (select 1 from inserted i
               inner join Piloto p on p.id_empleado = i.id_empleado
               where i.condicion is null)
    begin
        rollback transaction
        raiserror('el contrato de un piloto tiene que decir si es titular o reserva (RN08)', 16, 1)
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

    if exists (select 1
               from inserted i
               inner join Componente c on c.id_componente = i.id_componente
               where c.estado in ('Retirado', 'Danado'))
    begin
        rollback transaction
        raiserror('no se puede usar una pieza retirada o danada (RN16)', 16, 1)
        return
    end

    if exists (select 1
               from inserted i
               inner join Inscripcion ins on ins.id_inscripcion = i.id_inscripcion
               inner join GranPremio g on g.id_gp = ins.id_gp
               where g.cerrado = 1)
    begin
        rollback transaction
        raiserror('el Gran Premio ya esta cerrado y no acepta mas usos de piezas (RN15)', 16, 1)
        return
    end

    ;with nuevas as (
        select i.id_componente, min(i.id_inscripcion) as id_inscripcion
        from inserted i
        where not exists (select 1
                          from UsoComponente u
                          where u.id_componente = i.id_componente
                            and u.id_inscripcion not in (select x.id_inscripcion from inserted x
                                                         where x.id_componente = u.id_componente))
        group by i.id_componente
    ),
    datos as (
        select n.id_componente, n.id_inscripcion, ins.id_piloto, g.anio, c.id_tipo,
               t.nombre as tipo, l.cantidad_max,
               row_number() over (partition by ins.id_piloto, g.anio, c.id_tipo
                                  order by n.id_inscripcion, n.id_componente) as orden
        from nuevas n
        inner join Inscripcion ins on ins.id_inscripcion = n.id_inscripcion
        inner join GranPremio g on g.id_gp = ins.id_gp
        inner join Componente c on c.id_componente = n.id_componente
        inner join TipoComponente t on t.id_tipo = c.id_tipo
        inner join LimiteComponente l on l.anio = g.anio and l.id_tipo = c.id_tipo
    ),
    cuenta as (
        select d.*,
               (select count(distinct u.id_componente)
                from UsoComponente u
                inner join Inscripcion i2 on i2.id_inscripcion = u.id_inscripcion
                inner join GranPremio g2 on g2.id_gp = i2.id_gp
                inner join Componente c2 on c2.id_componente = u.id_componente
                where i2.id_piloto = d.id_piloto
                  and g2.anio = d.anio
                  and c2.id_tipo = d.id_tipo
                  and u.id_componente not in (select id_componente from nuevas)) + d.orden as numero
        from datos d
    )
    insert into Penalizacion (id_inscripcion, id_componente, puestos_grilla, motivo)
    select id_inscripcion, id_componente,
           case when numero = cantidad_max + 1 then 10 else 5 end,
           cast(numero as varchar(5)) + ' ' + tipo + ' usados en la temporada y el limite es ' + cast(cantidad_max as varchar(5))
    from cuenta
    where numero > cantidad_max
end
go

create or alter trigger tr_Gasto_tope
on Gasto
after insert, update
as
begin
    set nocount on

    if exists (select 1 from inserted i
               where not exists (select 1 from TopePresupuestario t where t.anio = year(i.fecha)))
    begin
        rollback transaction
        raiserror('no hay tope presupuestario cargado para el anio del gasto (RN19)', 16, 1)
        return
    end

    if exists (select 1
               from TopePresupuestario t
               where t.anio in (select year(fecha) from inserted)
                 and dbo.fn_gasto_computable(t.anio) > t.monto_usd)
    begin
        rollback transaction
        raiserror('el gasto hace pasar el tope presupuestario del anio (RN19)', 16, 1)
        return
    end

    if not exists (select 1 from deleted)
    begin
        insert into AlertaTope (id_gasto, gasto_acumulado_usd)
        select x.id_gasto, x.acumulado
        from (
            select i.id_gasto, i.monto_usd,
                   t.monto_usd * t.umbral_alerta_pct / 100 as limite,
                   dbo.fn_gasto_computable(t.anio)
                     - sum(i.monto_usd) over (partition by t.anio)
                     + sum(i.monto_usd) over (partition by t.anio order by i.id_gasto rows unbounded preceding) as acumulado
            from inserted i
            inner join CategoriaGasto c on c.id_categoria = i.id_categoria
            inner join TopePresupuestario t on t.anio = year(i.fecha)
            where c.computa_tope = 1
        ) x
        where x.acumulado >= x.limite
          and x.acumulado - x.monto_usd < x.limite
    end
end
