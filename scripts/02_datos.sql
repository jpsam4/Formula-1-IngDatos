use EscuderiaF1


set identity_insert Pais on
insert into Pais (id_pais, nombre, codigo_iso) values
(1, 'Argentina', 'ARG'),
(2, 'Australia', 'AUS'),
(3, 'China', 'CHN'),
(4, 'Japon', 'JPN'),
(5, 'Estados Unidos', 'USA'),
(6, 'Canada', 'CAN'),
(7, 'Monaco', 'MCO'),
(8, 'Espana', 'ESP'),
(9, 'Paises Bajos', 'NLD'),
(10, 'Francia', 'FRA'),
(11, 'Reino Unido', 'GBR'),
(12, 'Italia', 'ITA'),
(13, 'Alemania', 'DEU'),
(14, 'Austria', 'AUT')
set identity_insert Pais off

insert into Temporada (anio) values (2025), (2026), (2027)

set identity_insert TipoSesion on
insert into TipoSesion (id_tipo_sesion, nombre, es_sprint, otorga_puntos) values
(1, 'Practica 1', 0, 0),
(2, 'Practica 2', 0, 0),
(3, 'Practica 3', 0, 0),
(4, 'Clasificacion sprint', 1, 0),
(5, 'Sprint', 1, 1),
(6, 'Clasificacion', 0, 0),
(7, 'Carrera', 0, 1)
set identity_insert TipoSesion off

set identity_insert Puesto on
insert into Puesto (id_puesto, nombre, departamento) values
(1, 'Piloto', 'Deportivo'),
(2, 'Director de equipo', 'Direccion'),
(3, 'Director deportivo', 'Deportivo'),
(4, 'Ingeniero de carrera', 'Tecnico'),
(5, 'Ingeniero de pista', 'Tecnico'),
(6, 'Ingeniero de motores', 'Tecnico'),
(7, 'Jefe de mecanicos', 'Tecnico'),
(8, 'Mecanico', 'Tecnico'),
(9, 'Analista de datos', 'Tecnico'),
(10, 'Responsable de RRHH', 'Administracion'),
(11, 'Analista de finanzas', 'Administracion'),
(12, 'Administrativo', 'Administracion')
set identity_insert Puesto off

set identity_insert TipoComponente on
insert into TipoComponente (id_tipo, nombre, vida_util_km) values
(1, 'Motor de combustion', 4000),
(2, 'Turbo', 4000),
(3, 'MGU-K', 3800),
(4, 'Caja de cambios', 3500)
set identity_insert TipoComponente off

set identity_insert CategoriaGasto on
insert into CategoriaGasto (id_categoria, nombre, computa_tope) values
(1, 'Fabricacion de piezas', 1),
(2, 'Investigacion y desarrollo', 1),
(3, 'Tunel de viento y simulacion', 1),
(4, 'Logistica y fletes', 1),
(5, 'Hospitalidad y marketing', 0),
(6, 'Viajes del personal', 1)
set identity_insert CategoriaGasto off


set identity_insert Circuito on
insert into Circuito (id_circuito, nombre, ciudad, id_pais, longitud_km) values
(1, 'Albert Park', 'Melbourne', 2, 5.278),
(2, 'Shanghai International Circuit', 'Shanghai', 3, 5.451),
(3, 'Suzuka', 'Suzuka', 4, 5.807),
(4, 'Miami International Autodrome', 'Miami', 5, 5.412),
(5, 'Circuit Gilles Villeneuve', 'Montreal', 6, 4.361),
(6, 'Circuit de Monaco', 'Montecarlo', 7, 3.337),
(7, 'Circuit de Barcelona-Catalunya', 'Montmelo', 8, 4.657),
(8, 'Red Bull Ring', 'Spielberg', 14, 4.318)
set identity_insert Circuito off

