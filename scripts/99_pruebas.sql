use EscuderiaF1

declare @inscver int, @inschad int, @r int


print '===== 1. funciones'

select dbo.fn_puntos_piloto(1, 2026) as puntos_verstappen,
       dbo.fn_puntos_piloto(2, 2026) as puntos_hadjar,
       dbo.fn_puntos_piloto(3, 2026) as puntos_tsunoda

select dbo.fn_contrato_vigente(3, '2025-06-01') as tsunoda_2025,
       dbo.fn_contrato_vigente(3, '2026-06-01') as tsunoda_2026,
       dbo.fn_contrato_vigente(4, '2026-06-01') as ferraro_2026

select dbo.fn_km_restantes(9) as km_restantes_gbx_26_01, dbo.fn_gasto_computable(2026) as gasto_computable_2026

select * from dbo.fn_piezas_piloto(1, 2026)


print '===== 2. vistas'

select * from vw_puntos_equipo_por_gp
select * from vw_nomina
select * from vw_estado_piezas order by km_restantes
select * from vw_situacion_tope


print '===== 3. cierre del GP de Monaco con el cursor (RN14)'

select id_componente, numero_serie, km_acumulados, estado
from Componente
where id_componente in (2, 4, 8, 9, 11, 12, 14, 15)

exec usp_cerrar_gp @idgp = 6

select id_componente, numero_serie, km_acumulados, estado
from Componente
where id_componente in (2, 4, 8, 9, 11, 12, 14, 15)

print '--- esperado: error, ya estaba cerrado (RN15)'
exec usp_cerrar_gp @idgp = 6

print '--- esperado: error, no existe'
exec usp_cerrar_gp @idgp = 99


print '===== 4. inscripciones en el GP de Barcelona'

print '--- esperado: error, Ferraro no tiene contrato vigente (RN04)'
exec usp_inscribir_piloto @idgp = 7, @idpiloto = 4, @idchasis = 5

print '--- esperado: error, el chasis es de 2025 (RN06)'
exec usp_inscribir_piloto @idgp = 7, @idpiloto = 1, @idchasis = 1

print '--- esperado: error, el piloto no existe'
exec usp_inscribir_piloto @idgp = 7, @idpiloto = 99, @idchasis = 3

print '--- esperado: error, el GP de Monaco ya esta cerrado'
exec usp_inscribir_piloto @idgp = 6, @idpiloto = 3, @idchasis = 5

print '--- esperado: bien'
exec usp_inscribir_piloto @idgp = 7, @idpiloto = 1, @idchasis = 3

print '--- esperado: error, mismo chasis para dos pilotos (RN05, UNIQUE)'
exec usp_inscribir_piloto @idgp = 7, @idpiloto = 2, @idchasis = 3

print '--- esperado: bien'
exec usp_inscribir_piloto @idgp = 7, @idpiloto = 2, @idchasis = 4

print '--- esperado: error, ya hay dos pilotos (RN03)'
exec usp_inscribir_piloto @idgp = 7, @idpiloto = 3, @idchasis = 5

select @inscver = id_inscripcion from Inscripcion where id_gp = 7 and id_piloto = 1
select @inschad = id_inscripcion from Inscripcion where id_gp = 7 and id_piloto = 2

select * from Inscripcion where id_gp = 7


print '===== 5. resultados'

print '--- esperado: bien'
exec usp_cargar_resultado @idsesion = 33, @idinsc = @inscver, @pos = 1

print '--- esperado: error, posicion repetida en la sesion (RN11)'
exec usp_cargar_resultado @idsesion = 33, @idinsc = @inschad, @pos = 1

print '--- esperado: error, Finalizo sin posicion (RN11, CHECK)'
exec usp_cargar_resultado @idsesion = 33, @idinsc = @inschad, @pos = null, @estado = 'Finalizo'

print '--- esperado: error, la inscripcion es de otro GP (RN10)'
exec usp_cargar_resultado @idsesion = 33, @idinsc = 11, @pos = 3

