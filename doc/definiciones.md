# Definiciones del proyecto

## 1. Dominio del proyecto

**Escudería modelada: Red Bull Racing, temporada 2026.**

- Se modela la gestión interna de **una sola escudería real**: Red Bull Racing. No se modelan las demás escuderías ni el campeonato contra rivales; por eso, en lugar de posiciones de campeonato, se siguen los puntos acumulados del equipo por Gran Premio.
- La base queda **preparada para varias temporadas** (lo que cambia de un año a otro, como el puntaje, los límites de piezas y el tope presupuestario, se define por año) y se **carga con la temporada 2026**.
- La gestión se divide en cuatro áreas:
  - **Deportiva:** calendario de Grandes Premios, circuitos, sesiones, resultados y puntaje.
  - **Personal:** puestos, empleados, pilotos y contratos, con auditoría de los cambios de sueldo.
  - **Técnica:** chasis, inscripciones a cada Gran Premio, componentes y su uso, límites por temporada y penalizaciones.
  - **Finanzas:** proveedores, gastos por categoría, tope presupuestario anual y alertas.
- Todos los montos se expresan en **dólares estadounidenses (USD)**.

## 2. Motor de base de datos

**El proyecto se desarrolla sobre Microsoft SQL Server 2025.**

- Todos los scripts se escriben en T-SQL y se prueban sobre SQL Server 2025.
- Herramienta de trabajo: SQL Server Management Studio (SSMS).
- Cada integrante tiene una instancia local de SQL Server 2025, para poder correr el script completo desde cero en su máquina.

Motivo: toda la cursada se dicta sobre SQL Server.

## 3. Responsables

Cada responsable hace las tablas, los datos de prueba, los objetos, las consultas y la documentación de su área.

| Área | Responsable | Rama de trabajo | Códigos de error |
|---|---|---|---|
| Deportiva | _a definir_ | `deportiva-<nombre>` | 50100 a 50199 |
| Personal | _a definir_ | `personal-<nombre>` | 50200 a 50299 |
| Técnica | _a definir_ | `tecnica-<nombre>` | 50300 a 50399 |
| Finanzas | _a definir_ | `finanzas-<nombre>` | 50400 a 50499 |
| **Integrador** | _a definir_ (puede ser también responsable de un área) | — | — |

### Qué tiene a cargo cada área

| Área | Tablas | Mecanismos |
|---|---|---|
| Deportiva (8) | País, Temporada, Circuito, Gran Premio, Tipo de sesión, Sesión, Puntaje, Resultado | Función de puntos de un piloto en una temporada · vista de puntos acumulados del equipo por GP · SP para cargar un resultado · trigger de validación de sesión |
| Personal (5) | Puesto, Empleado, Piloto, Contrato, Auditoría de contrato | Función de contrato vigente en una fecha · vista de nómina sin sueldos · SP para inscribir un piloto en un GP · trigger de validación y auditoría de contratos |
| Técnica (7) | Chasis, Inscripción, Tipo de componente, Límite de componente, Componente, Uso de componente, Penalización | Función de km restantes de una pieza · vista de estado de las piezas · SP de cierre de GP (con cursor) y de retiro de componente · trigger de uso de componente |
| Finanzas (5) | Categoría de gasto, Proveedor, Gasto, Tope presupuestario, Alerta de tope | Función de gasto computable de un año · vista de situación del tope · SP para registrar la compra de una pieza · trigger de control del tope · **seguridad de todas las áreas** |

### Integrador

- Junta los scripts de las cuatro áreas **por nivel de dependencia**, no por área, cada vez que se integra el trabajo.
- Verifica que los scripts corran sin errores sobre una base vacía.
- Revisa y mergea a `main` los pull requests de las ramas de área.

## 4. Escudería real: qué implica

Para cuidar la originalidad del trabajo:

- **Datos públicos como referencia:** el calendario 2026, los circuitos, los países y los pilotos pueden tomarse de la temporada real.
- **Datos internos inventados:** sueldos, contratos, gastos, proveedores, componentes, kilómetros y penalizaciones no son públicos. Se arman a mano para ejercitar cada regla de negocio, aunque el piloto o el Gran Premio sean reales.
- **Sin datasets públicos:** no se copia la estructura ni se cargan datos de bases públicas de F1 (por ejemplo, el dataset Ergast que circula en Kaggle). Lo propio del proyecto es la gestión interna: piezas, contratos y tope de gasto.

## 5. Consultas a la cátedra

### Entrega por GitHub

**Lo hablamos con el profesor: no es obligatorio entregar a través de GitHub.**

Decisión del equipo: **el trabajo no se entrega por GitHub.** Este repositorio se usa solo para organizarnos y llevar el historial del trabajo.

### Formato de entrega

**Pendiente de confirmar:** si los scripts van en un único archivo `.sql` o en varios, y en qué formato se entrega el documento.

## 6. Acuerdos iniciales

1. **Escudería real:** Red Bull Racing, temporada 2026, con la base preparada para varias temporadas.
2. **Motor:** Microsoft SQL Server 2025.
3. **GitHub para organizarnos, no para entregar:** el profesor confirmó que no es obligatorio entregar por GitHub, así que la entrega no se hace por ahí. Este repositorio se usa para coordinar el trabajo del equipo y llevar el historial de versiones.
4. **Organización del trabajo:** las definiciones, el alcance y el DER se hacen entre todos; las tablas, los datos de prueba y los objetos, cada responsable en su área y en paralelo; la integración, las pruebas y el documento final, de nuevo entre todos. Como en la defensa le pueden preguntar a cualquiera por cualquier parte, todos participan de las partes comunes.
5. **Modelo de partida:** 25 tablas repartidas en las cuatro áreas. Se revisa entre todos y se puede ajustar al armar el DER.
6. **Convenciones:** las de [convenciones.md](convenciones.md). Una vez confirmadas, no se cambian sin acordarlo entre todos.
7. **Originalidad:** los datos de prueba se arman a mano, sin copiar datasets públicos (sección 4).
