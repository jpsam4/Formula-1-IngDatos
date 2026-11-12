# Normalización

Para mostrar el proceso partimos de tres planillas que alguien de la escudería podría tener hoy en un Excel, y las llevamos paso a paso hasta 3FN. Después revisamos FNBC y que las descomposiciones no pierdan información (Rissanen).

Repaso rápido de lo que usamos:

- Una dependencia funcional A → B quiere decir que si conocemos A conocemos B. Por ejemplo Circuito → País, cada circuito está en un solo país.
- 1FN: cada celda tiene un solo valor y no hay grupos repetidos.
- 2FN: está en 1FN y ningún atributo que no es clave depende de una parte de la clave. Solo puede fallar con claves compuestas.
- 3FN: está en 2FN y ningún atributo que no es clave depende de otro atributo que tampoco es clave (dependencia transitiva).


## Planilla 1: un fin de semana de carrera

Así la tendría alguien que anota los resultados del equipo:

| Gran Premio | Fecha | Circuito | País | Sesiones | Piloto | N.º auto | Posiciones |
|---|---|---|---|---|---|---|---|
| GP de Mónaco 2026 | 2026-06-07 | Montecarlo | Mónaco | FP1, FP2, FP3, Clasificación, Carrera | Pérez | 11 | 5, 7, 4, 6, 6 |
| GP de Mónaco 2026 | 2026-06-07 | Montecarlo | Mónaco | FP1, FP2, FP3, Clasificación, Carrera | Gómez | 27 | 3, 2, 2, 1, 2 |

No está en 1FN. Sesiones y Posiciones tienen varios valores en la misma celda, y la posición de cada sesión depende del orden en que se escribió, cosa que nadie controla.

### 1FN

Armamos una fila por Gran Premio, sesión y piloto. De paso agregamos la temporada, la hora de cada sesión, el estado (si terminó o no) y los puntos, que hoy alguien calcula a mano.

| Gran Premio | Temporada | Fecha | Circuito | País | Sesión | Hora | Piloto | N.º auto | Posición | Estado | Puntos |
|---|---|---|---|---|---|---|---|---|---|---|---|
| GP de Mónaco 2026 | 2026 | 2026-06-07 | Montecarlo | Mónaco | Carrera | 15:00 | Pérez | 11 | 6 | Finalizó | 8 |
| GP de Mónaco 2026 | 2026 | 2026-06-07 | Montecarlo | Mónaco | Carrera | 15:00 | Gómez | 27 | 2 | Finalizó | 18 |
| GP de Mónaco 2026 | 2026 | 2026-06-07 | Montecarlo | Mónaco | Clasificación | 16:00 | Pérez | 11 | 6 | Finalizó | 0 |

Clave: (Gran Premio, Sesión, Piloto).

Dependencias funcionales:

- Gran Premio → Temporada, Fecha, Circuito
- Circuito → País
- (Gran Premio, Sesión) → Hora
- Piloto → N.º auto
- (Gran Premio, Sesión, Piloto) → Posición, Estado
- (Temporada, Sesión, Posición) → Puntos

La última es la importante. Los puntos no dependen de quién corrió sino de la posición, del tipo de sesión y del reglamento de ese año.

Con la planilla así aparecen las tres anomalías:

- Modificación: si cambia el país de un circuito o el número de un piloto, hay que corregirlo en cientos de filas. Si se nos pasa una, quedan datos contradictorios.
- Inserción: no se puede cargar un circuito nuevo hasta que se corra una carrera ahí, ni un piloto antes de su primer resultado.
- Borrado: si borramos el único Gran Premio que se corrió en un circuito, perdemos el circuito y su país.

Y una cuarta que es propia de este caso: si la FIA cambia la tabla de puntos, hay que recalcular a mano todos los resultados de la temporada.

### 2FN

Sacamos lo que depende de una parte de la clave:

- GranPremio (**Gran Premio**, Temporada, Fecha, Circuito, País), por Gran Premio → ...
- Sesion (**Gran Premio, Sesión**, Hora), por (Gran Premio, Sesión) → Hora
- Piloto (**Piloto**, N.º auto), por Piloto → N.º auto
- Resultado (**Gran Premio, Sesión, Piloto**, Posición, Estado, Puntos)

### 3FN

Quedan dos dependencias transitivas:

- En GranPremio, País depende de Circuito, que no es clave. Sale Circuito (**Circuito**, País) y GranPremio se queda con Circuito como referencia.
- En Resultado, Puntos depende de (Temporada, Sesión, Posición). La temporada sale del Gran Premio, así que Puntos depende de la posición y no de la clave entera. Sale Puntaje (**Temporada, Sesión, Posición**, Puntos) y Resultado ya no guarda los puntos.

Resultado sin los puntos queda (**Gran Premio, Sesión, Piloto**, Posición, Estado). Los puntos se calculan cuando hacen falta, juntando Resultado con su Gran Premio (para saber la temporada) y con Puntaje. Eso hace la función `fn_puntos_piloto`.