print '--- esperado: error, la sesion no existe'
exec usp_cargar_resultado @idsesion = 999, @idinsc = @inschad, @pos = 3

print '--- esperado: bien'
exec usp_cargar_resultado @idsesion = 33, @idinsc = @inschad, @pos = 4

print '--- esperado: error, ya tiene resultado'
exec usp_cargar_resultado @idsesion = 33, @idinsc = @inscver, @pos = 2

select * from Resultado where id_sesion = 33


print '===== 6. sesiones'

print '--- esperado: error, sprint en un GP sin sprint (RN01)'
begin try
    insert into Sesion (id_gp, id_tipo_sesion, fecha_hora) values (7, 5, '2026-06-13 11:00')
    print 'MAL: se acepto la sesion'
end try
begin catch
    print 'error esperado: ' + error_message()
end catch

print '--- esperado: error, fecha fuera del fin de semana (RN02)'
begin try
    insert into Sesion (id_gp, id_tipo_sesion, fecha_hora) values (7, 3, '2026-06-20 12:30')
    print 'MAL: se acepto la sesion'
end try
begin catch
    print 'error esperado: ' + error_message()
end catch

print '--- esperado: bien'
insert into Sesion (id_gp, id_tipo_sesion, fecha_hora) values (7, 3, '2026-06-13 12:30')

select * from Sesion where id_gp = 7


print '===== 7. uso de piezas y penalizaciones (RN13, RN15, RN16)'

select * from dbo.fn_piezas_piloto(2, 2026)

print '--- esperado: bien, Hadjar llega justo al limite de MGU-K (3 de 3), sin penalizacion'
insert into UsoComponente (id_componente, id_inscripcion, km_recorridos) values
(11, @inschad, 640), (12, @inschad, 640), (15, @inschad, 640), (17, @inschad, 210)

select * from Penalizacion

print '--- esperado: bien, dos MGU-K nuevos en el mismo insert: 10 puestos y 5 puestos'
insert into UsoComponente (id_componente, id_inscripcion, km_recorridos) values
(18, @inschad, 190), (19, @inschad, 240)

select * from Penalizacion
select * from dbo.fn_piezas_piloto(2, 2026)

print '--- esperado: error, la caja GBX-26-01 se retiro al cerrar Monaco (RN16)'
begin try
    insert into UsoComponente (id_componente, id_inscripcion, km_recorridos) values (9, @inscver, 0)
    print 'MAL: se acepto la pieza retirada'
end try
begin catch
    print 'error esperado: ' + error_message()
end catch

print '--- esperado: error, el GP de Monaco ya esta cerrado (RN15)'
begin try
    insert into UsoComponente (id_componente, id_inscripcion, km_recorridos) values (16, 11, 50)
    print 'MAL: se acepto el uso'
end try
begin catch
    print 'error esperado: ' + error_message()
end catch

print '--- esperado: bien, Verstappen arranca Barcelona con caja nueva'
insert into UsoComponente (id_componente, id_inscripcion, km_recorridos) values
(2, @inscver, 650), (4, @inscver, 650), (8, @inscver, 650), (20, @inscver, 650)


print '===== 8. compras, gastos y tope (RN17, RN18, RN19, RN20)'

select * from vw_situacion_tope where anio = 2026

print '--- esperado: bien, sin alerta (queda abajo del 90%)'
exec usp_registrar_compra @idtipo = 3, @serie = 'MGUK-26-10', @fecha = '2026-06-10', @monto = 900000,
     @descr = 'MGU-K MGUK-26-10', @idcat = 1, @idprov = 4

print '--- esperado: bien y con alerta, cruza el 90%'
exec usp_registrar_compra @idtipo = 1, @serie = 'ICE-26-06', @fecha = '2026-06-11', @monto = 1800000,
     @descr = 'Motor de combustion ICE-26-06', @idcat = 1, @idprov = 5

select * from AlertaTope
select * from vw_situacion_tope where anio = 2026

