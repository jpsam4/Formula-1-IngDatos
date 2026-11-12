use master

if exists (select * from sysdatabases where name = 'EscuderiaF1')
    drop database EscuderiaF1

create database EscuderiaF1
go

use EscuderiaF1


create table Pais (
    id_pais int identity(1,1) constraint PK_Pais primary key,
    nombre nvarchar(60) not null constraint UQ_Pais_nombre unique,
    codigo_iso char(3) not null constraint UQ_Pais_codigo unique,
    constraint CK_Pais_codigo check (codigo_iso like '[A-Z][A-Z][A-Z]')
)

create table Temporada (
    anio smallint not null,
    constraint PK_Temporada primary key (anio),
    constraint CK_Temporada_anio check (anio >= 1950)
)

create table TipoSesion (
    id_tipo_sesion int identity(1,1) not null,
    nombre nvarchar(40) not null,
    es_sprint bit not null constraint DF_TipoSesion_sprint default 0,
    otorga_puntos bit not null constraint DF_TipoSesion_puntos default 0,
    constraint PK_TipoSesion primary key (id_tipo_sesion),
    constraint UQ_TipoSesion_nombre unique (nombre)
)

create table Puesto (
    id_puesto int identity(1,1) constraint PK_Puesto primary key,
    nombre nvarchar(60) not null,
    departamento nvarchar(40) not null,
    constraint UQ_Puesto_nombre unique (nombre)
)

create table TipoComponente (
    id_tipo int identity(1,1) not null,
    nombre nvarchar(40) not null,
    vida_util_km decimal(10,2) not null,
    constraint PK_TipoComponente primary key (id_tipo),
    constraint UQ_TipoComponente_nombre unique (nombre),
    constraint CK_TipoComponente_vida check (vida_util_km > 0)
)

create table CategoriaGasto (
    id_categoria int identity(1,1) constraint PK_CategoriaGasto primary key,
    nombre nvarchar(60) not null constraint UQ_CategoriaGasto_nombre unique,
    computa_tope bit not null constraint DF_CategoriaGasto_computa default 1
)



create table Circuito (
    id_circuito int identity(1,1) not null,
    nombre nvarchar(80) not null,
    ciudad nvarchar(60) not null,
    id_pais int not null,
    longitud_km decimal(5,3) not null,
    constraint PK_Circuito primary key (id_circuito),
    constraint UQ_Circuito_nombre unique (nombre),
    constraint FK_Circuito_Pais
        foreign key (id_pais) references Pais (id_pais),
    constraint CK_Circuito_longitud check (longitud_km > 0)
)

create table Puntaje (
    anio smallint not null,
    id_tipo_sesion int not null,
    posicion tinyint not null constraint CK_Puntaje_posicion check (posicion > 0),
    puntos tinyint not null constraint CK_Puntaje_puntos check (puntos > 0),
    constraint PK_Puntaje primary key (anio, id_tipo_sesion, posicion)
)

alter table Puntaje add
    constraint FK_Puntaje_Temporada foreign key (anio) references Temporada (anio),
    constraint FK_Puntaje_TipoSesion foreign key (id_tipo_sesion) references TipoSesion (id_tipo_sesion)

create table Empleado (
    id_empleado int identity(1,1) not null,
    nombre nvarchar(60) not null,
    apellido nvarchar(60) not null,
    documento nvarchar(20) not null,
    fecha_nacimiento date not null,
    email nvarchar(120) not null,
    id_pais int not null,
    id_puesto int not null,
    constraint PK_Empleado primary key (id_empleado),
    constraint UQ_Empleado_documento unique (documento),
    constraint UQ_Empleado_email unique (email),
    constraint FK_Empleado_Pais foreign key (id_pais) references Pais (id_pais),
    constraint FK_Empleado_Puesto foreign key (id_puesto) references Puesto (id_puesto),
    constraint CK_Empleado_email check (email like '%_@_%._%'),
    constraint CK_Empleado_nacimiento check (fecha_nacimiento >= '1920-01-01')
)