insert into Puntaje (anio, id_tipo_sesion, posicion, puntos) values
(2026, 7, 1, 25), (2026, 7, 2, 18), (2026, 7, 3, 15), (2026, 7, 4, 12), (2026, 7, 5, 10),
(2026, 7, 6, 8), (2026, 7, 7, 6), (2026, 7, 8, 4), (2026, 7, 9, 2), (2026, 7, 10, 1),
(2026, 5, 1, 8), (2026, 5, 2, 7), (2026, 5, 3, 6), (2026, 5, 4, 5),
(2026, 5, 5, 4), (2026, 5, 6, 3), (2026, 5, 7, 2), (2026, 5, 8, 1)

set identity_insert Empleado on
insert into Empleado (id_empleado, nombre, apellido, documento, fecha_nacimiento, email, id_pais, id_puesto) values
(1, 'Max', 'Verstappen', 'NLD-PX4471902', '1997-09-30', 'max.verstappen@redbullracing.com', 9, 1),
(2, 'Isack', 'Hadjar', 'FRA-19FR83321', '2004-09-28', 'isack.hadjar@redbullracing.com', 10, 1),
(3, 'Yuki', 'Tsunoda', 'JPN-TR8812045', '2000-05-11', 'yuki.tsunoda@redbullracing.com', 4, 1),
(4, 'Santiago', 'Ferraro', 'ARG-46118203', '2006-02-14', 'santiago.ferraro@redbullracing.com', 1, 1),
(5, 'Marc', 'Lenoir', 'FRA-14GH20551', '1976-11-02', 'marc.lenoir@redbullracing.com', 10, 2),
(6, 'Hannah', 'Whitcombe', 'GBR-533820147', '1983-04-19', 'hannah.whitcombe@redbullracing.com', 11, 3),
(7, 'Tomas', 'Ibarra', 'ARG-33456781', '1988-07-23', 'tomas.ibarra@redbullracing.com', 1, 5),
(8, 'Oliver', 'Granger', 'GBR-541093328', '1985-01-30', 'oliver.granger@redbullracing.com', 11, 4),
(9, 'Kenji', 'Morita', 'JPN-TK5520913', '1990-10-08', 'kenji.morita@redbullracing.com', 4, 6),
(10, 'Stefan', 'Brandt', 'DEU-C01X88412', '1979-03-15', 'stefan.brandt@redbullracing.com', 13, 7),
(11, 'Luca', 'Bernardi', 'ITA-YA7781203', '1994-12-01', 'luca.bernardi@redbullracing.com', 12, 8),
(12, 'Sam', 'Fletcher', 'GBR-560211874', '1997-06-11', 'sam.fletcher@redbullracing.com', 11, 8),
(13, 'Pieter', 'de Vries', 'NLD-NW3390218', '1991-08-27', 'pieter.devries@redbullracing.com', 9, 8),
(14, 'Valentina', 'Ruiz', 'ESP-PAF661203', '1996-02-05', 'valentina.ruiz@redbullracing.com', 8, 9),
(15, 'Claire', 'Dubois', 'FRA-12KD77310', '1987-05-21', 'claire.dubois@redbullracing.com', 10, 10),
(16, 'Emma', 'Hartley', 'GBR-548870021', '1992-09-09', 'emma.hartley@redbullracing.com', 11, 11),
(17, 'Julia', 'Steiner', 'AUT-P8812337', '1999-01-17', 'julia.steiner@redbullracing.com', 14, 12)
set identity_insert Empleado off

set identity_insert Chasis on
insert into Chasis (id_chasis, codigo, anio) values
(1, 'RB21-01', 2025),
(2, 'RB21-02', 2025),
(3, 'RB22-01', 2026),
(4, 'RB22-02', 2026),
(5, 'RB22-03', 2026)
set identity_insert Chasis off

insert into LimiteComponente (anio, id_tipo, cantidad_max) values
(2025, 1, 4), (2025, 2, 4), (2025, 3, 4), (2025, 4, 5),
(2026, 1, 4), (2026, 2, 4), (2026, 3, 3), (2026, 4, 4)

