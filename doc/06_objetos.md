# Vistas, procedimientos, triggers, cursor y funciones

Están en los scripts 03 a 06. Las secciones van en el orden del enunciado, aunque en los scripts las funciones se crean primero porque las vistas y los procedimientos las usan.

De cada objeto ponemos lo que pide el enunciado para su tipo y qué regla de negocio del alcance hace cumplir (RN01 a RN22).

## Vistas

Están en [scripts/04_vistas.sql](../scripts/04_vistas.sql). Hay una por área.

### vw_puntos_equipo_por_gp

| | |
|---|---|
| Objetivo | Seguir cómo le va al equipo en la temporada. Como no guardamos a los rivales no hay tabla del campeonato, pero sí se puede ver cuántos puntos sumó el equipo en cada Gran Premio y cuántos lleva en total. |
| Información que muestra | Año, ronda y Gran Premio, los puntos del equipo en ese fin de semana (los dos pilotos, carrera y sprint) y el acumulado de la temporada hasta esa ronda. |
| Tablas | GranPremio, Sesion, Resultado y Puntaje |
| Por qué es una vista | Es una consulta que se usa siempre igual y tiene dos niveles de cálculo (sumar por Gran Premio y después ir acumulando), que no queremos repetir cada vez. También deja que el rol de consulta vea los puntos sin tener permiso sobre Resultado ni Puntaje. |

```sql
create or alter view vw_puntos_equipo_por_gp
as
select x.anio, x.ronda, x.gran_premio, x.puntos,
       sum(x.puntos) over (partition by x.anio order by x.ronda) as acumulado
from (
    select g.anio, g.ronda, g.nombre as gran_premio, isnull(sum(p.puntos), 0) as puntos
    from GranPremio g
    inner join Sesion s on s.id_gp = g.id_gp
    inner join Resultado r on r.id_sesion = s.id_sesion
    left join Puntaje p on p.anio = g.anio
                       and p.id_tipo_sesion = s.id_tipo_sesion
                       and p.posicion = r.posicion
    group by g.anio, g.ronda, g.nombre
) x
```

La subconsulta suma los puntos de cada Gran Premio. Puntaje va con `left join` para que un fin de semana sin puntos aparezca igual, con 0. Afuera, `sum() over` es la función de ventana que vimos en clase: va sumando ronda por ronda y arranca de cero en cada temporada (`partition by anio`). Un Gran Premio aparece en la vista cuando ya tiene resultados cargados.

Con los datos de prueba, `select * from vw_puntos_equipo_por_gp` devuelve las 6 fechas corridas y el equipo llega a Mónaco con 146 puntos.

### vw_nomina

| | |
|---|---|
| Objetivo | Mostrar quién trabaja hoy en la escudería sin mostrar los sueldos (RN21). |
| Información que muestra | Empleado, puesto, departamento, nacionalidad, desde y hasta cuándo va su contrato y, si es piloto, si es titular o reserva. |
| Tablas | Empleado, Puesto, Pais y Contrato, más la función `fn_contrato_vigente` |
| Por qué es una vista | Es la forma de que los demás roles vean el plantel sin poder leer Contrato, que tiene los sueldos. Los roles tienen permiso sobre la vista y DENY sobre Contrato. La vista igual puede leer Contrato porque las dos tienen el mismo dueño (`dbo`): SQL Server no vuelve a revisar los permisos sobre la tabla (encadenamiento de propiedad). |

```sql
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
```

El join contra la función deja solo a los que tienen contrato vigente hoy. Con los datos de prueba salen 15 empleados. Ferraro y de Vries no aparecen porque hoy no tienen contrato.

### vw_estado_piezas

| | |
|---|---|
| Objetivo | Ver de un vistazo cuánto le queda a cada pieza, para decidir qué se pone en el auto antes de cada Gran Premio. |
| Información que muestra | Pieza, tipo, estado, km acumulados, vida útil, km restantes, porcentaje usado y el último piloto que la usó. |
| Tablas | Componente, TipoComponente, UsoComponente, Inscripcion y Empleado, más la función `fn_km_restantes` |
| Por qué es una vista | Junta un cálculo (los km restantes), un porcentaje y una subconsulta (el último piloto) que el ingeniero necesita siempre juntos. El ingeniero de pista tiene permiso de lectura sobre la vista. |

```sql
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
```

Con `select * from vw_estado_piezas order by km_restantes` la primera es la caja GBX-26-01, a la que le quedan 300 km.