create table Chasis (
    id_chasis int identity(1,1) constraint PK_Chasis primary key,
    codigo nvarchar(20) not null constraint UQ_Chasis_codigo unique,
    anio smallint not null constraint FK_Chasis_Temporada references Temporada (anio)
)

create table LimiteComponente (
    anio smallint not null,
    id_tipo int not null,
    cantidad_max tinyint not null,
    constraint PK_LimiteComponente
        primary key (anio, id_tipo),
    constraint FK_LimiteComponente_Temporada
        foreign key (anio) references Temporada (anio),
    constraint FK_LimiteComponente_Tipo
        foreign key (id_tipo) references TipoComponente (id_tipo),
    constraint CK_LimiteComponente_cantidad
        check (cantidad_max > 0)
)

create table Componente (
    id_componente int identity(1,1) not null,
    id_tipo int not null,
    numero_serie nvarchar(30) not null,
    km_acumulados decimal(10,2) not null constraint DF_Componente_km default 0,
    estado nvarchar(10) not null constraint DF_Componente_estado default 'Nuevo',
    constraint PK_Componente primary key (id_componente),
    constraint UQ_Componente_serie unique (numero_serie),
    constraint FK_Componente_Tipo foreign key (id_tipo) references TipoComponente (id_tipo),
    constraint CK_Componente_km check (km_acumulados >= 0),
    constraint CK_Componente_estado check (estado in ('Nuevo', 'En uso', 'Retirado', 'Danado'))
)

create table Proveedor (
    id_proveedor int identity(1,1) constraint PK_Proveedor primary key,
    razon_social nvarchar(100) not null,
    identificacion_fiscal nvarchar(30) not null constraint UQ_Proveedor_fiscal unique,
    id_pais int not null constraint FK_Proveedor_Pais references Pais (id_pais)
)

create table TopePresupuestario (
    anio smallint not null,
    monto_usd decimal(14,2) not null,
    umbral_alerta_pct tinyint not null
        constraint DF_Tope_umbral default 90
        constraint CK_Tope_umbral check (umbral_alerta_pct between 1 and 99),
    constraint PK_TopePresupuestario primary key (anio),
    constraint FK_Tope_Temporada foreign key (anio) references Temporada (anio),
    constraint CK_Tope_monto check (monto_usd > 0)
)



create table GranPremio (
    id_gp int identity(1,1) not null,
    anio smallint not null,
    ronda tinyint not null,
    id_circuito int not null,
    nombre nvarchar(80) not null,
    fecha_inicio date not null,
    fecha_fin date not null,
    es_sprint bit not null constraint DF_GranPremio_sprint default 0,
    cerrado bit not null constraint DF_GranPremio_cerrado default 0,
    constraint PK_GranPremio primary key (id_gp),
    constraint FK_GranPremio_Temporada foreign key (anio) references Temporada (anio),
    constraint FK_GranPremio_Circuito foreign key (id_circuito) references Circuito (id_circuito),
    constraint UQ_GranPremio_anio_ronda unique (anio, ronda),
    constraint CK_GranPremio_ronda check (ronda > 0),
    constraint CK_GranPremio_fechas check (fecha_fin >= fecha_inicio),
    constraint CK_GranPremio_anio check (year(fecha_inicio) = anio)
)

create table Piloto (
    id_empleado int not null,
    numero_auto tinyint not null,
    constraint PK_Piloto primary key (id_empleado),
    constraint FK_Piloto_Empleado foreign key (id_empleado) references Empleado (id_empleado),
    constraint UQ_Piloto_numero unique (numero_auto),
    constraint CK_Piloto_numero check (numero_auto between 1 and 99)
)

create table Contrato (
    id_contrato int identity(1,1) not null,
    id_empleado int not null,
    fecha_inicio date not null,
    fecha_fin date null,
    sueldo_mensual_usd decimal(14,2) not null,
    condicion nvarchar(10) null,
    constraint PK_Contrato primary key (id_contrato),
    constraint FK_Contrato_Empleado
        foreign key (id_empleado) references Empleado (id_empleado),
    constraint CK_Contrato_fechas
        check (fecha_fin is null or fecha_fin > fecha_inicio),
    constraint CK_Contrato_sueldo
        check (sueldo_mensual_usd > 0),
    constraint CK_Contrato_condicion
        check (condicion is null or condicion in ('Titular', 'Reserva'))
)

