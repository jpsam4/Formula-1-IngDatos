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
    set xact_abort on

    declare @gpsesion int, @gpinsc int

    begin try
        select @gpsesion = id_gp from Sesion where id_sesion = @idsesion
        select @gpinsc = id_gp from Inscripcion where id_inscripcion = @idinsc

        if @gpsesion is null
            raiserror('la sesion %d no existe', 16, 1, @idsesion)

        if @gpinsc is null
            raiserror('la inscripcion %d no existe', 16, 1, @idinsc)

        if @gpsesion <> @gpinsc
            raiserror('la inscripcion %d no es del Gran Premio de la sesion %d (RN10)', 16, 1, @idinsc, @idsesion)

        if exists (select 1 from Resultado where id_sesion = @idsesion and id_inscripcion = @idinsc)
            raiserror('ese piloto ya tiene un resultado cargado en la sesion %d', 16, 1, @idsesion)

        begin transaction

        insert into Resultado (id_sesion, id_inscripcion, posicion, estado)
        values (@idsesion, @idinsc, @pos, @estado)

        commit transaction

        print 'resultado cargado: sesion ' + cast(@idsesion as varchar(10)) + ', inscripcion ' + cast(@idinsc as varchar(10))
        return 0
    end try
    begin catch
        if xact_state() <> 0
            rollback transaction

        print 'error: ' + error_message()
        return 1
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
    set xact_abort on

    declare @fecha date, @anio smallint, @cerrado bit, @cant int

    begin try
        select @fecha = fecha_inicio, @anio = anio, @cerrado = cerrado
        from GranPremio
        where id_gp = @idgp

        if @fecha is null
            raiserror('el Gran Premio %d no existe', 16, 1, @idgp)

        if @cerrado = 1
            raiserror('el Gran Premio %d ya esta cerrado', 16, 1, @idgp)

        if not exists (select 1 from Piloto where id_empleado = @idpiloto)
            raiserror('el piloto %d no existe', 16, 1, @idpiloto)

        if dbo.fn_contrato_vigente(@idpiloto, @fecha) is null
            raiserror('el piloto %d no tiene contrato vigente en la fecha del Gran Premio (RN04)', 16, 1, @idpiloto)

        select @cant = count(*) from Inscripcion where id_gp = @idgp
        if @cant >= 2
            raiserror('el Gran Premio %d ya tiene dos pilotos inscriptos (RN03)', 16, 1, @idgp)

        if not exists (select 1 from Chasis where id_chasis = @idchasis and anio = @anio)
            raiserror('el chasis %d no existe o no es de la temporada del Gran Premio (RN06)', 16, 1, @idchasis)

        begin transaction

        insert into Inscripcion (id_gp, id_piloto, id_chasis)
        values (@idgp, @idpiloto, @idchasis)

        commit transaction

        print 'piloto ' + cast(@idpiloto as varchar(10)) + ' inscripto en el GP ' + cast(@idgp as varchar(10))
            + ' (inscripcion ' + cast(scope_identity() as varchar(10)) + ')'
        return 0
    end try
    begin catch
        if xact_state() <> 0
            rollback transaction

        print 'error: ' + error_message()
        return 1
    end catch
end
go

create or alter procedure usp_retirar_componente
    @idcomp int,
    @danada bit = 0
as
begin
    set nocount on

    declare @est nvarchar(10)

    select @est = estado from Componente where id_componente = @idcomp

    if @est is null
    begin
        print 'error: la pieza ' + cast(@idcomp as varchar(10)) + ' no existe'
        return 1
    end

    if @est = 'Retirado'
    begin
        print 'error: la pieza ' + cast(@idcomp as varchar(10)) + ' ya estaba retirada'
        return 1
    end

    update Componente
    set estado = case when @danada = 1 then 'Danado' else 'Retirado' end
    where id_componente = @idcomp

    print 'pieza ' + cast(@idcomp as varchar(10)) + ' fuera de servicio (' + case when @danada = 1 then 'danada' else 'retirada' end + ')'
    return 0