set identity_insert Componente on
insert into Componente (id_componente, id_tipo, numero_serie, km_acumulados, estado) values
(1, 1, 'ICE-26-01', 1990, 'En uso'),
(2, 1, 'ICE-26-02', 1210, 'En uso'),
(3, 2, 'TC-26-01', 1990, 'En uso'),
(4, 2, 'TC-26-02', 1210, 'En uso'),
(5, 3, 'MGUK-26-01', 1280, 'Danado'),
(6, 3, 'MGUK-26-02', 1300, 'Danado'),
(7, 3, 'MGUK-26-03', 620, 'Danado'),
(8, 3, 'MGUK-26-04', 0, 'Nuevo'),
(9, 4, 'GBX-26-01', 3200, 'En uso'),
(10, 1, 'ICE-26-03', 2310, 'En uso'),
(11, 1, 'ICE-26-04', 615, 'En uso'),
(12, 2, 'TC-26-03', 2925, 'En uso'),
(13, 3, 'MGUK-26-05', 2310, 'Danado'),
(14, 3, 'MGUK-26-06', 615, 'En uso'),
(15, 4, 'GBX-26-02', 2925, 'En uso'),
(16, 1, 'ICE-26-05', 0, 'Nuevo'),
(17, 3, 'MGUK-26-07', 0, 'Nuevo'),
(18, 3, 'MGUK-26-08', 0, 'Nuevo'),
(19, 3, 'MGUK-26-09', 0, 'Nuevo'),
(20, 4, 'GBX-26-03', 0, 'Nuevo'),
(21, 2, 'TC-26-04', 0, 'Nuevo')
set identity_insert Componente off

set identity_insert Proveedor on
insert into Proveedor (id_proveedor, razon_social, identificacion_fiscal, id_pais) values
(1, 'Tirreno Frenos S.p.A.', 'IT01987650214', 12),
(2, 'Milton Composites Ltd', 'GB284113790', 11),
(3, 'Logistica Austral S.A.', 'AR30712345679', 1),
(4, 'Kanto Precision Electronics KK', 'JP7010401092', 4),
(5, 'Bavaria Antriebstechnik GmbH', 'DE298765431', 13),
(6, 'Northfield Wind Tunnel Ltd', 'GB301556782', 11),
(7, 'Steirische Events GmbH', 'ATU71234567', 14),
(8, 'Iberia Viajes Corporativos S.L.', 'ESB86543210', 8),
(9, 'Hydra Fluidos S.A.S.', 'FR40512339871', 10)
set identity_insert Proveedor off

insert into TopePresupuestario (anio, monto_usd, umbral_alerta_pct) values
(2025, 135000000, 90),
(2026, 215000000, 90)


set identity_insert GranPremio on
insert into GranPremio (id_gp, anio, ronda, id_circuito, nombre, fecha_inicio, fecha_fin, es_sprint, cerrado) values
(1, 2026, 1, 1, 'GP de Australia', '2026-03-06', '2026-03-08', 0, 1),
(2, 2026, 2, 2, 'GP de China', '2026-03-13', '2026-03-15', 1, 1),
(3, 2026, 3, 3, 'GP de Japon', '2026-03-27', '2026-03-29', 0, 1),
(4, 2026, 4, 4, 'GP de Miami', '2026-05-01', '2026-05-03', 1, 1),
(5, 2026, 5, 5, 'GP de Canada', '2026-05-22', '2026-05-24', 1, 1),
(6, 2026, 6, 6, 'GP de Monaco', '2026-06-05', '2026-06-07', 0, 0),
(7, 2026, 7, 7, 'GP de Barcelona-Catalunya', '2026-06-12', '2026-06-14', 0, 0)
set identity_insert GranPremio off

insert into Piloto (id_empleado, numero_auto) values
(1, 3),
(2, 6),
(3, 22),
(4, 47)