create table Gasto (
    id_gasto int identity(1,1) not null,
    fecha date not null,
    monto_usd decimal(14,2) not null,
    descripcion nvarchar(200) not null,
    id_categoria int not null,
    id_proveedor int not null,
    id_componente int null,
    constraint PK_Gasto primary key (id_gasto),
    constraint CK_Gasto_monto check (monto_usd > 0)
)

alter table Gasto add constraint FK_Gasto_Categoria foreign key (id_categoria) references CategoriaGasto (id_categoria)
alter table Gasto add constraint FK_Gasto_Proveedor foreign key (id_proveedor) references Proveedor (id_proveedor)
alter table Gasto add constraint FK_Gasto_Componente foreign key (id_componente) references Componente (id_componente)



create table Sesion (
    id_sesion int identity(1,1) not null,
    id_gp int not null,
    id_tipo_sesion int not null,
    fecha_hora datetime2(0) not null,
    constraint PK_Sesion primary key (id_sesion),
    constraint FK_Sesion_GranPremio foreign key (id_gp) references GranPremio (id_gp),
    constraint FK_Sesion_TipoSesion foreign key (id_tipo_sesion) references TipoSesion (id_tipo_sesion),
    constraint UQ_Sesion_gp_tipo unique (id_gp, id_tipo_sesion)
)

create table Inscripcion (
    id_inscripcion int identity(1,1) not null,
    id_gp int not null,
    id_piloto int not null,
    id_chasis int not null,
    constraint PK_Inscripcion primary key (id_inscripcion),
    constraint FK_Inscripcion_GranPremio foreign key (id_gp) references GranPremio (id_gp),
    constraint FK_Inscripcion_Piloto foreign key (id_piloto) references Piloto (id_empleado),
    constraint FK_Inscripcion_Chasis foreign key (id_chasis) references Chasis (id_chasis),
    constraint UQ_Inscripcion_gp_piloto unique (id_gp, id_piloto),
    constraint UQ_Inscripcion_gp_chasis unique (id_gp, id_chasis)
)

create table AuditoriaContrato (
    id_auditoria int identity(1,1) constraint PK_AuditoriaContrato primary key,
    id_contrato int not null constraint FK_Auditoria_Contrato references Contrato (id_contrato),
    sueldo_anterior decimal(14,2) not null,
    sueldo_nuevo decimal(14,2) not null,
    fecha datetime2(0) not null constraint DF_Auditoria_fecha default getdate(),
    usuario nvarchar(128) not null constraint DF_Auditoria_usuario default system_user
)

create table AlertaTope (
    id_alerta int identity(1,1) not null,
    id_gasto int not null,
    fecha datetime2(0) not null constraint DF_AlertaTope_fecha default getdate(),
    gasto_acumulado_usd decimal(14,2) not null,
    constraint PK_AlertaTope primary key (id_alerta),
    constraint FK_AlertaTope_Gasto foreign key (id_gasto) references Gasto (id_gasto),
    constraint UQ_AlertaTope_gasto unique (id_gasto)
)



create table Resultado (
    id_sesion int not null,
    id_inscripcion int not null,
    posicion tinyint null,
    estado nvarchar(15) not null,
    constraint PK_Resultado primary key (id_sesion, id_inscripcion),
    constraint FK_Resultado_Sesion foreign key (id_sesion) references Sesion (id_sesion),
    constraint FK_Resultado_Inscripcion foreign key (id_inscripcion) references Inscripcion (id_inscripcion),
    constraint CK_Resultado_estado
        check (estado in ('Finalizo', 'Abandono', 'Descalificado', 'No largo')),
    constraint CK_Resultado_posicion check (
        (estado = 'Finalizo' and posicion is not null and posicion > 0)
        or (estado <> 'Finalizo' and posicion is null)
    )
)

