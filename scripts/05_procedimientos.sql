use EscuderiaF1
go

create or alter procedure usp_cargar_resultado
    @idsesion int,
    @idinsc int,
    @pos tinyint = null,
    @estado nvarchar(15) = 'Finalizo'
as
begin
    set nocount on

    declare @gpsesion int, @gpinsc int

    begin try
        select @gpsesion = id_gp from Sesion where id_sesion = @idsesion
        select @gpinsc = id_gp from Inscripcion where id_inscripcion = @idinsc

        if @gpsesion <> @gpinsc
            raiserror('la inscripcion no es del mismo Gran Premio que la sesion', 16, 1)

        if exists (select 1 from Resultado where id_sesion = @idsesion and posicion = @pos)
            raiserror('esa posicion ya la tiene otro piloto en la sesion', 16, 1)

        insert into Resultado (id_sesion, id_inscripcion, posicion, estado)
        values (@idsesion, @idinsc, @pos, @estado)

        print 'resultado cargado'
    end try
    begin catch
        print 'error: ' + error_message()
    end catch
end
go

create or alter procedure usp_inscribir_piloto
    @idgp int,
    @idpiloto int,
    @idchasis int
as
begin
    set nocount on

    declare @fecha date, @anio smallint

    begin try
        select @fecha = fecha_inicio, @anio = anio from GranPremio where id_gp = @idgp

        if @fecha is null
            raiserror('el Gran Premio no existe', 16, 1)

        if dbo.fn_contrato_vigente(@idpiloto, @fecha) is null
            raiserror('el piloto no tiene contrato vigente en la fecha del Gran Premio', 16, 1)

        if (select count(*) from Inscripcion where id_gp = @idgp) >= 2
            raiserror('el Gran Premio ya tiene dos pilotos inscriptos', 16, 1)

        if not exists (select 1 from Chasis where id_chasis = @idchasis and anio = @anio)
            raiserror('el chasis no existe o no es de la temporada del Gran Premio', 16, 1)

        insert into Inscripcion (id_gp, id_piloto, id_chasis)
        values (@idgp, @idpiloto, @idchasis)

        print 'piloto inscripto'
    end try
    begin catch
        print 'error: ' + error_message()
    end catch
end
go

create or alter procedure usp_retirar_componente
    @idcomp int,
    @danada bit = 0
as
begin
    set nocount on

    if not exists (select 1 from Componente where id_componente = @idcomp and estado <> 'Retirado')
    begin
        print 'error: la pieza no existe o ya estaba retirada'
        return
    end

    update Componente
    set estado = case when @danada = 1 then 'Danado' else 'Retirado' end
    where id_componente = @idcomp

    print 'pieza ' + cast(@idcomp as varchar(10)) + ' fuera de servicio'
end
go

create or alter procedure usp_cerrar_gp
    @idgp int
as
begin
    set nocount on
    set xact_abort on

    declare @idcomp int, @km decimal(10,2)

    begin try
        if not exists (select 1 from GranPremio where id_gp = @idgp and cerrado = 0)
            raiserror('el Gran Premio no existe o ya estaba cerrado', 16, 1)

        begin transaction

        declare cur_usos cursor local fast_forward for
            select u.id_componente, u.km_recorridos
            from UsoComponente u
            inner join Inscripcion i on i.id_inscripcion = u.id_inscripcion
            where i.id_gp = @idgp

        open cur_usos
        fetch next from cur_usos into @idcomp, @km

        while @@fetch_status = 0
        begin
            update Componente
            set km_acumulados = km_acumulados + @km,
                estado = case when estado = 'Nuevo' then 'En uso' else estado end
            where id_componente = @idcomp

            if exists (select 1 from Componente c inner join TipoComponente t on t.id_tipo = c.id_tipo
                       where c.id_componente = @idcomp and c.km_acumulados >= t.vida_util_km and c.estado <> 'Retirado')
                exec usp_retirar_componente @idcomp = @idcomp

            fetch next from cur_usos into @idcomp, @km
        end

        close cur_usos
        deallocate cur_usos

        update GranPremio set cerrado = 1 where id_gp = @idgp

        commit transaction

        print 'GP ' + cast(@idgp as varchar(10)) + ' cerrado'
    end try
    begin catch
        if xact_state() <> 0
            rollback transaction

        print 'error: ' + error_message()
    end catch
end
go

create or alter procedure usp_registrar_compra
    @idtipo int,
    @serie nvarchar(30),
    @fecha date,
    @monto decimal(14,2),
    @descr nvarchar(200),
    @idcat int,
    @idprov int
as
begin
    set nocount on
    set xact_abort on

    begin try
        begin transaction

        insert into Componente (id_tipo, numero_serie)
        values (@idtipo, @serie)

        insert into Gasto (fecha, monto_usd, descripcion, id_categoria, id_proveedor, id_componente)
        values (@fecha, @monto, @descr, @idcat, @idprov, @@identity)

        commit transaction

        print 'compra registrada: pieza ' + @serie
    end try
    begin catch
        if xact_state() <> 0
            rollback transaction

        print 'error: ' + error_message()
    end catch
end
go

create or alter procedure usp_registrar_gasto
    @fecha date,
    @monto decimal(14,2),
    @descr nvarchar(200),
    @idcat int,
    @idprov int
as
begin
    set nocount on

    begin try
        insert into Gasto (fecha, monto_usd, descripcion, id_categoria, id_proveedor)
        values (@fecha, @monto, @descr, @idcat, @idprov)

        print 'gasto registrado'
    end try
    begin catch
        print 'error: ' + error_message()
    end catch
end