set identity_insert Contrato on
insert into Contrato (id_contrato, id_empleado, fecha_inicio, fecha_fin, sueldo_mensual_usd, condicion) values
(1, 1, '2024-01-01', '2028-12-31', 4200000, 'Titular'),
(2, 2, '2026-01-01', '2027-12-31', 210000, 'Titular'),
(3, 3, '2025-01-01', '2025-12-31', 150000, 'Titular'),
(4, 3, '2026-01-01', '2026-12-31', 90000, 'Reserva'),
(5, 4, '2025-01-01', '2025-12-31', 12000, 'Reserva'),
(6, 5, '2025-07-15', null, 95000, null),
(7, 6, '2023-03-01', null, 48000, null),
(8, 7, '2024-02-01', null, 22000, null),
(9, 8, '2022-01-10', null, 26000, null),
(10, 9, '2025-06-01', null, 24000, null),
(11, 10, '2021-01-01', null, 17000, null),
(12, 11, '2024-08-01', '2026-12-31', 9500, null),
(13, 12, '2025-01-15', null, 8800, null),
(14, 13, '2023-01-01', '2025-06-30', 8200, null),
(15, 14, '2024-09-01', null, 11000, null),
(16, 15, '2022-05-01', null, 15000, null),
(17, 16, '2023-11-01', null, 13500, null),
(18, 17, '2025-02-01', null, 6000, null)
set identity_insert Contrato off

set identity_insert Gasto on
insert into Gasto (id_gasto, fecha, monto_usd, descripcion, id_categoria, id_proveedor, id_componente) values
(1, '2025-02-14', 45000000, 'Desarrollo aerodinamico del RB21', 2, 2, null),
(2, '2025-04-10', 28000000, 'Horas de tunel de viento 2025', 3, 6, null),
(3, '2025-06-20', 22000000, 'Fabricacion de piezas de carroceria 2025', 1, 2, null),
(4, '2025-08-29', 19500000, 'Fletes de la temporada 2025', 4, 3, null),
(5, '2025-10-15', 9200000, 'Pinzas y discos de freno, fin de temporada', 1, 1, null),
(6, '2025-11-03', 4000000, 'Hospitalidad en Las Vegas', 5, 7, null),
(7, '2026-01-12', 1800000, 'Motor de combustion ICE-26-01', 1, 5, 1),
(8, '2026-01-12', 1800000, 'Motor de combustion ICE-26-03', 1, 5, 10),
(9, '2026-01-14', 650000, 'Turbo TC-26-01', 1, 5, 3),
(10, '2026-01-14', 650000, 'Turbo TC-26-03', 1, 5, 12),
(11, '2026-01-20', 900000, 'MGU-K MGUK-26-01', 1, 4, 5),
(12, '2026-01-20', 900000, 'MGU-K MGUK-26-05', 1, 4, 13),
(13, '2026-01-22', 1100000, 'Caja de cambios GBX-26-01', 1, 2, 9),
(14, '2026-01-22', 1100000, 'Caja de cambios GBX-26-02', 1, 2, 15),
(15, '2026-02-02', 38500000, 'Desarrollo aerodinamico del RB22, primera etapa', 2, 2, null),
(16, '2026-02-10', 12400000, 'Horas de tunel de viento enero y febrero', 3, 6, null),
(17, '2026-02-18', 4200000, 'Flete aereo a Melbourne', 4, 3, null),
(18, '2026-02-25', 9800000, 'Pinzas y discos de freno 2026', 1, 1, null),
(19, '2026-03-02', 2100000, 'Viajes y alojamiento, Australia y China', 6, 8, null),
(20, '2026-03-20', 900000, 'MGU-K MGUK-26-02', 1, 4, 6),
(21, '2026-03-23', 3900000, 'Flete a Japon', 4, 3, null),
(22, '2026-04-06', 31000000, 'Desarrollo aerodinamico del RB22, segunda etapa', 2, 2, null),
(23, '2026-04-14', 11700000, 'Horas de tunel de viento marzo y abril', 3, 6, null),
(24, '2026-04-20', 1800000, 'Motor de combustion ICE-26-02', 1, 5, 2),
(25, '2026-04-20', 650000, 'Turbo TC-26-02', 1, 5, 4),
(26, '2026-04-24', 4600000, 'Flete a Miami y Canada', 4, 3, null),
(27, '2026-04-28', 2600000, 'Viajes y alojamiento, Japon, Miami y Canada', 6, 8, null),
(28, '2026-05-05', 3500000, 'Hospitalidad en Miami', 5, 7, null),
(29, '2026-05-11', 900000, 'MGU-K MGUK-26-03', 1, 4, 7),
(30, '2026-05-15', 1800000, 'Motor de combustion ICE-26-04', 1, 5, 11),
(31, '2026-05-15', 900000, 'MGU-K MGUK-26-06', 1, 4, 14),
(32, '2026-05-26', 900000, 'MGU-K MGUK-26-04', 1, 4, 8),
(33, '2026-05-26', 2700000, 'Tres MGU-K de repuesto (MGUK-26-07 a 09)', 1, 4, null),
(34, '2026-05-27', 1800000, 'Motor de combustion ICE-26-05', 1, 5, 16),
(35, '2026-05-27', 650000, 'Turbo TC-26-04', 1, 5, 21),
(36, '2026-05-29', 27500000, 'Software de simulacion y simulador de manejo', 3, 6, null),
(37, '2026-06-01', 2800000, 'Hospitalidad y activaciones en Monaco', 5, 7, null),
(38, '2026-06-02', 18850000, 'Alerones y pisos, actualizacion europea', 1, 2, null),
(39, '2026-06-03', 3300000, 'Flete por carretera a Monaco y Barcelona', 4, 3, null)
set identity_insert Gasto off