create table UsoComponente (
    id_componente int not null,
    id_inscripcion int not null,
    km_recorridos decimal(10,2) not null constraint CK_Uso_km check (km_recorridos >= 0),
    constraint PK_UsoComponente primary key (id_componente, id_inscripcion),
    constraint FK_Uso_Componente foreign key (id_componente) references Componente (id_componente),
    constraint FK_Uso_Inscripcion foreign key (id_inscripcion) references Inscripcion (id_inscripcion)
)

create table Penalizacion (
    id_penalizacion int identity(1,1) not null,
    id_inscripcion int not null,
    id_componente int not null,
    puestos_grilla tinyint not null,
    motivo nvarchar(200) not null,
    fecha datetime2(0) not null constraint DF_Penalizacion_fecha default getdate(),
    constraint PK_Penalizacion primary key (id_penalizacion),
    constraint FK_Penalizacion_Inscripcion foreign key (id_inscripcion) references Inscripcion (id_inscripcion),
    constraint FK_Penalizacion_Componente foreign key (id_componente) references Componente (id_componente),
    constraint CK_Penalizacion_puestos check (puestos_grilla > 0)
)

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
(1, 'Max', 'Verstappen', '38455120', '1997-09-30', 'max.verstappen@redbullracing.com', 9, 1),
(2, 'Isack', 'Hadjar', '45210877', '2004-09-28', 'isack.hadjar@redbullracing.com', 10, 1),
(3, 'Yuki', 'Tsunoda', '41530296', '2000-05-11', 'yuki.tsunoda@redbullracing.com', 4, 1),
(4, 'Santiago', 'Ferraro', '46118203', '2006-02-14', 'santiago.ferraro@redbullracing.com', 1, 1),
(5, 'Mark', 'Wilson', '23871540', '1976-11-02', 'mark.wilson@redbullracing.com', 11, 2),
(6, 'Laura', 'Bennett', '30447812', '1983-04-19', 'laura.bennett@redbullracing.com', 11, 3),
(7, 'Tomas', 'Ibarra', '33456781', '1988-07-23', 'tomas.ibarra@redbullracing.com', 1, 5),
(8, 'Ryan', 'Cooper', '31209933', '1985-01-30', 'ryan.cooper@redbullracing.com', 11, 4),
(9, 'Daniel', 'Brown', '35118274', '1990-10-08', 'daniel.brown@redbullracing.com', 11, 6),
(10, 'Paul', 'Harris', '26654091', '1979-03-15', 'paul.harris@redbullracing.com', 11, 7),
(11, 'Lucas', 'Romero', '38992416', '1994-12-01', 'lucas.romero@redbullracing.com', 1, 8),
(12, 'Jack', 'Taylor', '40731158', '1997-06-11', 'jack.taylor@redbullracing.com', 11, 8),
(13, 'Ben', 'Walker', '34560127', '1991-08-27', 'ben.walker@redbullracing.com', 11, 8),
(14, 'Sofia', 'Martinez', '39874401', '1996-02-05', 'sofia.martinez@redbullracing.com', 8, 9),
(15, 'Emily', 'Turner', '32015586', '1987-05-21', 'emily.turner@redbullracing.com', 11, 10),
(16, 'Sarah', 'Hughes', '36702219', '1992-09-09', 'sarah.hughes@redbullracing.com', 11, 11),
(17, 'Julia', 'Mendez', '42183370', '1999-01-17', 'julia.mendez@redbullracing.com', 1, 12)
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
(1, 'Brembo', 'IT001', 12),
(2, 'Red Bull Advanced Technologies', 'GB002', 11),
(3, 'DHL', 'DE003', 13),
(4, 'Ford', 'US004', 5),
(5, 'Red Bull Powertrains', 'GB005', 11),
(6, 'Toyota Gazoo Racing Europe', 'DE006', 13),
(7, 'Do & Co', 'AT007', 14),
(8, 'Iberia', 'ES008', 8),
(9, 'Mobil 1', 'US009', 5)
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
    left join Puntaje p on p.anio = g.anio and p.id_tipo_sesion = s.id_tipo_sesion and p.posicion = r.posicion
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
            raiserror('la sesion no existe', 16, 1)

        if @gpinsc is null
            raiserror('la inscripcion no existe', 16, 1)

        if @gpsesion <> @gpinsc
            raiserror('la inscripcion no es del mismo Gran Premio que la sesion', 16, 1)

        if exists (select 1 from Resultado where id_sesion = @idsesion and id_inscripcion = @idinsc)
            raiserror('ese piloto ya tiene un resultado cargado en la sesion', 16, 1)

        if @pos is not null and exists (select 1 from Resultado where id_sesion = @idsesion and posicion = @pos)
            raiserror('esa posicion ya la tiene otro piloto en la sesion', 16, 1)

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
            raiserror('el Gran Premio no existe', 16, 1)

        if @cerrado = 1
            raiserror('el Gran Premio ya esta cerrado', 16, 1)

        if not exists (select 1 from Piloto where id_empleado = @idpiloto)
            raiserror('el piloto no existe', 16, 1)

        if dbo.fn_contrato_vigente(@idpiloto, @fecha) is null
            raiserror('el piloto no tiene contrato vigente en la fecha del Gran Premio', 16, 1)

        select @cant = count(*) from Inscripcion where id_gp = @idgp
        if @cant >= 2
            raiserror('el Gran Premio ya tiene dos pilotos inscriptos', 16, 1)

        if not exists (select 1 from Chasis where id_chasis = @idchasis and anio = @anio)
            raiserror('el chasis no existe o no es de la temporada del Gran Premio', 16, 1)

        begin transaction

        insert into Inscripcion (id_gp, id_piloto, id_chasis)
        values (@idgp, @idpiloto, @idchasis)

        commit transaction

        print 'piloto ' + cast(@idpiloto as varchar(10)) + ' inscripto en el GP ' + cast(@idgp as varchar(10))
            + ' (inscripcion ' + cast(@@identity as varchar(10)) + ')'
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
            raiserror('el Gran Premio no existe', 16, 1)

        if exists (select 1 from GranPremio where id_gp = @idgp and cerrado = 1)
            raiserror('el Gran Premio ya estaba cerrado', 16, 1)

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

            if exists (
                select 1
                from Componente c
                inner join TipoComponente t on t.id_tipo = c.id_tipo
                where c.id_componente = @idcomp and c.km_acumulados >= t.vida_util_km and c.estado <> 'Retirado'
            )
            begin
                exec @r = usp_retirar_componente @idcomp = @idcomp

                if @r <> 0
                    raiserror('no se pudo retirar una de las piezas', 16, 1)

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
            raiserror('el tipo de pieza no existe', 16, 1)

        if not exists (select 1 from CategoriaGasto where id_categoria = @idcat)
            raiserror('la categoria no existe', 16, 1)

        if not exists (select 1 from Proveedor where id_proveedor = @idprov)
            raiserror('el proveedor no existe', 16, 1)

        begin transaction

        insert into Componente (id_tipo, numero_serie)
        values (@idtipo, @serie)

        set @idcomp = @@identity

        insert into Gasto (fecha, monto_usd, descripcion, id_categoria, id_proveedor, id_componente)
        values (@fecha, @monto, @descr, @idcat, @idprov, @idcomp)

        commit transaction

        print 'compra registrada: pieza ' + @serie + ' (id ' + cast(@idcomp as varchar(10)) + ')'
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
            raiserror('la categoria no existe', 16, 1)

        if not exists (select 1 from Proveedor where id_proveedor = @idprov)
            raiserror('el proveedor no existe', 16, 1)

        begin transaction

        insert into Gasto (fecha, monto_usd, descripcion, id_categoria, id_proveedor)
        values (@fecha, @monto, @descr, @idcat, @idprov)

        commit transaction

        print 'gasto registrado'
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

    if exists (select 1 from inserted i
        where i.condicion is not null and i.id_empleado not in (select id_empleado from Piloto))
    begin
        rollback transaction
        raiserror('solo el contrato de un piloto dice si es titular o reserva', 16, 1)
        return
    end

    if exists (select 1 from inserted i
        inner join Piloto p on p.id_empleado = i.id_empleado
        where i.condicion is null)
    begin
        rollback transaction
        raiserror('el contrato de un piloto tiene que decir si es titular o reserva', 16, 1)
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
go

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