### vw_situacion_tope

| | |
|---|---|
| Objetivo | Saber en todo momento cuánto se gastó en el año y cuánto queda antes del tope. |
| Información que muestra | Año, tope, gasto computable, disponible, porcentaje usado, umbral de aviso y cuántas alertas saltaron. |
| Tablas | TopePresupuestario y AlertaTope, y Gasto y CategoriaGasto a través de la función `fn_gasto_computable` |
| Por qué es una vista | El cálculo de qué gastos cuentan para el tope vive en la función, y la vista lo presenta para cada año. Finanzas tiene permiso sobre la vista y el rol de consulta tiene DENY, porque son montos. |

```sql
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
```

Con los datos de prueba, 2025 terminó en 91,63 % del tope (con una alerta) y 2026 va en 89,47 %, todavía sin alerta.

## Procedimientos

Están en [scripts/05_procedimientos.sql](../scripts/05_procedimientos.sql). Todos siguen la misma estructura, la que usamos en clase:

```sql
create or alter procedure usp_ejemplo
    @param int
as
begin
    set nocount on
    set xact_abort on

    begin try
        if not exists (select 1 from Tabla where id = @param)
            raiserror('el registro %d no existe', 16, 1, @param)

        begin transaction

        insert into ...

        commit transaction

        print 'listo'
        return 0
    end try
    begin catch
        if xact_state() <> 0
            rollback transaction

        print 'error: ' + error_message()
        return 1
    end catch
end
```

Primero se valida todo lo que se puede validar sin tocar datos. Cada validación que falla corta con `raiserror` y salta al `catch`. Recién después se abre la transacción y se modifica. Si algo falla adentro (una restricción, un trigger que rechaza), el `catch` deshace lo que haya quedado abierto. `set xact_abort on` hace que cualquier error marque la transacción para deshacerse entera, así no queda nada a medias. El procedimiento devuelve 0 si salió bien y 1 si no, y el que lo llama puede preguntar por ese valor.

### usp_cargar_resultado

| | |
|---|---|
| Parámetros | `@idsesion int`, `@idinsc int`, `@pos tinyint = null`, `@estado nvarchar(15) = 'Finalizo'` |
| Qué hace | Carga el resultado de un piloto inscripto en una sesión. |
| Validaciones | Que la sesión exista, que la inscripción exista, que las dos sean del mismo Gran Premio (RN10) y que ese piloto no tenga ya un resultado en la sesión. Que la posición sea coherente con el estado y que no se repita lo controlan el CHECK y el índice filtrado de Resultado (RN11). |
| Qué modifica | Inserta una fila en Resultado. |
| Errores | Cada validación tiene su mensaje. Si salta el CHECK o el índice, el `catch` muestra el mensaje de SQL Server, que nombra la restricción, y devuelve 1. |

RN10 no se puede escribir como restricción sin agregarle `id_gp` a Resultado, y eso sería una dependencia transitiva (rompe la 3FN). Por eso se controla acá, y los permisos hacen que este procedimiento sea la única forma de cargar un resultado (RN22).

### usp_inscribir_piloto

| | |
|---|---|
| Parámetros | `@idgp int`, `@idpiloto int`, `@idchasis int` |
| Qué hace | Inscribe a un piloto en un Gran Premio con un chasis. |
| Validaciones | Que el Gran Premio exista y no esté cerrado, que el piloto exista, que tenga contrato vigente en la fecha del Gran Premio (RN04, con `fn_contrato_vigente`), que el Gran Premio tenga menos de dos inscriptos (RN03) y que el chasis exista y sea de la misma temporada (RN06). El mismo piloto dos veces o el mismo chasis para dos pilotos los frenan los UNIQUE de Inscripcion (RN05). |
| Qué modifica | Inserta una fila en Inscripcion. |
| Errores | Igual que el anterior: mensaje propio por cada validación, y el de SQL Server si salta un UNIQUE. |

### usp_retirar_componente

| | |
|---|---|
| Parámetros | `@idcomp int`, `@danada bit = 0` |
| Qué hace | Saca una pieza de servicio. La deja en 'Retirado' si llegó a su vida útil o en 'Danado' si se rompió. |
| Validaciones | Que la pieza exista y que no esté ya retirada. |
| Qué modifica | El estado de la pieza en Componente. |
| Errores | Es el más simple. Hace un solo UPDATE, así que no necesita transacción propia. Avisa con `print` y devuelve 1, como el ejemplo de RETURN que vimos en clase. |