set identity_insert Sesion on
insert into Sesion (id_sesion, id_gp, id_tipo_sesion, fecha_hora) values
(1, 1, 1, '2026-03-06 12:30'), (2, 1, 2, '2026-03-06 16:00'), (3, 1, 3, '2026-03-07 12:30'),
(4, 1, 6, '2026-03-07 16:00'), (5, 1, 7, '2026-03-08 15:00'),
(6, 2, 1, '2026-03-13 11:30'), (7, 2, 4, '2026-03-13 15:30'), (8, 2, 5, '2026-03-14 11:00'),
(9, 2, 6, '2026-03-14 15:00'), (10, 2, 7, '2026-03-15 15:00'),
(11, 3, 1, '2026-03-27 11:30'), (12, 3, 2, '2026-03-27 15:00'), (13, 3, 3, '2026-03-28 11:30'),
(14, 3, 6, '2026-03-28 15:00'), (15, 3, 7, '2026-03-29 14:00'),
(16, 4, 1, '2026-05-01 12:30'), (17, 4, 4, '2026-05-01 16:30'), (18, 4, 5, '2026-05-02 12:00'),
(19, 4, 6, '2026-05-02 16:00'), (20, 4, 7, '2026-05-03 16:00'),
(21, 5, 1, '2026-05-22 12:30'), (22, 5, 4, '2026-05-22 16:30'), (23, 5, 5, '2026-05-23 12:00'),
(24, 5, 6, '2026-05-23 16:00'), (25, 5, 7, '2026-05-24 14:00'),
(26, 6, 1, '2026-06-05 13:30'), (27, 6, 2, '2026-06-05 17:00'), (28, 6, 3, '2026-06-06 12:30'),
(29, 6, 6, '2026-06-06 16:00'), (30, 6, 7, '2026-06-07 15:00'),
(31, 7, 1, '2026-06-12 13:30'), (32, 7, 2, '2026-06-12 17:00'),
(33, 7, 6, '2026-06-13 16:00'), (34, 7, 7, '2026-06-14 15:00')
set identity_insert Sesion off