print '--- esperado: error, pasa el tope. la pieza tampoco tiene que quedar creada'
exec usp_registrar_compra @idtipo = 4, @serie = 'GBX-26-04', @fecha = '2026-06-12', @monto = 25000000,
     @descr = 'Caja de cambios GBX-26-04', @idcat = 1, @idprov = 2

select count(*) as piezas_gbx_26_04 from Componente where numero_serie = 'GBX-26-04'

print '--- esperado: error, monto negativo'
exec usp_registrar_compra @idtipo = 4, @serie = 'GBX-26-05', @fecha = '2026-06-12', @monto = -10,
     @descr = 'prueba', @idcat = 1, @idprov = 2

print '--- esperado: error, numero de serie repetido (UNIQUE)'
exec usp_registrar_compra @idtipo = 1, @serie = 'ICE-26-01', @fecha = '2026-06-12', @monto = 1800000,
     @descr = 'prueba', @idcat = 1, @idprov = 5

print '--- esperado: error, proveedor inexistente'
exec usp_registrar_gasto @fecha = '2026-06-12', @monto = 1000, @descr = 'prueba', @idcat = 4, @idprov = 99

print '--- esperado: error, 2027 no tiene tope cargado (RN19)'
exec usp_registrar_gasto @fecha = '2027-01-10', @monto = 1000, @descr = 'Flete de pretemporada', @idcat = 4, @idprov = 3

print '--- esperado: bien, hospitalidad no cuenta para el tope (RN18)'
exec usp_registrar_gasto @fecha = '2026-06-12', @monto = 2500000, @descr = 'Hospitalidad en Barcelona', @idcat = 5, @idprov = 7

print '--- esperado: error, una pieza con dos gastos de compra (RN17)'
begin try
    insert into Gasto (fecha, monto_usd, descripcion, id_categoria, id_proveedor, id_componente)
    values ('2026-06-12', 100, 'segunda compra de la misma pieza', 1, 5, 1)
    print 'MAL: se acepto el gasto'
end try
begin catch
    print 'error esperado: ' + error_message()
end catch

select * from vw_situacion_tope


print '===== 9. contratos y auditoria (RN07, RN08, RN09)'

print '--- esperado: error, contrato superpuesto (RN07)'
begin try
    insert into Contrato (id_empleado, fecha_inicio, fecha_fin, sueldo_mensual_usd, condicion)
    values (1, '2027-01-01', '2029-12-31', 5000000, 'Titular')
    print 'MAL: se acepto el contrato'
end try
begin catch
    print 'error esperado: ' + error_message()
end catch

print '--- esperado: error, titular/reserva en el contrato de un mecanico (RN08)'
begin try
    insert into Contrato (id_empleado, fecha_inicio, fecha_fin, sueldo_mensual_usd, condicion)
    values (13, '2026-07-01', null, 8500, 'Titular')
    print 'MAL: se acepto el contrato'
end try
begin catch
    print 'error esperado: ' + error_message()
end catch

print '--- esperado: error, contrato de piloto sin titular/reserva (RN08)'
begin try
    insert into Contrato (id_empleado, fecha_inicio, fecha_fin, sueldo_mensual_usd, condicion)
    values (4, '2027-01-01', '2027-12-31', 15000, null)
    print 'MAL: se acepto el contrato'
end try
begin catch
    print 'error esperado: ' + error_message()
end catch

print '--- esperado: bien, vuelve Walker'
insert into Contrato (id_empleado, fecha_inicio, fecha_fin, sueldo_mensual_usd, condicion)
values (13, '2026-07-01', null, 8500, null)

print '--- esperado: bien, aumentos y cada cambio queda en la auditoria'
update Contrato set sueldo_mensual_usd = 250000 where id_contrato = 2
update Contrato set sueldo_mensual_usd = sueldo_mensual_usd * 1.05 where id_empleado in (11, 12)

select * from AuditoriaContrato


print '===== 10. seguridad'

