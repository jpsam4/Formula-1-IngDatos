# Descripción del sistema y alcance

## Descripción del sistema

Es una base de datos para la gestión interna de una escudería de Fórmula 1. Elegimos Red Bull Racing. Registra lo que pasa en cada Gran Premio, quién trabaja en el equipo y con qué contrato, qué piezas usa cada auto y cuánto gasta la escudería en el año. Ademas de guardar esos datos hace cumplir las reglas del reglamento y del equipo, como el límite de piezas por temporada o el tope de gasto anual.

## Contexto

Una escudería de F1 corre unos 24 Grandes Premios por temporada con dos autos. Cada Gran Premio se corre en un fin de semana con varias sesiones: prácticas, clasificación y carrera, y en algunos fines de semana además una clasificación sprint y una carrera sprint. Las sesiones que reparten puntos lo hacen según la posición de llegada.

Para correr, la escudería tiene que resolver tres cosas además de las carreras.


La primera es el personal. Hay pilotos, ingenieros, mecánicos y administrativos, todos con contrato. De los pilotos, dos son titulares y suele haber uno de reserva.

La segunda son las piezas. El reglamento limita cuántas piezas de cada tipo (motor, caja de cambios, etc.) puede usar cada piloto en la temporada. Si se pasa, recibe una penalización en la grilla de largada. Ademas cada pieza tiene una vida útil en kilómetros, y cuando llega a ese número hay que retirarla.

La tercera es la plata. El reglamento fija un tope de gasto anual. Superarlo trae sanciones graves, así que el equipo necesita saber en todo momento cuánto gastó y cuánto le queda.

Hoy todo eso puede estar repartido en planillas sueltas, y en una planilla nada impide cargar a un piloto sin contrato, usar una pieza que ya se retiró o pasarse del tope sin que nadie lo note.

## Objetivo de la base de datos

Centralizar la información deportiva, de personal, técnica y financiera de la escudería, y hacer que la propia base de datos haga cumplir las reglas del reglamento y del equipo. Las reglas viven en la base (restricciones, triggers, procedimientos y permisos) y no en una aplicación. Asi valen para cualquiera que use los datos, por el camino que sea.


## Actores

Cada actor despues se convierte en un rol de seguridad.

| Actor | Qué hace en el sistema |
|---|---|
| Director deportivo | Arma el calendario de sesiones, inscribe a los pilotos en cada Gran Premio y carga los resultados |
| Ingeniero de pista | Registra qué piezas usa cada auto en cada Gran Premio y cierra el Gran Premio cuando termina |
| Recursos Humanos | Da de alta empleados y contratos y actualiza sueldos. Es el único que ve los sueldos |
| Finanzas | Registra las compras y los gastos y sigue el tope anual |
| Consulta | Ve información general (calendario, resultados, nómina sin sueldos), sin modificar nada |

Los datos fijos (países, circuitos, tipos de sesión, tabla de puntos, tipos de pieza, límites por temporada y tope de cada año) los carga el administrador de la base.

## Información a guardar

Parte deportiva:

- Las temporadas y, para cada una, el calendario de Grandes Premios con su número de fecha, el circuito y las fechas del fin de semana. También si ese fin de semana tiene formato sprint.
- Los circuitos, con su ciudad, su país y su longitud.
- Las sesiones de cada Gran Premio, de qué tipo son y cuándo se corren.
- Cuántos puntos da cada posición en cada tipo de sesión. Esto cambia según la temporada
- El resultado de cada piloto en cada sesión: si terminó, en qué posición; si no, por qué (abandono, descalificación o no largó).

Personal:

- Los empleados, con sus datos personales, su nacionalidad y su puesto.
- De los pilotos, además, su número de auto.
- Los contratos de cada empleado: desde cuándo, hasta cuándo (puede no tener fecha de fin), el sueldo mensual y, para los pilotos, si es titular o reserva.
- El historial de cambios de sueldo: cuándo cambió, de cuánto a cuánto y quién lo hizo.

Parte tecnica:

- Los chasis de cada temporada
- Qué piloto corre cada Gran Premio y con qué chasis.
- Los tipos de pieza con su vida útil en kilómetros, y cuántas piezas de cada tipo se permiten por piloto en cada temporada.
- Cada pieza con su número de serie, su tipo, los kilómetros que lleva y su estado (nueva, en uso, retirada o dañada).
- Qué piezas usó cada piloto en cada Gran Premio y cuántos kilómetros hizo con cada una.
- Las penalizaciones de grilla que recibió cada piloto, por qué pieza y de cuántos puestos.

Finanzas:

- Los proveedores, con su identificación fiscal y su país.
- Las categorías de gasto y si cada una cuenta o no para el tope.
- Cada gasto con su fecha, su monto en dólares, su categoría, su proveedor y, si fue la compra de una pieza, cuál.
- El tope de gasto de cada año y el porcentaje a partir del cual hay que dar aviso.
- Las alertas: qué gasto hizo cruzar ese porcentaje y cuánto se llevaba gastado en ese momento.

## Reglas de negocio

Las reglas están numeradas porque cada objeto de la base dice qué regla implementa. La ultima columna es el mecanismo que pensamos usar, se confirma cuando se programe cada objeto.