set identity_insert Inscripcion on
insert into Inscripcion (id_inscripcion, id_gp, id_piloto, id_chasis) values
(1, 1, 1, 3), (2, 1, 2, 4),
(3, 2, 1, 3), (4, 2, 2, 4),
(5, 3, 1, 3), (6, 3, 2, 4),
(7, 4, 1, 3), (8, 4, 2, 4),
(9, 5, 1, 3), (10, 5, 2, 4),
(11, 6, 1, 3), (12, 6, 2, 4)
set identity_insert Inscripcion off

set identity_insert AuditoriaContrato on
insert into AuditoriaContrato (id_auditoria, id_contrato, sueldo_anterior, sueldo_nuevo, fecha, usuario) values
(1, 1, 4000000, 4200000, '2026-01-05 10:12', 'login_rrhh'),
(2, 12, 9000, 9500, '2026-04-01 09:30', 'login_rrhh')
set identity_insert AuditoriaContrato off

insert into AlertaTope (id_gasto, fecha, gasto_acumulado_usd) values
(5, '2025-10-15 00:00', 123700000)


insert into Resultado (id_sesion, id_inscripcion, posicion, estado) values
(4, 1, 3, 'Finalizo'), (4, 2, 9, 'Finalizo'),
(5, 1, 2, 'Finalizo'), (5, 2, null, 'Abandono'),
(8, 3, 1, 'Finalizo'), (8, 4, 6, 'Finalizo'),
(9, 3, 2, 'Finalizo'), (9, 4, 7, 'Finalizo'),
(10, 3, 3, 'Finalizo'), (10, 4, 8, 'Finalizo'),
(14, 5, 1, 'Finalizo'), (14, 6, 6, 'Finalizo'),
(15, 5, 1, 'Finalizo'), (15, 6, 5, 'Finalizo'),
(18, 7, 4, 'Finalizo'), (18, 8, 7, 'Finalizo'),
(19, 7, 5, 'Finalizo'), (19, 8, 10, 'Finalizo'),
(20, 7, null, 'Descalificado'), (20, 8, 6, 'Finalizo'),
(23, 9, 2, 'Finalizo'), (23, 10, 9, 'Finalizo'),
(24, 9, 3, 'Finalizo'), (24, 10, 11, 'Finalizo'),
(25, 9, 2, 'Finalizo'), (25, 10, 9, 'Finalizo'),
(29, 11, 4, 'Finalizo'), (29, 12, 8, 'Finalizo'),
(30, 11, 3, 'Finalizo'), (30, 12, 7, 'Finalizo')

insert into UsoComponente (id_componente, id_inscripcion, km_recorridos) values
(1, 1, 680), (1, 3, 600), (1, 5, 710),
(2, 7, 590), (2, 9, 620), (2, 11, 540),
(3, 1, 680), (3, 3, 600), (3, 5, 710),
(4, 7, 590), (4, 9, 620), (4, 11, 540),
(5, 1, 680), (5, 3, 600),
(6, 5, 710), (6, 7, 590),
(7, 9, 620),
(8, 11, 540),
(9, 1, 680), (9, 3, 600), (9, 5, 710), (9, 7, 590), (9, 9, 620), (9, 11, 540),
(10, 2, 420), (10, 4, 600), (10, 6, 705), (10, 8, 585),
(11, 10, 615), (11, 12, 535),
(12, 2, 420), (12, 4, 600), (12, 6, 705), (12, 8, 585), (12, 10, 615), (12, 12, 535),
(13, 2, 420), (13, 4, 600), (13, 6, 705), (13, 8, 585),
(14, 10, 615), (14, 12, 535),
(15, 2, 420), (15, 4, 600), (15, 6, 705), (15, 8, 585), (15, 10, 615), (15, 12, 535)

insert into Penalizacion (id_inscripcion, id_componente, puestos_grilla, motivo, fecha) values
(11, 8, 10, '4 MGU-K usados en la temporada y el limite es 3', '2026-06-05 13:00')