Lo llama el cierre de Gran Premio para cada pieza que llega a su vida útil, y mira lo que devuelve. Si no es 0, el cierre corta con `raiserror` y se deshace todo.

### usp_cerrar_gp

| | |
|---|---|
| Parámetros | `@idgp int` |
| Qué hace | Cierra un Gran Premio: a cada pieza usada le suma los km, pasa las nuevas a 'En uso', retira las que llegaron a su vida útil y marca el Gran Premio como cerrado (RN14). Es el procedimiento del cursor, que se explica más abajo. |
| Validaciones | Que el Gran Premio exista y que no estuviera cerrado (RN15). |
| Qué modifica | `km_acumulados` y `estado` en Componente, y `cerrado` en GranPremio. |
| Errores | Todo pasa en una sola transacción. Si falla el retiro de una pieza, no queda ningún km sumado ni el Gran Premio cerrado. |

Es el único que modifica `km_acumulados`, que es la desnormalización explicada en la normalización. Ningún rol tiene permiso de UPDATE sobre Componente.

### usp_registrar_compra

| | |
|---|---|
| Parámetros | `@idtipo int`, `@serie nvarchar(30)`, `@fecha date`, `@monto decimal(14,2)`, `@descr nvarchar(200)`, `@idcat int`, `@idprov int` |
| Qué hace | Da de alta una pieza nueva y el gasto de su compra, juntos. |
| Validaciones | Que el monto sea mayor a 0 y que el tipo de pieza, la categoría y el proveedor existan. El número de serie repetido lo frena el UNIQUE de Componente, y el tope (RN19) el trigger de Gasto. |
| Qué modifica | Inserta en Componente y en Gasto, y si el gasto cruza el umbral el trigger inserta en AlertaTope. |
| Errores | Es donde más importa la transacción: si el trigger rechaza el gasto por el tope, la pieza tampoco queda creada. Lo prueba el script de pruebas con la caja GBX-26-04. |

El id de la pieza nueva se toma con `scope_identity()` y no con `@@identity`. `@@identity` devuelve el último id generado en la conexión, y como el trigger de Gasto puede insertar una alerta, podría devolver el id de la alerta.

### usp_registrar_gasto

| | |
|---|---|
| Parámetros | `@fecha date`, `@monto decimal(14,2)`, `@descr nvarchar(200)`, `@idcat int`, `@idprov int` |
| Qué hace | Registra un gasto que no es la compra de una pieza (fletes, viajes, hospitalidad). |
| Validaciones | Que el monto sea mayor a 0 y que la categoría y el proveedor existan. El tope lo controla el trigger. |
| Qué modifica | Inserta en Gasto, y el trigger puede insertar en AlertaTope. |
| Errores | Si el trigger lo rechaza (año sin tope o se pasa del tope), el `catch` lo muestra y devuelve 1. |

## Triggers

Están en [scripts/06_triggers.sql](../scripts/06_triggers.sql). Los cuatro son AFTER y trabajan con toda la tabla `inserted`, no con una sola fila: si un INSERT trae varias filas y una rompe la regla, se rechaza el INSERT completo.

Cuando rechazan algo hacen `rollback transaction`, después `raiserror` y `return`. Así se deshace la operación que los disparó y el mensaje que llega es el nuestro.

Usamos triggers para las reglas que tienen que valer siempre, venga de donde venga el cambio. Las tablas donde los roles escriben directo (Sesion, Contrato, UsoComponente) quedan protegidas igual que si usaran un procedimiento. Y en Gasto, aunque solo se escribe por procedimiento, el control del tope está en el trigger para que valga también para el administrador.

### tr_Sesion_validar

| | |
|---|---|
| Evento | AFTER INSERT, UPDATE |
| Tabla | Sesion |
| Condición | Alguna sesión nueva o modificada es de un tipo sprint en un Gran Premio sin formato sprint, o su fecha cae fuera del fin de semana del Gran Premio. |
| Acción | Deshace la operación y avisa cuál de las dos reglas se rompió. |
| Regla | RN01 y RN02 |

Un CHECK no sirve porque las dos reglas miran datos de otras tablas (TipoSesion y GranPremio).

### tr_Contrato

