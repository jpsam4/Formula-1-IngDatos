use master

if exists (select * from syslogins where name = 'login_director') drop login login_director
if exists (select * from syslogins where name = 'login_ingeniero') drop login login_ingeniero
if exists (select * from syslogins where name = 'login_rrhh') drop login login_rrhh
if exists (select * from syslogins where name = 'login_finanzas') drop login login_finanzas
if exists (select * from syslogins where name = 'login_consulta') drop login login_consulta

create login login_director with password = 'Rbr-Director-2026'
create login login_ingeniero with password = 'Rbr-Ingeniero-2026'
create login login_rrhh with password = 'Rbr-Rrhh-2026'
create login login_finanzas with password = 'Rbr-Finanzas-2026'
create login login_consulta with password = 'Rbr-Consulta-2026'

use EscuderiaF1

create user usr_director for login login_director
create user usr_ingeniero for login login_ingeniero
create user usr_rrhh for login login_rrhh
create user usr_finanzas for login login_finanzas
create user usr_consulta for login login_consulta

create role rol_director_deportivo
create role rol_ingeniero_pista
create role rol_rrhh
create role rol_finanzas
create role rol_consulta

alter role rol_director_deportivo add member usr_director
alter role rol_ingeniero_pista add member usr_ingeniero
alter role rol_rrhh add member usr_rrhh
alter role rol_finanzas add member usr_finanzas
alter role rol_consulta add member usr_consulta


grant select on Pais to rol_director_deportivo
grant select on Temporada to rol_director_deportivo
grant select on Circuito to rol_director_deportivo
grant select on TipoSesion to rol_director_deportivo
grant select on Puntaje to rol_director_deportivo
grant select on Piloto to rol_director_deportivo
grant select on Chasis to rol_director_deportivo
grant select on Resultado to rol_director_deportivo
grant select on Inscripcion to rol_director_deportivo
grant select, insert, update on Sesion to rol_director_deportivo
grant select, insert on GranPremio to rol_director_deportivo
grant select on vw_puntos_equipo_por_gp to rol_director_deportivo
grant select on vw_nomina to rol_director_deportivo
grant select on vw_estado_piezas to rol_director_deportivo
grant execute on usp_cargar_resultado to rol_director_deportivo
grant execute on usp_inscribir_piloto to rol_director_deportivo
grant execute on dbo.fn_puntos_piloto to rol_director_deportivo
deny update, delete on GranPremio to rol_director_deportivo
deny insert, update, delete on Resultado to rol_director_deportivo
deny insert, update, delete on Inscripcion to rol_director_deportivo
deny select on Contrato to rol_director_deportivo
deny select on AuditoriaContrato to rol_director_deportivo
deny select on Gasto to rol_director_deportivo


grant select on GranPremio to rol_ingeniero_pista
grant select on Inscripcion to rol_ingeniero_pista
grant select on Chasis to rol_ingeniero_pista
grant select on TipoComponente to rol_ingeniero_pista
grant select on LimiteComponente to rol_ingeniero_pista
grant select on Componente to rol_ingeniero_pista
grant select on Penalizacion to rol_ingeniero_pista
grant select, insert on UsoComponente to rol_ingeniero_pista
grant select on vw_estado_piezas to rol_ingeniero_pista
grant select on dbo.fn_piezas_piloto to rol_ingeniero_pista
grant execute on dbo.fn_km_restantes to rol_ingeniero_pista
grant execute on usp_cerrar_gp to rol_ingeniero_pista
grant execute on usp_retirar_componente to rol_ingeniero_pista
deny update, delete on UsoComponente to rol_ingeniero_pista
deny insert, update, delete on Componente to rol_ingeniero_pista
deny insert, update, delete on Penalizacion to rol_ingeniero_pista
deny insert, update, delete on GranPremio to rol_ingeniero_pista
deny select on Contrato to rol_ingeniero_pista
deny select on Gasto to rol_ingeniero_pista


grant select on Pais to rol_rrhh
grant select on Puesto to rol_rrhh
grant select, insert, update on Empleado to rol_rrhh
grant select, insert, update on Piloto to rol_rrhh
grant select, insert, update on Contrato to rol_rrhh
grant select on AuditoriaContrato to rol_rrhh
grant select on vw_nomina to rol_rrhh
grant execute on dbo.fn_contrato_vigente to rol_rrhh
deny delete on Contrato to rol_rrhh
deny insert, update, delete on AuditoriaContrato to rol_rrhh
deny select on Gasto to rol_rrhh


grant select on Pais to rol_finanzas
grant select on CategoriaGasto to rol_finanzas
grant select on TopePresupuestario to rol_finanzas
grant select on AlertaTope to rol_finanzas
grant select on TipoComponente to rol_finanzas
grant select on Componente to rol_finanzas
grant select on Gasto to rol_finanzas
grant select, insert, update on Proveedor to rol_finanzas
grant select on vw_situacion_tope to rol_finanzas
grant execute on dbo.fn_gasto_computable to rol_finanzas
grant execute on usp_registrar_compra to rol_finanzas
grant execute on usp_registrar_gasto to rol_finanzas
deny insert, update, delete on Gasto to rol_finanzas
deny insert, update, delete on AlertaTope to rol_finanzas
deny insert, update, delete on Componente to rol_finanzas
deny select on Contrato to rol_finanzas
deny select on AuditoriaContrato to rol_finanzas


grant select on Pais to rol_consulta
grant select on Circuito to rol_consulta
grant select on GranPremio to rol_consulta
grant select on TipoSesion to rol_consulta
grant select on Sesion to rol_consulta
grant select on vw_puntos_equipo_por_gp to rol_consulta
grant select on vw_nomina to rol_consulta
deny select on Contrato to rol_consulta
deny select on AuditoriaContrato to rol_consulta
deny select on Gasto to rol_consulta
deny select on vw_situacion_tope to rol_consulta