end
go

create or alter procedure usp_cerrar_gp
    @idgp int
as
begin
    set nocount on
    set xact_abort on

    declare @idcomp int, @km decimal(10,2), @r int, @retiradas int
    set @retiradas = 0

    begin try
        if not exists (select 1 from GranPremio where id_gp = @idgp)
            raiserror('el Gran Premio %d no existe', 16, 1, @idgp)

        if exists (select 1 from GranPremio where id_gp = @idgp and cerrado = 1)
            raiserror('el Gran Premio %d ya estaba cerrado (RN15)', 16, 1, @idgp)

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

            if exists (select 1
                       from Componente c
                       inner join TipoComponente t on t.id_tipo = c.id_tipo
                       where c.id_componente = @idcomp
                         and c.km_acumulados >= t.vida_util_km
                         and c.estado <> 'Retirado')
            begin
                exec @r = usp_retirar_componente @idcomp = @idcomp

                if @r <> 0
                    raiserror('no se pudo retirar la pieza %d', 16, 1, @idcomp)

                set @retiradas = @retiradas + 1
            end

            fetch next from cur_usos into @idcomp, @km
        end

        close cur_usos
        deallocate cur_usos

        update GranPremio set cerrado = 1 where id_gp = @idgp

        commit transaction

        print 'GP ' + cast(@idgp as varchar(10)) + ' cerrado. piezas retiradas: ' + cast(@retiradas as varchar(10))
        return 0
    end try
    begin catch
        if xact_state() <> 0
            rollback transaction

        print 'error: ' + error_message()
        return 1
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

    declare @idcomp int

    begin try
        if @monto is null or @monto <= 0
            raiserror('el monto de la compra tiene que ser mayor a 0', 16, 1)

        if not exists (select 1 from TipoComponente where id_tipo = @idtipo)
            raiserror('el tipo de pieza %d no existe', 16, 1, @idtipo)

        if not exists (select 1 from CategoriaGasto where id_categoria = @idcat)
            raiserror('la categoria %d no existe', 16, 1, @idcat)

        if not exists (select 1 from Proveedor where id_proveedor = @idprov)
            raiserror('el proveedor %d no existe', 16, 1, @idprov)

        begin transaction

        insert into Componente (id_tipo, numero_serie)
        values (@idtipo, @serie)

        set @idcomp = scope_identity()

        insert into Gasto (fecha, monto_usd, descripcion, id_categoria, id_proveedor, id_componente)
        values (@fecha, @monto, @descr, @idcat, @idprov, @idcomp)

        commit transaction

        print 'compra registrada: pieza ' + @serie + ' (id ' + cast(@idcomp as varchar(10)) + '), gasto ' + cast(scope_identity() as varchar(10))
        return 0
    end try
    begin catch
        if xact_state() <> 0
            rollback transaction

        print 'error: ' + error_message()
        return 1
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
    set xact_abort on

    begin try
        if @monto is null or @monto <= 0
            raiserror('el monto del gasto tiene que ser mayor a 0', 16, 1)

        if not exists (select 1 from CategoriaGasto where id_categoria = @idcat)
            raiserror('la categoria %d no existe', 16, 1, @idcat)

        if not exists (select 1 from Proveedor where id_proveedor = @idprov)
            raiserror('el proveedor %d no existe', 16, 1, @idprov)

        begin transaction

        insert into Gasto (fecha, monto_usd, descripcion, id_categoria, id_proveedor)
        values (@fecha, @monto, @descr, @idcat, @idprov)

        commit transaction

        print 'gasto registrado (id ' + cast(scope_identity() as varchar(10)) + ')'
        return 0
    end try
    begin catch
        if xact_state() <> 0
            rollback transaction

        print 'error: ' + error_message()
        return 1
    end catch
end