Antes de pasar a tablas hicimos tres cambios más, que no son de normalización sino de diseño:

1. "Clasificación", "Carrera", "Sprint" se repetían como texto. Pasaron a un catálogo, TipoSesion, que además dice si la sesión es sprint y si da puntos.
2. El par (Gran Premio, Piloto) se convirtió en Inscripcion, porque la parte técnica necesita saber con qué chasis corrió cada piloto en cada GP. Resultado apunta a la inscripción en vez de al par.
3. Reemplazamos los nombres por claves numéricas (`id_gp`, `id_circuito`, ...).



## Planilla 2: las piezas por temporada

| Tipo de pieza | Temporada | Vida útil (km) | Máximo por temporada |
|---|---|---|---|
| Motor | 2026 | 7000 | 4 |
| Motor | 2027 | 7000 | 3 |
| Caja de cambios | 2026 | 9000 | 5 |

Está en 1FN. La clave es (Tipo, Temporada).

Dependencias:

- (Tipo, Temporada) → Máximo, porque el reglamento cambia el límite de un año a otro
- Tipo → Vida útil

La vida útil depende solo del tipo, o sea de una parte de la clave. Es una dependencia parcial y la planilla no está en 2FN. Se ve en la tabla: el 7000 del motor está repetido, y si en algún momento cambia hay que tocarlo en todas las temporadas. Tampoco se puede cargar un tipo de pieza nuevo hasta saber su límite para algún año.

Separamos:

- TipoComponente (**Tipo**, Vida útil)
- LimiteComponente (**Tipo, Temporada**, Máximo)

Las dos quedan en 3FN porque no tienen atributos no clave que dependan entre sí. Es el ejemplo más claro de 2FN que tenemos.


## Planilla 3: los gastos

| N.º gasto | Fecha | Monto (USD) | Proveedor | Identificación fiscal | País del proveedor | Categoría | ¿Cuenta para el tope? |
|---|---|---|---|---|---|---|---|
| 1 | 2026-03-02 | 120000 | Frenos Tirreno | IT-0001 | Italia | Frenos | Sí |
| 2 | 2026-03-09 | 45000 | Frenos Tirreno | IT-0001 | Italia | Frenos | Sí |
| 3 | 2026-03-10 | 8000 | Logística Austral | AR-3312 | Argentina | Fletes | No |

Clave: N.º gasto. Como la clave es simple está en 2FN automáticamente.

Dependencias:

- N.º gasto → Fecha, Monto, Proveedor, Categoría
- Proveedor → Identificación fiscal, País del proveedor
- Identificación fiscal → Proveedor
- Categoría → ¿Cuenta para el tope?

Hay dos dependencias transitivas: los datos del proveedor dependen del proveedor y "¿Cuenta para el tope?" depende de la categoría. Ninguno de los dos es clave de la planilla.

Las anomalías: si un proveedor cambia de país hay que corregir todos sus gastos, no se puede dar de alta un proveedor sin haberle comprado algo, y si alguien marca "No" en un gasto de Frenos y "Sí" en otro, la planilla no sabe cuál vale.

En 3FN queda:

- Gasto (**N.º gasto**, Fecha, Monto, Proveedor, Categoría)
- Proveedor (**Proveedor**, Identificación fiscal, País)
- CategoriaGasto (**Categoría**, Cuenta para el tope)

Las alertas del tope salen del mismo razonamiento. Al principio AlertaTope tenía año y porcentaje. El año sale de la fecha del gasto (id_gasto → fecha → año), es una transitiva, así que lo sacamos. El porcentaje es gasto acumulado dividido el tope del año, o sea un dato calculado, y se muestra en la vista `vw_situacion_tope`.


## FNBC

La definición que vimos en la clase 13: una relación está en FNBC si para cada dependencia funcional no trivial X → Y, X es una superclave.

Revisamos las tablas finales que tienen más de una clave candidata, que es donde puede fallar:

- Inscripcion. Tiene tres claves candidatas: `id_inscripcion`, (`id_gp`, `id_piloto`) y (`id_gp`, `id_chasis`). Todas las dependencias salen de alguna de ellas. Está en FNBC.
- Resultado. La clave es (`id_sesion`, `id_inscripcion`). Además, para los que terminaron, (`id_sesion`, `posicion`) → `id_inscripcion`, porque no puede haber dos pilotos en la misma posición. Eso también es una clave (está garantizada con un índice único filtrado), así que sigue en FNBC.
- Puntaje, LimiteComponente, UsoComponente: el único determinante es la clave compuesta. FNBC.
- Proveedor: `id_proveedor` e `identificacion_fiscal` son claves candidatas y se determinan entre sí. FNBC.
- GranPremio: este no está en FNBC y lo dejamos así a propósito, está explicado más abajo.

El resto de las tablas tiene una sola clave y todo depende de ella, así que 3FN y FNBC coinciden.



## Rissanen: que no se pierda nada al separar