| | |
|---|---|
| Evento | AFTER INSERT, UPDATE |
| Tabla | Contrato |
| Condición | El contrato se superpone con otro del mismo empleado, o dice titular/reserva y el empleado no es piloto, o es de un piloto y no lo dice. |
| Acción | Si se rompe alguna regla, deshace y avisa. Si no, por cada contrato al que le cambió el sueldo inserta una fila en AuditoriaContrato con el sueldo anterior (de `deleted`) y el nuevo (de `inserted`). La fecha y el usuario los pone el default de la tabla. |
| Regla | RN07, RN08 y RN09 |

Para la superposición, un contrato sin fecha de fin se compara como si terminara el 31/12/9999. Recursos Humanos modifica Contrato directo, y el trigger asegura que ningún cambio de sueldo quede sin registrar.

### tr_UsoComponente

| | |
|---|---|
| Evento | AFTER INSERT |
| Tabla | UsoComponente |
| Condición | Se usa una pieza retirada o dañada, o el Gran Premio ya está cerrado. Y para las penalizaciones: una pieza que se usa por primera vez hace que el piloto pase el límite de su tipo en la temporada. |
| Acción | En los dos primeros casos deshace y avisa. Si no, inserta en Penalizacion una fila por cada pieza de más: 10 puestos la primera y 5 cada una de las siguientes. |
| Regla | RN13, RN15 y RN16 |

Las penalizaciones son lo más complicado de los cuatro triggers, porque un mismo INSERT puede traer varias piezas:

1. En la variable tabla `@nuevas` guarda las piezas que se usan por primera vez (las que no tienen usos fuera de este INSERT). Una pieza que ya se venía usando no cuenta como nueva.
2. Para cada pieza nueva cuenta cuántas piezas distintas de ese tipo tenía el piloto en la temporada antes de este INSERT, y le suma su orden entre las nuevas del mismo piloto y tipo (`row_number`). Ese es el número de pieza en la temporada.
3. Si ese número pasa el límite de LimiteComponente, inserta la penalización. Si el número es justo el límite más uno, es la primera de más y lleva 10 puestos. Las siguientes llevan 5.

Así, si en un mismo INSERT entran dos MGU-K que pasan el límite, el primero recibe 10 puestos y el segundo 5. El script de pruebas lo hace con Hadjar.

### tr_Gasto_tope

| | |
|---|---|
| Evento | AFTER INSERT, UPDATE |
| Tabla | Gasto |
| Condición | El año del gasto no tiene tope cargado, o con el gasto el total computable del año pasa el tope. Y para la alerta: el gasto hace cruzar el porcentaje de aviso. |
| Acción | En los dos primeros casos deshace y avisa. Si no, y es un INSERT, inserta en AlertaTope el gasto que cruzó el umbral y el acumulado del año en ese momento. |
| Regla | RN19 y RN20, con el cálculo de RN18 |

Para las alertas el trigger necesita saber cuánto se llevaba gastado en el momento de cada gasto del INSERT. Lo calcula así: el total computable del año (que ya incluye todo el INSERT) menos lo que suman las filas del INSERT, más la suma acumulada hasta esa fila (`sum() over` ordenado por `id_gasto`). La alerta va solo en el gasto que cruza: el acumulado con él llega al umbral y sin él no llegaba. Solo cuentan las categorías con `computa_tope = 1`.

Las alertas salen de los INSERT. Un UPDATE se controla contra el tope pero no genera alerta, porque en el modelo los gastos no se corrigen: Finanzas no tiene permiso de UPDATE sobre Gasto.

## Cursor

Está dentro de `usp_cerrar_gp`.

| | |
|---|---|
| Problema | Al cerrar un Gran Premio hay que pasar por cada pieza que se usó, sumarle los km que hizo y, si llegó a su vida útil, retirarla. |
| Por qué un cursor | Para cada pieza que llega a su vida útil hay que ejecutar otro procedimiento, `usp_retirar_componente`, y mirar lo que devuelve. Con un UPDATE se podrían sumar los km de todas las piezas de una vez, pero no se puede hacer un EXEC por cada fila. Además el retiro queda en un solo lugar: si mañana cambia cómo se retira una pieza, el cierre no hay que tocarlo. |
| Registros que recorre | Los usos (UsoComponente) de las inscripciones de ese Gran Premio, con la pieza y los km. Son dos pilotos con unas cuatro piezas cada uno, así que ir fila por fila no cuesta nada. |
| Qué hace con cada uno | Le suma los km a la pieza y la pasa de 'Nuevo' a 'En uso'. Si con eso llegó a la vida útil de su tipo, ejecuta el retiro. Si el retiro devuelve algo distinto de 0, corta con `raiserror` y se deshace todo el cierre. |

