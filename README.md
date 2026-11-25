# Inteligencia de fichajes en Counter-Strike 2

Trabajo Práctico Integrador de **Ingeniería de Datos I** (UADE). Grupo 04, Turno Noche: Criado, Amorín, Herrera, Saad y Viegas. Docente: Ing. Franco Emanuel Salazar.

Base de datos en SQL Server para analizar si el fichaje de un jugador mejora el rendimiento de un equipo profesional de CS2, teniendo en cuenta el nivel de los rivales.

## Cómo ejecutarlo

1. Abrir `TPI_Grupo4.sql` en SQL Server Management Studio (SQL Server 2017 o superior).
2. Ejecutar el archivo completo con **F5**, sin nada seleccionado.

El script borra la base `FichajesCS2DB` si ya existe y la crea de nuevo, así que se puede ejecutar varias veces.

## Contenido del script

| Sección | Contenido |
| --- | --- |
| 1. Tablas | 11 tablas con PK, FK, UNIQUE y CHECK |
| 2. Índices | 5 índices de apoyo para las consultas |
| 3. Vistas | `vw_RendimientoJugadores`, `vw_ResultadoEquipo` |
| 4. Triggers | Cupo de 5 jugadores activos por equipo, un solo contrato activo por jugador y auditoría de transferencias |
| 5. Función | `fn_CostoPorMapa` |
| 6. Procedimientos | 22 procedimientos: 2 de CRUD por cada tabla (alta, modificación, baja o consulta) y `sp_RegistrarTransferencia`, que registra un pase en una sola transacción |
| 7. Datos | Datos de ejemplo: 3 juegos, 10 organizaciones, 10 equipos, 28 jugadores, 32 contratos, 10 transferencias, 7 mapas, 12 series, 23 partidas y 27 filas de estadísticas |
| 8. Pruebas | 6 pruebas que muestran a los triggers, a los procedimientos y a las restricciones rechazando datos inválidos |
| 9. Consultas | 10 consultas de análisis y un control de filas por tabla |

Los datos son de ejemplo, inspirados en la escena real de CS2: resultados, estadísticas, salarios y montos son ilustrativos.