execute as user = 'usr_director'
    print 'usuario: ' + user_name()

    print '--- esperado: error, no puede escribir Resultado directo (RN22)'
    begin try
        insert into Resultado (id_sesion, id_inscripcion, posicion, estado) values (34, @inscver, 1, 'Finalizo')
        print 'MAL: pudo escribir'
    end try
    begin catch
        print 'error esperado: ' + error_message()
    end catch

    print '--- esperado: bien, por el procedimiento si puede'
    exec usp_cargar_resultado @idsesion = 34, @idinsc = @inscver, @pos = 1

    print '--- esperado: error, no ve sueldos (RN21)'
    begin try
        select id_contrato, sueldo_mensual_usd from Contrato
        print 'MAL: vio los sueldos'
    end try
    begin catch
        print 'error esperado: ' + error_message()
    end catch

    print '--- esperado: bien, la nomina sin sueldos'
    select top 3 * from vw_nomina

    print '--- esperado: error, no puede marcar un GP como cerrado'
    begin try
        update GranPremio set cerrado = 1 where id_gp = 7
        print 'MAL: pudo cerrar el GP'
    end try
    begin catch
        print 'error esperado: ' + error_message()
    end catch
revert

execute as user = 'usr_ingeniero'
    print 'usuario: ' + user_name()

    print '--- esperado: error, no puede tocar los km a mano'
    begin try
        update Componente set km_acumulados = 0 where id_componente = 1
        print 'MAL: pudo cambiar los km'
    end try
    begin catch
        print 'error esperado: ' + error_message()
    end catch

    print '--- esperado: bien, carga el uso directo y el trigger controla'
    insert into UsoComponente (id_componente, id_inscripcion, km_recorridos) values (16, @inscver, 120)
    print '--- esperado: bien, cierra Barcelona'
    exec usp_cerrar_gp @idgp = 7
revert

execute as user = 'usr_rrhh'
    print 'usuario: ' + user_name()

    print '--- esperado: bien, el aumento queda auditado con su usuario'
    update Contrato set sueldo_mensual_usd = 9800 where id_contrato = 13

    print '--- esperado: error, la auditoria no se puede borrar'
    begin try
        delete from AuditoriaContrato
        print 'MAL: borro la auditoria'
    end try
    begin catch
        print 'error esperado: ' + error_message()
    end catch
revert

select * from AuditoriaContrato

execute as user = 'usr_finanzas'
    print 'usuario: ' + user_name()

    print '--- esperado: error, no puede insertar gastos directo (RN22)'
    begin try
        insert into Gasto (fecha, monto_usd, descripcion, id_categoria, id_proveedor) values ('2026-06-15', 1000, 'directo', 4, 3)
        print 'MAL: pudo insertar'
    end try
    begin catch
        print 'error esperado: ' + error_message()
    end catch

    print '--- esperado: bien, por el procedimiento'
    exec usp_registrar_gasto @fecha = '2026-06-15', @monto = 1000, @descr = 'Envio de documentacion', @idcat = 4, @idprov = 3

    print '--- esperado: error, no ve sueldos'
    begin try
        select sueldo_mensual_usd from Contrato
        print 'MAL: vio los sueldos'
    end try
    begin catch
        print 'error esperado: ' + error_message()
    end catch
revert

execute as user = 'usr_consulta'
    print 'usuario: ' + user_name()

    print '--- esperado: bien'
    select * from vw_puntos_equipo_por_gp

    print '--- esperado: error, no ve montos'
    begin try
        select * from vw_situacion_tope
        print 'MAL: vio los montos'
    end try
    begin catch
        print 'error esperado: ' + error_message()
    end catch
revert


print '===== 11. control final: los km guardados tienen que coincidir con los usos (no deberia devolver filas)'

select c.id_componente, c.km_acumulados, sum(u.km_recorridos) as km_calculados
from Componente c
inner join UsoComponente u on u.id_componente = c.id_componente
inner join Inscripcion i on i.id_inscripcion = u.id_inscripcion
inner join GranPremio g on g.id_gp = i.id_gp
where g.cerrado = 1
group by c.id_componente, c.km_acumulados
having c.km_acumulados <> sum(u.km_recorridos)

select * from vw_estado_piezas order by tipo, numero_serie
select * from vw_puntos_equipo_por_gp