```sql
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
```

Está declarado `local`, así solo existe dentro del procedimiento, y `fast_forward`, que es de solo lectura y solo para adelante: es lo único que necesita y es el más liviano.

Con los datos de prueba, cerrar Mónaco recorre 8 usos. La caja GBX-26-01 tenía 3200 km, hizo 540 más y pasó los 3500 de vida útil, así que el cursor la retira.

## Funciones

Están en [scripts/03_funciones.sql](../scripts/03_funciones.sql). Cuatro son escalares y una es de tabla.

### fn_puntos_piloto

| | |
|---|---|
| Objetivo | Los puntos de un piloto en una temporada. Como los puntos no se guardan (RN12), hay que calcularlos. |
| Parámetros | `@idpiloto int`, `@anio smallint` |
| Retorno | `int` |
| Lógica | Suma los puntos de Puntaje cruzando cada resultado del piloto por temporada, tipo de sesión y posición. Si no sumó nada devuelve 0 en vez de NULL. |
| Ejemplo | `select dbo.fn_puntos_piloto(1, 2026)` devuelve 111, los puntos de Verstappen. |

```sql
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
    inner join Puntaje p on p.anio = g.anio
                        and p.id_tipo_sesion = s.id_tipo_sesion
                        and p.posicion = r.posicion
    where i.id_piloto = @idpiloto
      and g.anio = @anio

    return isnull(@pts, 0)
end
```

### fn_contrato_vigente

| | |
|---|---|
| Objetivo | Saber qué contrato tenía vigente un empleado en una fecha. |
| Parámetros | `@idemp int`, `@fecha date` |
| Retorno | `int`: el id del contrato, o NULL si en esa fecha no tenía |
| Lógica | Busca el contrato que empezó antes o en esa fecha y que no tiene fin o termina después. Como RN07 no deja contratos superpuestos, hay uno o ninguno. |
| Ejemplo | `select dbo.fn_contrato_vigente(3, '2025-06-01')` devuelve 3 y con `'2026-06-01'` devuelve 4: Tsunoda pasó de titular a reserva. `select dbo.fn_contrato_vigente(4, '2026-06-01')` devuelve NULL, Ferraro ya no tiene contrato. |

```sql
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
```

La usan `usp_inscribir_piloto` (RN04), `vw_nomina` y dos de las subconsultas.

### fn_km_restantes

| | |
|---|---|
| Objetivo | Cuántos km le quedan a una pieza antes de llegar a su vida útil. |
| Parámetros | `@idcomp int` |
| Retorno | `decimal(10,2)` |
| Lógica | Vida útil del tipo menos km acumulados. Si da negativo devuelve 0. |
| Ejemplo | `select dbo.fn_km_restantes(9)` devuelve 300 (la caja GBX-26-01). |

```sql
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
```

### fn_gasto_computable

| | |
|---|---|
| Objetivo | El gasto de un año que cuenta para el tope (RN18). |
| Parámetros | `@anio smallint` |
| Retorno | `decimal(14,2)` |
| Lógica | Suma los gastos del año que son de categorías con `computa_tope = 1`. |
| Ejemplo | `select dbo.fn_gasto_computable(2026)` devuelve 192.350.000. |

```sql
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
```

La usan el trigger del tope y la vista del tope. Que el cálculo esté en un solo lugar asegura que los dos digan lo mismo.

### fn_piezas_piloto

| | |
|---|---|
| Objetivo | Para un piloto y una temporada, cuántas piezas de cada tipo usó, cuál es el límite y cuántas le quedan. |
| Parámetros | `@idpiloto int`, `@anio smallint` |
| Retorno | Una tabla con `tipo`, `limite`, `usadas` y `disponibles` (función de tabla en línea) |
| Lógica | Arranca de los límites de ese año, así aparecen también los tipos que el piloto todavía no usó, y les une con `left join` cuántas piezas distintas de cada tipo usó. Si `disponibles` da negativo, el piloto ya se pasó. |
| Ejemplo | `select * from dbo.fn_piezas_piloto(1, 2026)` devuelve los cuatro tipos. En MGU-K dice límite 3, usadas 4 y disponibles -1. |

```sql
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
```

Es una función de tabla y no una vista porque necesita parámetros, y una vista no los recibe.