En la clase vimos que una descomposición de R en R1 y R2 es independiente si y solo si:

1. Toda dependencia funcional de R se puede deducir de las dependencias de R1 y R2, y
2. Los atributos comunes de R1 y R2 forman una clave candidata de al menos una de las dos.

La segunda condición es la que asegura que al hacer el JOIN volvemos a tener exactamente los datos de antes. Lo revisamos en cada separación:

| Original | R1 | R2 | Atributos comunes | ¿Clave de cuál? | ¿Se conservan las dependencias? |
|---|---|---|---|---|---|
| GranPremio (planilla 1) | GranPremio (GP, Temporada, Fecha, Circuito) | Circuito (Circuito, País) | Circuito | de Circuito | Sí. GP → Circuito queda en R1 y Circuito → País en R2 |
| Resultado (planilla 1) | Resultado (GP, Sesión, Piloto, Posición, Estado) | Puntaje (Temporada, Sesión, Posición, Puntos) | Sesión, Posición, y la temporada a través del GP | de Puntaje | Sí, ver abajo |
| Planilla 2 | TipoComponente (Tipo, Vida útil) | LimiteComponente (Tipo, Temporada, Máximo) | Tipo | de TipoComponente | Sí. Tipo → Vida útil en R1 y (Tipo, Temporada) → Máximo en R2 |
| Planilla 3 | Gasto (..., Proveedor, Categoría) | Proveedor (Proveedor, Id. fiscal, País) | Proveedor | de Proveedor | Sí |
| Planilla 3 | Gasto (..., Categoría) | CategoriaGasto (Categoría, Cuenta) | Categoría | de CategoriaGasto | Sí |

El caso de Resultado y Puntaje es el único que no es directo, porque la temporada no está en Resultado. Si lo separamos primero con el Gran Premio, R2 = (GP, Sesión, Posición, Puntos), los atributos comunes son (GP, Sesión, Posición), que es clave de R2, y cumple Rissanen. Después cambiamos GP por su temporada en R2, porque los puntos son los mismos para todos los Grandes Premios de un año. Como GP → Temporada está en GranPremio, el JOIN Resultado ⋈ GranPremio ⋈ Puntaje devuelve los mismos puntos que tenía la planilla.



## Excepciones a propósito

Hay dos lugares donde no seguimos la normalización al pie de la letra. Los dejamos así sabiendo lo que hacemos.

### Los km acumulados de cada pieza

Componente guarda `km_acumulados`, aunque se podría calcular sumando los km de esa pieza en UsoComponente. Es una desnormalización: el mismo dato está en dos lugares.

La hacemos porque el estado de las piezas se consulta todo el tiempo, y porque el cierre de cada Gran Premio decide si retira una pieza según esos km. Sumar todo el historial cada vez no tiene sentido.

El riesgo es que el número guardado no coincida con la suma real. Lo controlamos así:

- Solo el procedimiento `usp_cerrar_gp` modifica ese campo, una vez por Gran Premio.
- Ningún rol tiene permiso de UPDATE directo sobre Componente.
- Un Gran Premio cerrado no acepta más usos de piezas (RN15), así que lo que se sumó no cambia después.

En el DER `km_acumulados` aparece como atributo derivado por esto mismo.

### El año del Gran Premio

GranPremio tiene `anio` (la temporada) y `fecha_inicio`. Como una temporada es un año calendario, `fecha_inicio` → `anio`, y `fecha_inicio` no es superclave. Por eso la tabla no está en FNBC.

Igual sí está en 3FN. `anio` forma parte de la clave candidata (`anio`, `ronda`), y 3FN solo prohíbe que dependan transitivamente los atributos que no son parte de ninguna clave.

Lo dejamos porque `anio` es la clave foránea a Temporada y es lo que permite decir "la ronda 8 de 2026" con un UNIQUE. Para que el dato repetido no pueda contradecirse le pusimos un CHECK: `YEAR(fecha_inicio) = anio`.



## De dónde sale cada tabla

| Tabla | Sale de |
|---|---|
| Pais, Circuito, GranPremio, Temporada | planilla 1 (3FN de la parte del Gran Premio) |
| Sesion, TipoSesion | planilla 1 (2FN más el catálogo de tipos) |
| Resultado, Puntaje | planilla 1 (3FN de los resultados) |
| Inscripcion | planilla 1, el par (Gran Premio, Piloto) con el chasis |
| Empleado, Piloto | planilla 1 (Piloto → N.º auto), ampliado con los datos de personal |
| TipoComponente, LimiteComponente | planilla 2 |
| Gasto, Proveedor, CategoriaGasto, AlertaTope | planilla 3 |
| Puesto, Contrato, AuditoriaContrato | no salen de una planilla. Las armamos directo desde el alcance, y ya nacen normalizadas (cada una tiene una clave simple y nada depende de otra cosa que la clave) |
| Chasis, Componente, UsoComponente, Penalizacion, TopePresupuestario | lo mismo, salen del alcance y del DER |
