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