| Regla | Qué dice | Mecanismo previsto |
|---|---|---|
| RN01 | Las sesiones sprint solo existen en Grandes Premios con formato sprint | Trigger de Sesion |
| RN02 | La fecha de una sesión está dentro del fin de semana de su Gran Premio | Trigger de Sesion |
| RN03 | Un Gran Premio tiene como mucho dos pilotos inscriptos | Procedimiento de inscripción |
| RN04 | Solo se inscribe a un piloto con contrato vigente en la fecha del Gran Premio | Procedimiento de inscripción y función de contrato vigente |
| RN05 | Un chasis no se asigna a dos pilotos en el mismo Gran Premio | UNIQUE en Inscripcion |
| RN06 | El chasis inscripto es de la misma temporada que el Gran Premio | Procedimiento de inscripción |
| RN07 | Un empleado no tiene dos contratos con fechas superpuestas | Trigger de Contrato |
| RN08 | Solo los contratos de pilotos dicen si el piloto es titular o reserva | Trigger de Contrato |
| RN09 | Todo cambio de sueldo queda registrado con fecha y usuario | Trigger de Contrato |
| RN10 | Un resultado solo se carga para un piloto inscripto en el Gran Premio de esa sesión | Procedimiento de carga de resultados |
| RN11 | Solo los que terminan tienen posición, y no hay dos con la misma posición en una sesión | CHECK e índice único filtrado en Resultado |
| RN12 | Los puntos dependen de la temporada, el tipo de sesión y la posición, y no se guardan en el resultado | Tabla Puntaje y función de puntos |
| RN13 | Si un piloto usa más piezas de un tipo que las permitidas en la temporada, recibe una penalización: 10 puestos la primera vez y 5 por cada pieza siguiente | Trigger de UsoComponente |
| RN14 | Al cerrar un Gran Premio se suman los kilómetros a cada pieza usada, y la pieza que llega a su vida útil se retira | Procedimiento de cierre con cursor |
| RN15 | Un Gran Premio se cierra una sola vez, y cerrado no acepta más usos de piezas | Procedimiento de cierre y trigger de UsoComponente |
| RN16 | Una pieza retirada no se puede volver a usar | Trigger de UsoComponente |
| RN17 | Una pieza tiene como mucho un gasto de compra | Índice único filtrado en Gasto |
| RN18 | Para el tope solo cuentan los gastos de las categorías marcadas | Función de gasto computable |
| RN19 | Se rechaza un gasto que haría pasar el tope del año, y también uno de un año sin tope cargado | Trigger de Gasto |
| RN20 | Un gasto que hace cruzar el porcentaje de aviso queda registrado como alerta | Trigger de Gasto |
| RN21 | Los sueldos solo los ve Recursos Humanos | Vista de nómina y permisos |
| RN22 | Resultado, Inscripcion, Gasto y Componente solo se modifican mediante sus procedimientos | Permisos |

## Procesos principales

1. Armar la temporada. El administrador carga la temporada, su tope, sus límites de piezas y su tabla de puntos. El director deportivo carga los Grandes Premios y sus sesiones.
2. Inscribir a los pilotos. Para cada Gran Premio, el director deportivo inscribe a dos pilotos con contrato vigente, cada uno con un chasis de esa temporada.
3. Correr el fin de semana. El ingeniero de pista registra qué piezas usa cada auto y cuántos kilómetros hace con cada una. Si una pieza nueva pasa el límite de la temporada, el piloto queda penalizado. El director deportivo carga los resultados de cada sesión.
4. Cerrar el Gran Premio. El ingeniero de pista lo cierra: a cada pieza usada se le suman los kilómetros, y las que llegaron a su vida útil se retiran. Después del cierre no se pueden cargar más usos de piezas.
5. Comprar. Finanzas registra cada compra. Si es una pieza, la pieza y su gasto se dan de alta juntos. Si el gasto haría pasar el tope, se rechaza. Si hace cruzar el porcentaje de aviso, queda una alerta.
6. Contratar. Recursos Humanos da de alta empleados y contratos y actualiza sueldos. Cada cambio de sueldo queda registrado.

## Restricciones del sistema

Son los límites que le pusimos al modelo a propósito.


- Es una sola escudería (Red Bull Racing). No guardamos a los equipos rivales, así que no hay tabla de posiciones del campeonato. Lo que sí se puede calcular es cuántos puntos sumó cada uno de nuestros pilotos.
- Todos los montos estan en dólares y no manejamos tipo de cambio.
- El tope se controla sobre los gastos operativos. Los sueldos no entran en el cálculo (en la F1 real la mayoría sí cuenta).
- El uso de piezas se registra por Gran Premio, no por sesión.
- Una temporada coincide con un año calendario.
- Un gasto de un año que no tiene tope cargado se rechaza.

## Relaciones entre los elementos

Cada Gran Premio pertenece a una temporada y se corre en un circuito, y cada circuito está en un país. Un Gran Premio tiene varias sesiones, y cada sesión es de un tipo. La tabla de puntos se define por temporada y tipo de sesión.

Un piloto es un empleado con datos propios. Cada empleado ocupa un puesto, tiene una nacionalidad y firma uno o más contratos a lo largo del tiempo. Cada cambio de sueldo de un contrato queda en su historial.

Un piloto se inscribe en un Gran Premio con un chasis de esa temporada. Esa inscripción es la que después tiene resultados en cada sesión, usos de piezas y penalizaciones. Cada pieza es de un tipo, y cada tipo tiene un límite de piezas por temporada.


Cada gasto es de una categoria y de un proveedor, y puede corresponder a la compra de una pieza. Cada temporada tiene un tope de gasto, y un gasto puede disparar una alerta.
