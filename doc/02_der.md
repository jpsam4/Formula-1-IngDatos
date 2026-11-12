# DER

El DER está hecho en draw.io: [der/der.drawio](der/der.drawio). Tiene cinco pestañas. La primera es el modelo entero sin atributos, para ver cómo se conecta todo, y las otras cuatro son una por área con todos los atributos.

Usamos la notación de Chen que vimos en clase.

## Cómo se lee

- Rectángulo: entidad. Rectángulo doble: entidad débil.
- Rombo: relación. Rombo doble: relación identificadora (la que le da la identidad a una entidad débil).
- Elipse: atributo. Si está subrayado es el identificador de la entidad. Subrayado punteado es la clave parcial de una entidad débil.
- Elipse punteada: atributo derivado, o sea que se puede calcular a partir de otros datos.
- El triángulo es una especialización ("es un").
- En las páginas por área, las cajas grises punteadas son entidades de otra área. Están para que se vea con quién se conecta, sus atributos aparecen en su propia página.

Las cardinalidades van a cada lado del rombo, con 1, N o M. Se leen cruzando: en "GranPremio 1 — tiene — N Sesion" un Gran Premio tiene N sesiones y cada sesión es de 1 Gran Premio. Si los dos lados son muchos se pone N y M.

En "admite" pusimos 2 en vez de N porque un Gran Premio admite como mucho dos inscripciones (los dos autos del equipo).


## Modelo general

![DER general](der/der_general.png)

Son 22 entidades y tres relaciones N:M que tienen atributos propios (Resultado, LimiteComponente y UsoComponente). Cuando se pasa a tablas eso da las 25 tablas del modelo.

## Por área

### Deportiva

![DER deportiva](der/der_deportiva.png)

Temporada se identifica por el año, no le inventamos un id.

Puntaje es débil. Un puntaje solo existe para una temporada y un tipo de sesión, y se identifica por esos dos más la posición (su clave parcial). La tabla de puntos cambia según la temporada y según si es carrera o sprint, por eso depende de las dos.

Resultado es una relación N:M entre Sesion e Inscripcion: en una sesión hay resultados de varios pilotos inscriptos, y un piloto inscripto tiene resultado en varias sesiones del fin de semana. Tiene sus propios atributos, posicion y estado (Finalizó, Abandono, Descalificado, No largó). `puntos` está como derivado porque no lo guardamos, sale de cruzar la posición con Puntaje.

### Personal

![DER personal](der/der_personal.png)

Piloto es una especialización de Empleado. Un piloto es un empleado con un dato más, el número de auto. La marcamos (p,d):

- Parcial, porque hay empleados que no son pilotos (ingenieros, mecánicos, administrativos).
- Disjunta, porque solo hay un subtipo y no se puede ser piloto "dos veces".

AuditoriaContrato es débil, depende de Contrato. Un registro de auditoría no tiene sentido sin el contrato al que le cambiaron el sueldo. Su clave parcial es la fecha y hora del cambio. En la tabla igual le pusimos un `id_auditoria` propio, porque dos cambios en el mismo segundo romperían la clave y un id es más simple de manejar.

### Técnica

![DER técnica](der/der_tecnica.png)

Inscripcion es la entidad que más se conecta. Salió de una relación N:M entre Piloto y GranPremio (un piloto corre muchos GP, un GP lo corren dos pilotos), pero además de unir a los dos lleva el chasis, y de ella cuelgan los resultados, el uso de piezas y las penalizaciones. Por eso la dibujamos como entidad y no como rombo.

El 2 en "admite" es la regla de que corren dos autos por equipo (RN03).

LimiteComponente es N:M entre Temporada y TipoComponente con el atributo cantidad_max: cuántas piezas de ese tipo se permiten en esa temporada.

UsoComponente es N:M entre Componente e Inscripcion. Guarda los km que hizo cada pieza en cada Gran Premio.

`km_acumulados` de Componente está punteado porque es derivado: es la suma de los km de UsoComponente. Igual lo guardamos en la tabla, es una desnormalización hecha a propósito y está explicada en la sección de normalización.

### Finanzas

![DER finanzas](der/der_finanzas.png)

TopePresupuestario es débil respecto de Temporada. Hay un tope por año, y el tope se identifica por el año de su temporada, no tiene identificador propio.

La relación "compra" entre Gasto y Componente es 1 a 1 y opcional de los dos lados. No todo gasto es una pieza (hay fletes, servicios, etc.) y una pieza puede no tener gasto cargado, por ejemplo si vino de una temporada anterior. Lo que no puede pasar es que una pieza tenga dos gastos de compra (RN17).

En AlertaTope el porcentaje es derivado (gasto acumulado sobre el tope del año), así que no lo guardamos. Se calcula en la vista.

## Cardinalidades

| Relación | Entidad | Entidad | Tipo |
|---|---|---|---|
| está en | Pais | Circuito | 1:N |
| se corre en | Circuito | GranPremio | 1:N |
| pertenece a | Temporada | GranPremio | 1:N |
| tiene | GranPremio | Sesion | 1:N |
| es de tipo | TipoSesion | Sesion | 1:N |
| asigna | Temporada | Puntaje | 1:N |
| otorga | TipoSesion | Puntaje | 1:N |
| Resultado | Sesion | Inscripcion | N:M |
| nacionalidad | Pais | Empleado | 1:N |
| ocupa | Puesto | Empleado | 1:N |
| firma | Empleado | Contrato | 1:N |
| registra | Contrato | AuditoriaContrato | 1:N |
| se inscribe | Piloto | Inscripcion | 1:N |
| admite | GranPremio | Inscripcion | 1:2 |
| es de | Temporada | Chasis | 1:N |
| se asigna | Chasis | Inscripcion | 1:N |
| LimiteComponente | Temporada | TipoComponente | N:M |
| clasifica | TipoComponente | Componente | 1:N |
| UsoComponente | Inscripcion | Componente | N:M |
| recibe | Inscripcion | Penalizacion | 1:N |
| origina | Componente | Penalizacion | 1:N |
| fija | Temporada | TopePresupuestario | 1:1 |
| se clasifica | CategoriaGasto | Gasto | 1:N |
| factura | Proveedor | Gasto | 1:N |
| radicado en | Pais | Proveedor | 1:N |
| compra | Componente | Gasto | 1:1 |
| dispara | Gasto | AlertaTope | 1:1 |

En las 1:N la primera entidad es la del lado 1. Casi todas son opcionales del lado de muchos a propósito, así se puede cargar un circuito antes de que tenga Grandes Premios, un puesto antes de contratar a alguien, etc.



Hay dos reglas que el DER no alcanza a mostrar y que se controlan en la base:

- Que el resultado y la inscripción sean del mismo Gran Premio (la sesión es de un GP y la inscripción también, tienen que coincidir). Lo valida el procedimiento de carga de resultados.
- Que el chasis sea de la misma temporada que el Gran Premio (RN06). Lo valida el procedimiento de inscripción.
