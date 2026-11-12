# Conclusiones

## Las decisiones que más pesaron

Modelar una sola escudería y no el campeonato. Lo interesante del dominio es la gestión interna: las piezas, los contratos y el tope de gasto. Con los rivales adentro la base hubiera sido mucho más grande sin sumar ninguna regla nueva. El costo es que no hay tabla de posiciones, solo los puntos de nuestros pilotos y del equipo.

No guardar los puntos. Salen de cruzar cada resultado con la tabla Puntaje de esa temporada. Si cambia el reglamento se cambia una tabla y no hay que tocar ningún resultado.

Guardar los km de cada pieza aunque se puedan calcular. Es la única excepción a la 3FN y la hicimos a propósito, porque el cierre de Gran Premio decide con ese dato si retira una pieza. Para que no pueda quedar mal, solo lo cambia `usp_cerrar_gp` y ningún rol tiene permiso para tocarlo.

Colgar todo de la inscripción. Los resultados, los usos de piezas y las penalizaciones apuntan a Inscripcion y no al piloto. Así cada dato sabe de qué Gran Premio es y con qué chasis se corrió, sin repetir esas columnas.

Elegir el mecanismo más simple que alcanza. Si una regla se podía escribir como restricción, fue restricción (un CHECK, un UNIQUE, un índice filtrado). Si tenía que valer siempre y miraba otras tablas, trigger. Si era una operación con varios pasos o con validaciones previas, procedimiento, y los permisos obligan a usarlo. El cursor quedó solo en el cierre de Gran Premio, que es el único lugar donde hace falta ejecutar algo por cada fila.

Armar los datos de prueba para las reglas y no al revés. Verstappen ya tiene un MGU-K de más, Hadjar está a uno del límite, 2026 va en 89,47 % del tope y una caja de cambios está a 300 km de su vida útil. Así cada regla se puede ver saltar con una o dos instrucciones.

## Qué cambiaríamos

- El uso de piezas se registra por Gran Premio. Si se registrara por sesión se podría saber, por ejemplo, en qué sesión se rompió una pieza. Lo dejamos así porque el reglamento cuenta las piezas por temporada y el cierre suma los km una vez por Gran Premio.
- Los sueldos no cuentan para el tope. En la F1 real la mayoría sí cuenta (quedan afuera los pilotos y los tres sueldos más altos del equipo). Se podría agregar con una categoría de gasto para sueldos que se cargue todos los meses.
- Las alertas del tope solo salen cuando se inserta un gasto. Si en algún momento se permitiera corregir montos, el trigger también tendría que revisar los UPDATE.
- Todos nuestros errores salen con el número 50000. Para el TP alcanza con el mensaje, pero si arriba de la base hubiera una aplicación, convendría que cada error tuviera su propio número para que la aplicación los distinga sin leer el texto.
- Todo está en dólares y no hay tipo de cambio. Muchos proveedores son europeos, así que en una base de verdad haría falta.

## Qué aprendimos

Que un trigger se dispara una vez por instrucción, no una vez por fila. Hay que pensar `inserted` como una tabla. El caso más claro es el de las penalizaciones: si un mismo INSERT trae dos piezas de más, la primera tiene que llevar 10 puestos y la segunda 5, y eso solo sale bien si se cuentan todas juntas.

Que un CHECK no falla cuando la condición da desconocido. `posicion > 0` con la posición en NULL no da falso, da desconocido, y el CHECK lo deja pasar. Por eso `CK_Resultado_posicion` dice `posicion is not null` de forma explícita.

Que con el encadenamiento de propiedad un DENY sobre una tabla no impide escribir en ella a través de un procedimiento del mismo dueño. Con eso se arma todo el esquema de "solo por procedimiento" sin darle a nadie permisos sobre las tablas.

Que una transacción sirve si se piensa qué pasa cuando algo falla a la mitad. En la compra de una pieza, si el gasto se rechaza, la pieza que ya se había insertado tiene que desaparecer también.

Y que tener las reglas en la base y no en una aplicación cambia la forma de pensar el diseño. No alcanza con que el camino normal funcione: hay que pensar qué pasa si alguien entra por otro lado, y cerrar ese lado con un trigger o con un permiso.
