/* =====================================================================
   TPI Ingenieria de Datos I (UADE) - Grupo 04 - Turno Noche
   Inteligencia de fichajes en Counter-Strike 2
   ---------------------------------------------------------------------
   Orden: 1. Tablas  2. Indices  3. Vistas  4. Triggers  5. Funcion
          6. Procedimientos  7. Datos  8. Pruebas  9. Consultas
   Los datos son de ejemplo, inspirados en la escena real de CS2:
   resultados, estadisticas, salarios y montos son ilustrativos.
   Ejecutar entero en SSMS (F5).
   ===================================================================== */

USE master;
GO
IF DB_ID('FichajesCS2DB') IS NOT NULL
BEGIN
    ALTER DATABASE FichajesCS2DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FichajesCS2DB;
END
GO
CREATE DATABASE FichajesCS2DB;
GO
USE FichajesCS2DB;
GO

-- ============================= 1. TABLAS =================================

CREATE TABLE Juego (
    idJuego         INT            NOT NULL IDENTITY(1,1),
    nombre          NVARCHAR(100)  NOT NULL,
    desarrollador   NVARCHAR(100)  NOT NULL,

    CONSTRAINT PK_Juego PRIMARY KEY (idJuego),
    CONSTRAINT UQ_Juego_Nombre UNIQUE (nombre)
);
GO

CREATE TABLE Organizacion (
    idOrganizacion  INT            NOT NULL IDENTITY(1,1),
    nombre          NVARCHAR(100)  NOT NULL,
    region          NVARCHAR(50)   NOT NULL,

    CONSTRAINT PK_Organizacion PRIMARY KEY (idOrganizacion),
    CONSTRAINT UQ_Organizacion_Nombre UNIQUE (nombre)
);
GO

CREATE TABLE Equipo (
    idEquipo        INT            NOT NULL IDENTITY(1,1),
    idOrganizacion  INT            NOT NULL,
    idJuego         INT            NOT NULL,
    nombre          NVARCHAR(100)  NOT NULL,
    rankingActual   INT            NULL,

    CONSTRAINT PK_Equipo PRIMARY KEY (idEquipo),
    CONSTRAINT FK_Equipo_Organizacion FOREIGN KEY (idOrganizacion) REFERENCES Organizacion(idOrganizacion),
    CONSTRAINT FK_Equipo_Juego FOREIGN KEY (idJuego) REFERENCES Juego(idJuego),
    CONSTRAINT UQ_Equipo_Nombre UNIQUE (nombre),
    CONSTRAINT CK_Equipo_Ranking CHECK (rankingActual IS NULL OR rankingActual >= 1)
);
GO

CREATE TABLE Jugador (
    idJugador       INT            NOT NULL IDENTITY(1,1),
    alias           NVARCHAR(50)   NOT NULL,
    nombreReal      NVARCHAR(150)  NULL,      -- NVARCHAR: nombres con letras como C con caron o A con anillo
    nacionalidad    NVARCHAR(50)   NOT NULL,

    CONSTRAINT PK_Jugador PRIMARY KEY (idJugador),
    CONSTRAINT UQ_Jugador_Alias UNIQUE (alias)
);
GO

CREATE TABLE Contrato (
    idContrato      INT            NOT NULL IDENTITY(1,1),
    idJugador       INT            NOT NULL,
    idEquipo        INT            NOT NULL,
    fechaInicio     DATE           NOT NULL,
    fechaFin        DATE           NULL,      -- NULL = contrato vigente
    salarioMensual  DECIMAL(10,2)  NULL,      -- NULL = no divulgado
    estado          VARCHAR(20)    NOT NULL,

    CONSTRAINT PK_Contrato PRIMARY KEY (idContrato),
    CONSTRAINT FK_Contrato_Jugador FOREIGN KEY (idJugador) REFERENCES Jugador(idJugador),
    CONSTRAINT FK_Contrato_Equipo  FOREIGN KEY (idEquipo)  REFERENCES Equipo(idEquipo),
    CONSTRAINT CK_Contrato_Fechas  CHECK (fechaFin IS NULL OR fechaFin >= fechaInicio),
    CONSTRAINT CK_Contrato_Estado  CHECK (estado IN ('Activo', 'Finalizado', 'Rescindido')),
    -- estado y fechaFin no pueden contradecirse: activo <=> sin fecha de fin
    CONSTRAINT CK_Contrato_EstadoFecha CHECK ((estado = 'Activo' AND fechaFin IS NULL) OR
                                              (estado <> 'Activo' AND fechaFin IS NOT NULL)),
    CONSTRAINT CK_Contrato_Salario CHECK (salarioMensual IS NULL OR salarioMensual >= 0)
);
GO

CREATE TABLE Transferencia (
    idTransferencia INT            NOT NULL IDENTITY(1,1),
    idJugador       INT            NOT NULL,
    idEquipoOrigen  INT            NULL,      -- NULL = jugador libre
    idEquipoDestino INT            NOT NULL,
    fecha           DATE           NOT NULL,
    monto           DECIMAL(12,2)  NULL,      -- NULL = no divulgado

    CONSTRAINT PK_Transferencia PRIMARY KEY (idTransferencia),
    CONSTRAINT FK_Transf_Jugador FOREIGN KEY (idJugador) REFERENCES Jugador(idJugador),
    CONSTRAINT FK_Transf_Origen  FOREIGN KEY (idEquipoOrigen)  REFERENCES Equipo(idEquipo),
    CONSTRAINT FK_Transf_Destino FOREIGN KEY (idEquipoDestino) REFERENCES Equipo(idEquipo),
    CONSTRAINT CK_Transf_Equipos CHECK (idEquipoOrigen IS NULL OR idEquipoOrigen <> idEquipoDestino),
    CONSTRAINT CK_Transf_Monto   CHECK (monto IS NULL OR monto >= 0)
);
GO

CREATE TABLE Mapa (
    idMapa            INT           NOT NULL IDENTITY(1,1),
    nombre            VARCHAR(50)   NOT NULL,
    activoCompetitivo BIT           NOT NULL CONSTRAINT DF_Mapa_Activo DEFAULT 1,

    CONSTRAINT PK_Mapa PRIMARY KEY (idMapa),
    CONSTRAINT UQ_Mapa_Nombre UNIQUE (nombre)
);
GO

CREATE TABLE Serie (
    idSerie         INT           NOT NULL IDENTITY(1,1),
    fecha           DATE          NOT NULL,
    idEquipoA       INT           NOT NULL,
    idEquipoB       INT           NOT NULL,
    rankingRivalA   INT           NULL,       -- ranking del equipo B (rival de A) el dia de la serie
    rankingRivalB   INT           NULL,       -- ranking del equipo A (rival de B) el dia de la serie

    CONSTRAINT PK_Serie PRIMARY KEY (idSerie),
    CONSTRAINT FK_Serie_EquipoA FOREIGN KEY (idEquipoA) REFERENCES Equipo(idEquipo),
    CONSTRAINT FK_Serie_EquipoB FOREIGN KEY (idEquipoB) REFERENCES Equipo(idEquipo),
    CONSTRAINT CK_Serie_Equipos CHECK (idEquipoA <> idEquipoB),
    CONSTRAINT CK_Serie_Ranking CHECK ((rankingRivalA IS NULL OR rankingRivalA >= 1) AND
                                       (rankingRivalB IS NULL OR rankingRivalB >= 1))
);
GO

CREATE TABLE Partida (
    idPartida       INT           NOT NULL IDENTITY(1,1),
    idSerie         INT           NOT NULL,
    idMapa          INT           NOT NULL,
    rondasEquipoA   INT           NOT NULL,
    rondasEquipoB   INT           NOT NULL,

    CONSTRAINT PK_Partida PRIMARY KEY (idPartida),
    CONSTRAINT FK_Partida_Serie FOREIGN KEY (idSerie) REFERENCES Serie(idSerie),
    CONSTRAINT FK_Partida_Mapa FOREIGN KEY (idMapa) REFERENCES Mapa(idMapa),
    CONSTRAINT CK_Partida_Rondas    CHECK (rondasEquipoA >= 0 AND rondasEquipoB >= 0),
    CONSTRAINT CK_Partida_SinEmpate CHECK (rondasEquipoA <> rondasEquipoB),
    CONSTRAINT CK_Partida_Ganador   CHECK (rondasEquipoA >= 13 OR rondasEquipoB >= 13)  -- en CS2 se gana con 13
);
GO

CREATE TABLE EstadisticaCS2 (
    idEstadistica   INT           NOT NULL IDENTITY(1,1),
    idPartida       INT           NOT NULL,
    idJugador       INT           NOT NULL,
    idEquipo        INT           NOT NULL,
    kills           INT           NOT NULL,
    deaths          INT           NOT NULL,
    assists         INT           NOT NULL,
    adr             DECIMAL(5,1)  NOT NULL,
    kast            DECIMAL(5,1)  NOT NULL,
    rating2         DECIMAL(4,2)  NOT NULL,

    CONSTRAINT PK_EstadisticaCS2 PRIMARY KEY (idEstadistica),
    CONSTRAINT FK_Estadistica_Partida FOREIGN KEY (idPartida) REFERENCES Partida(idPartida),
    CONSTRAINT FK_Estadistica_Jugador FOREIGN KEY (idJugador) REFERENCES Jugador(idJugador),
    CONSTRAINT FK_Estadistica_Equipo FOREIGN KEY (idEquipo) REFERENCES Equipo(idEquipo),
    CONSTRAINT UQ_Estadistica_PartidaJugador UNIQUE (idPartida, idJugador),  -- una fila por jugador y mapa
    CONSTRAINT CK_Estadistica_Valores CHECK (kills >= 0 AND deaths >= 0 AND assists >= 0 AND adr >= 0 AND rating2 >= 0),
    CONSTRAINT CK_Estadistica_Kast    CHECK (kast BETWEEN 0 AND 100)
);
GO

CREATE TABLE Auditoria (
    idAuditoria     INT            NOT NULL IDENTITY(1,1),
    tablaAfectada   VARCHAR(50)    NOT NULL,
    operacion       VARCHAR(10)    NOT NULL,
    usuarioDB       NVARCHAR(128)  NOT NULL,
    fechaHora       DATETIME       NOT NULL CONSTRAINT DF_Auditoria_Fecha DEFAULT GETDATE(),
    detalle         NVARCHAR(400)  NOT NULL,

    CONSTRAINT PK_Auditoria PRIMARY KEY (idAuditoria)
);
GO

-- ============================= 2. INDICES =================================

CREATE INDEX idx_Contrato_Jugador ON Contrato(idJugador);
CREATE INDEX idx_Contrato_Equipo ON Contrato(idEquipo);
CREATE INDEX idx_Transferencia_Jugador ON Transferencia(idJugador);
CREATE INDEX idx_Estadistica_Jugador ON EstadisticaCS2(idJugador);
CREATE INDEX idx_Serie_Fecha ON Serie(fecha);
GO

-- ============================= 3. VISTAS =================================

-- Vista 1: Rendimiento general de cada jugador con contrato activo
CREATE OR ALTER VIEW vw_RendimientoJugadores AS
SELECT
    j.alias,
    e.nombre AS equipo_actual,
    COUNT(est.idPartida) AS mapas_jugados,
    CAST(AVG(est.rating2) AS DECIMAL(4,2)) AS rating_promedio,
    CAST(AVG(est.adr) AS DECIMAL(5,1)) AS adr_promedio,
    CAST(AVG(est.kast) AS DECIMAL(5,1)) AS kast_promedio,
    SUM(est.kills) AS total_kills,
    SUM(est.deaths) AS total_deaths,
    CAST(CAST(SUM(est.kills) AS DECIMAL(10,2)) / NULLIF(SUM(est.deaths), 0) AS DECIMAL(5,2)) AS kd_ratio
FROM Jugador j
JOIN Contrato c ON j.idJugador = c.idJugador AND c.estado = 'Activo'
JOIN Equipo e ON c.idEquipo = e.idEquipo
JOIN EstadisticaCS2 est ON j.idJugador = est.idJugador
GROUP BY j.alias, e.nombre;
GO

-- Vista 2: Cada mapa visto desde cada equipo (dos filas por mapa)
CREATE OR ALTER VIEW vw_ResultadoEquipo AS
SELECT
    s.idSerie,
    p.idPartida,
    s.fecha,
    m.nombre AS mapa,
    e.idEquipo,
    e.nombre AS equipo,
    r.idEquipo AS idRival,
    r.nombre AS rival,
    CASE WHEN s.idEquipoA = e.idEquipo THEN s.rankingRivalA ELSE s.rankingRivalB END AS ranking_rival,
    CASE WHEN s.idEquipoA = e.idEquipo THEN p.rondasEquipoA ELSE p.rondasEquipoB END AS rondas_a_favor,
    CASE WHEN s.idEquipoA = e.idEquipo THEN p.rondasEquipoB ELSE p.rondasEquipoA END AS rondas_en_contra,
    CASE
        WHEN (s.idEquipoA = e.idEquipo AND p.rondasEquipoA > p.rondasEquipoB) OR
             (s.idEquipoB = e.idEquipo AND p.rondasEquipoB > p.rondasEquipoA) THEN 1
        ELSE 0
    END AS gano
FROM Serie s
JOIN Partida p ON s.idSerie = p.idSerie
JOIN Mapa m ON p.idMapa = m.idMapa
JOIN Equipo e ON e.idEquipo IN (s.idEquipoA, s.idEquipoB)
JOIN Equipo r ON r.idEquipo = CASE WHEN s.idEquipoA = e.idEquipo THEN s.idEquipoB ELSE s.idEquipoA END;
GO

-- ============================= 4. TRIGGERS =================================
-- Los triggers que bloquean guardan primero el detalle en una variable de tabla
-- (no se ve afectada por el ROLLBACK), deshacen la operacion, registran la
-- auditoria DESPUES del ROLLBACK (si no, el ROLLBACK la borraria) y lanzan el error.

-- Trigger 1: Maximo 5 jugadores activos por equipo
CREATE OR ALTER TRIGGER trg_ValidarCupoEquipo
ON Contrato
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT idEquipo FROM inserted) i
        WHERE (SELECT COUNT(*) FROM Contrato c
               WHERE c.idEquipo = i.idEquipo AND c.estado = 'Activo') > 5
    )
    BEGIN
        DECLARE @log TABLE (detalle NVARCHAR(400));
        INSERT INTO @log
        SELECT DISTINCT N'Intento de superar el cupo de 5 jugadores en el equipo ID: ' + CAST(idEquipo AS NVARCHAR(10))
        FROM inserted;

        ROLLBACK TRANSACTION;

        INSERT INTO Auditoria (tablaAfectada, operacion, usuarioDB, detalle)
        SELECT 'Contrato', 'BLOQUEADO', SYSTEM_USER, detalle FROM @log;

        THROW 50001, 'Un equipo de CS2 no puede tener mas de 5 jugadores activos.', 1;
    END
END;
GO

-- Trigger 2: Un jugador no puede tener dos contratos activos a la vez
CREATE OR ALTER TRIGGER trg_EvitarContratosMultiples
ON Contrato
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT idJugador FROM inserted) i
        WHERE (SELECT COUNT(*) FROM Contrato c
               WHERE c.idJugador = i.idJugador AND c.estado = 'Activo') > 1
    )
    BEGIN
        DECLARE @log TABLE (detalle NVARCHAR(400));
        INSERT INTO @log
        SELECT DISTINCT N'Intento de contrato multiple para el jugador ID: ' + CAST(idJugador AS NVARCHAR(10))
        FROM inserted;

        ROLLBACK TRANSACTION;

        INSERT INTO Auditoria (tablaAfectada, operacion, usuarioDB, detalle)
        SELECT 'Contrato', 'BLOQUEADO', SYSTEM_USER, detalle FROM @log;

        THROW 50002, 'El jugador ya posee un contrato activo con otro equipo.', 1;
    END
END;
GO

-- Trigger 3: Auditoria de cada transferencia registrada
CREATE OR ALTER TRIGGER trg_AuditarTransferencia
ON Transferencia
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Auditoria (tablaAfectada, operacion, usuarioDB, detalle)
    SELECT 'Transferencia', 'INSERT', SYSTEM_USER,
           N'Fichaje - Jugador: ' + CAST(i.idJugador AS NVARCHAR(10)) +
           N' | Destino: ' + CAST(i.idEquipoDestino AS NVARCHAR(10)) +
           N' | Monto: ' + ISNULL(N'$' + CAST(i.monto AS NVARCHAR(20)), N'no divulgado')
    FROM inserted i;
END;
GO

-- ============================= 5. FUNCIONES =================================

-- Costo de la transferencia por cada mapa jugado en el nuevo equipo.
-- Devuelve NULL si el monto no se conoce o si todavia no jugo ningun mapa.
CREATE OR ALTER FUNCTION fn_CostoPorMapa
(
    @idTransferencia INT,
    @mapasJugados INT
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @montoTransferencia DECIMAL(12,2);

    SELECT @montoTransferencia = monto
    FROM Transferencia
    WHERE idTransferencia = @idTransferencia;

    IF @mapasJugados IS NULL OR @mapasJugados = 0 RETURN NULL;

    RETURN @montoTransferencia / @mapasJugados;
END;
GO

-- ============================= 6. PROCEDIMIENTOS =================================

-- SP 1: Insertar Jugador
CREATE OR ALTER PROCEDURE sp_InsertarJugador
    @alias NVARCHAR(50),
    @nombreReal NVARCHAR(150),
    @nacionalidad NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Jugador (alias, nombreReal, nacionalidad)
    VALUES (@alias, @nombreReal, @nacionalidad);
END;
GO

-- SP 2: Registrar una transferencia en una sola transaccion:
-- cierra el contrato activo (el dia anterior), registra el pase y abre el contrato nuevo.
CREATE OR ALTER PROCEDURE sp_RegistrarTransferencia
    @idJugador INT,
    @idEquipoDestino INT,
    @monto DECIMAL(12,2) = NULL,
    @fecha DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @idEquipoOrigen INT;

    SELECT @idEquipoOrigen = idEquipo
    FROM Contrato
    WHERE idJugador = @idJugador AND estado = 'Activo';

    IF @idEquipoOrigen = @idEquipoDestino
        THROW 50003, 'El jugador ya tiene contrato activo con el equipo de destino.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF @idEquipoOrigen IS NOT NULL
                UPDATE Contrato
                SET estado = 'Rescindido', fechaFin = DATEADD(DAY, -1, @fecha)
                WHERE idJugador = @idJugador AND estado = 'Activo';

            INSERT INTO Transferencia (idJugador, idEquipoOrigen, idEquipoDestino, fecha, monto)
            VALUES (@idJugador, @idEquipoOrigen, @idEquipoDestino, @fecha, @monto);

            INSERT INTO Contrato (idJugador, idEquipo, fechaInicio, estado)
            VALUES (@idJugador, @idEquipoDestino, @fecha, 'Activo');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP 3: Actualizar Ranking de Equipo
CREATE OR ALTER PROCEDURE sp_ActualizarRankingEquipo
    @idEquipo INT,
    @nuevoRanking INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Equipo
    SET rankingActual = @nuevoRanking
    WHERE idEquipo = @idEquipo;
END;
GO

-- SP 4: Borrar una partida con sus estadisticas
CREATE OR ALTER PROCEDURE sp_BorrarPartida
    @idPartida INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            DELETE FROM EstadisticaCS2 WHERE idPartida = @idPartida;
            DELETE FROM Partida WHERE idPartida = @idPartida;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================= 7. DATOS DE EJEMPLO =================================

INSERT INTO Juego (nombre, desarrollador) VALUES (N'Counter-Strike 2', N'Valve');

INSERT INTO Organizacion (nombre, region) VALUES
(N'Team Spirit', N'CIS'),               -- 1
(N'FaZe Clan', N'Europa'),              -- 2
(N'Team Liquid', N'Norteamérica'),      -- 3
(N'G2 Esports', N'Europa'),             -- 4
(N'Team Vitality', N'Europa'),          -- 5
(N'Natus Vincere', N'CIS'),             -- 6
(N'MOUZ', N'Europa'),                   -- 7
(N'Team Falcons', N'Medio Oriente'),    -- 8
(N'Astralis', N'Europa'),               -- 9
(N'HEROIC', N'Europa');                 -- 10

INSERT INTO Equipo (idOrganizacion, idJuego, nombre, rankingActual) VALUES
(1, 1, N'Team Spirit CS2', 3),      -- 1
(2, 1, N'FaZe Clan CS2', 1),        -- 2
(3, 1, N'Team Liquid CS2', 12),     -- 3
(4, 1, N'G2 Esports CS2', 4),       -- 4
(5, 1, N'Team Vitality CS2', 2),    -- 5
(6, 1, N'Natus Vincere CS2', 5),    -- 6
(7, 1, N'MOUZ CS2', 6),             -- 7
(8, 1, N'Team Falcons CS2', 8),     -- 8
(9, 1, N'Astralis CS2', 10),        -- 9
(10, 1, N'HEROIC CS2', 7);          -- 10

INSERT INTO Jugador (alias, nombreReal, nacionalidad) VALUES
(N'donk', N'Danil Kryshkovets', N'Rusia'),            -- 1
(N'chopper', N'Leonid Vishnyakov', N'Rusia'),         -- 2
(N'sh1ro', N'Dmitry Sokolov', N'Rusia'),              -- 3
(N'frozen', N'David Čerňanský', N'Eslovaquia'),       -- 4
(N'Twistzz', N'Russel Van Dulken', N'Canadá'),        -- 5
(N'karrigan', N'Finn Andersen', N'Dinamarca'),        -- 6
(N'rain', N'Håvard Nygaard', N'Noruega'),             -- 7
(N'broky', N'Helvijs Saukants', N'Letonia'),          -- 8
(N'ZywOo', N'Mathieu Herbaut', N'Francia'),           -- 9
(N'apEX', N'Dan Madesclaire', N'Francia'),            -- 10
(N'm0NESY', N'Ilya Osipov', N'Rusia'),                -- 11
(N'NiKo', N'Nikola Kovač', N'Bosnia y Herzegovina'),  -- 12
(N'Aleksib', N'Aleksi Virolainen', N'Finlandia'),     -- 13
(N'iM', N'Mihai Ivan', N'Rumania'),                   -- 14
(N'jL', N'Justinas Lekavicius', N'Lituania'),         -- 15
(N'torzsi', N'Ádám Torzsás', N'Hungría'),             -- 16
(N'Brollan', N'Ludvig Brolin', N'Suecia'),            -- 17
(N'NAF', N'Keith Markovic', N'Canadá'),               -- 18
(N'HooXi', N'Rasmus Nielsen', N'Dinamarca'),          -- 19
(N'ropz', N'Robin Kool', N'Estonia');                 -- 20

-- Contratos iniciales (antes de las transferencias que se registran con el SP)
INSERT INTO Contrato (idJugador, idEquipo, fechaInicio, fechaFin, salarioMensual, estado) VALUES
(2, 1, '2022-01-01', NULL, 15000, 'Activo'),          -- chopper  - Spirit
(3, 1, '2023-12-17', NULL, 25000, 'Activo'),          -- sh1ro    - Spirit
(6, 2, '2021-01-01', NULL, 30000, 'Activo'),          -- karrigan - FaZe
(7, 2, '2016-01-01', NULL, 28000, 'Activo'),          -- rain     - FaZe
(8, 2, '2018-12-01', NULL, 27000, 'Activo'),          -- broky    - FaZe
(5, 2, '2019-01-01', NULL, 32000, 'Activo'),          -- Twistzz  - FaZe
(20, 2, '2022-01-01', NULL, NULL, 'Activo'),          -- ropz     - FaZe
(4, 7, '2019-01-01', NULL, 18000, 'Activo'),          -- frozen   - MOUZ
(16, 7, '2021-01-01', NULL, 16000, 'Activo'),         -- torzsi   - MOUZ
(17, 7, '2023-01-01', NULL, NULL, 'Activo'),          -- Brollan  - MOUZ
(9, 5, '2018-10-01', NULL, 40000, 'Activo'),          -- ZywOo    - Vitality
(10, 5, '2021-07-01', NULL, 22000, 'Activo'),         -- apEX     - Vitality
(11, 4, '2022-01-01', NULL, 35000, 'Activo'),         -- m0NESY   - G2
(12, 4, '2021-01-01', NULL, 38000, 'Activo'),         -- NiKo     - G2
(19, 4, '2022-01-01', NULL, NULL, 'Activo'),          -- HooXi    - G2
(13, 6, '2023-07-01', NULL, NULL, 'Activo'),          -- Aleksib  - NAVI
(14, 6, '2023-07-01', NULL, NULL, 'Activo'),          -- iM       - NAVI
(15, 6, '2023-07-01', NULL, NULL, 'Activo'),          -- jL       - NAVI
(18, 3, '2017-01-01', NULL, 20000, 'Activo'),         -- NAF      - Liquid
(12, 2, '2017-02-01', '2020-10-01', NULL, 'Finalizado'); -- NiKo  - FaZe (contrato anterior)

INSERT INTO Mapa (nombre) VALUES ('Mirage'), ('Nuke'), ('Inferno'), ('Ancient'), ('Anubis'), ('Dust2'), ('Train');

-- Transferencias con el SP. Twistzz sale de FaZe antes de que llegue frozen,
-- asi FaZe nunca supera los 5 jugadores activos. Montos ilustrativos; NULL = no divulgado.
EXEC sp_RegistrarTransferencia @idJugador = 1, @idEquipoDestino = 1, @monto = NULL,   @fecha = '2023-07-01'; -- donk a Spirit (academia)
EXEC sp_RegistrarTransferencia @idJugador = 5, @idEquipoDestino = 3, @monto = 500000, @fecha = '2023-12-07'; -- Twistzz de FaZe a Liquid
EXEC sp_RegistrarTransferencia @idJugador = 4, @idEquipoDestino = 2, @monto = 250000, @fecha = '2023-12-04'; -- frozen de MOUZ a FaZe

-- Series: 3 de FaZe antes del fichaje de frozen (04/12/2023), 3 despues y 6 de otros equipos
INSERT INTO Serie (fecha, idEquipoA, idEquipoB, rankingRivalA, rankingRivalB) VALUES
('2023-10-15', 2, 5, 2, 1),    -- 1  FaZe vs Vitality   (antes)
('2023-11-05', 2, 6, 5, 1),    -- 2  FaZe vs NAVI       (antes)
('2023-11-20', 2, 4, 4, 1),    -- 3  FaZe vs G2         (antes)
('2024-01-28', 2, 7, 6, 1),    -- 4  FaZe vs MOUZ       (despues)
('2024-02-10', 2, 1, 3, 1),    -- 5  FaZe vs Spirit     (despues)
('2024-03-02', 2, 10, 7, 1),   -- 6  FaZe vs HEROIC     (despues)
('2023-10-20', 1, 5, 2, 3),    -- 7  Spirit vs Vitality
('2023-11-12', 4, 6, 5, 4),    -- 8  G2 vs NAVI
('2024-01-30', 5, 7, 6, 2),    -- 9  Vitality vs MOUZ
('2024-02-15', 3, 9, 10, 12),  -- 10 Liquid vs Astralis
('2024-02-20', 6, 10, 7, 5),   -- 11 NAVI vs HEROIC
('2024-03-05', 1, 4, 4, 3);    -- 12 Spirit vs G2

-- Mapas: 1 Mirage, 2 Nuke, 3 Inferno, 4 Ancient, 5 Anubis, 6 Dust2, 7 Train
INSERT INTO Partida (idSerie, idMapa, rondasEquipoA, rondasEquipoB) VALUES
(1, 1, 13, 10), (1, 2, 9, 13),  (1, 3, 13, 11),     -- partidas 1-3
(2, 4, 11, 13), (2, 5, 13, 7),  (2, 1, 16, 14),     -- partidas 4-6
(3, 1, 13, 10), (3, 3, 7, 13),  (3, 2, 13, 9),      -- partidas 7-9
(4, 3, 13, 8),  (4, 4, 13, 11),                     -- partidas 10-11
(5, 2, 9, 13),  (5, 1, 13, 6),  (5, 5, 13, 10),     -- partidas 12-14
(6, 4, 13, 4),  (6, 3, 10, 13), (6, 1, 13, 9),      -- partidas 15-17
(7, 1, 13, 11),                                     -- partida 18
(8, 2, 13, 5),                                      -- partida 19
(9, 6, 10, 13),                                     -- partida 20
(10, 7, 13, 9),                                     -- partida 21
(11, 5, 13, 8),                                     -- partida 22
(12, 3, 11, 13);                                    -- partida 23

INSERT INTO EstadisticaCS2 (idPartida, idJugador, idEquipo, kills, deaths, assists, adr, kast, rating2) VALUES
-- FaZe antes de frozen
(1, 5, 2, 20, 15, 4, 88.1, 76.0, 1.18),    -- Twistzz
(1, 8, 2, 17, 16, 3, 79.5, 72.0, 1.04),    -- broky
(4, 5, 2, 15, 18, 5, 72.0, 68.0, 0.92),
(4, 8, 2, 19, 17, 2, 84.3, 70.0, 1.08),
(7, 5, 2, 18, 14, 6, 81.2, 78.0, 1.12),
(7, 8, 2, 21, 13, 3, 90.6, 80.0, 1.30),
(8, 8, 2, 12, 18, 2, 65.4, 60.0, 0.78),
-- FaZe con frozen
(10, 4, 2, 22, 12, 5, 95.2, 82.0, 1.38),   -- frozen
(10, 8, 2, 18, 13, 4, 83.0, 77.0, 1.15),
(11, 4, 2, 19, 16, 6, 86.7, 75.0, 1.17),
(12, 4, 2, 18, 15, 4, 85.4, 75.0, 1.15),
(12, 1, 1, 28, 11, 6, 112.5, 88.0, 1.95),  -- donk
(13, 4, 2, 17, 9, 3, 88.9, 85.0, 1.33),
(14, 4, 2, 20, 15, 5, 84.1, 76.0, 1.16),
(15, 8, 2, 16, 6, 2, 92.3, 88.0, 1.45),
(16, 4, 2, 14, 17, 3, 70.2, 66.0, 0.89),
(17, 4, 2, 21, 14, 4, 91.0, 79.0, 1.25),
-- Otras series
(18, 1, 1, 26, 14, 3, 104.8, 80.0, 1.48),  -- donk
(18, 9, 5, 24, 17, 4, 98.3, 74.0, 1.30),   -- ZywOo
(19, 11, 4, 22, 9, 2, 101.7, 86.0, 1.62),  -- m0NESY
(19, 15, 6, 11, 18, 4, 64.0, 62.0, 0.74),  -- jL
(20, 9, 5, 23, 18, 5, 95.5, 70.0, 1.21),   -- ZywOo
(20, 16, 7, 19, 15, 6, 82.4, 77.0, 1.10),  -- torzsi
(21, 5, 3, 21, 13, 4, 89.7, 81.0, 1.27),   -- Twistzz en Liquid
(22, 15, 6, 20, 12, 7, 88.0, 84.0, 1.24),  -- jL
(23, 1, 1, 27, 19, 5, 108.1, 74.0, 1.36),  -- donk
(23, 12, 4, 22, 16, 6, 90.4, 76.0, 1.18);  -- NiKo
GO

-- ============================= 8. PRUEBAS DE RESTRICCIONES Y TRIGGERS =================================
-- Cada prueba intenta algo invalido: la base debe rechazarlo y el CATCH muestra el motivo.

-- Prueba 1 (Trigger 2): donk ya esta activo en Spirit; se intenta un contrato con Liquid sin usar el SP
BEGIN TRY
    INSERT INTO Contrato (idJugador, idEquipo, fechaInicio, estado)
    VALUES ((SELECT idJugador FROM Jugador WHERE alias = N'donk'), 3, '2024-04-01', 'Activo');
END TRY
BEGIN CATCH
    PRINT 'Prueba 1 rechazada: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 2 (Trigger 1): Spirit tiene 3 activos (chopper, sh1ro, donk); se suman 2 y el sexto se rechaza
EXEC sp_InsertarJugador @alias = N'magixx', @nombreReal = N'Boris Vorobiev', @nacionalidad = N'Rusia';
EXEC sp_InsertarJugador @alias = N'zont1x', @nombreReal = N'Myroslav Plakhotja', @nacionalidad = N'Ucrania';
EXEC sp_InsertarJugador @alias = N'hally', @nombreReal = NULL, @nacionalidad = N'Rusia';
INSERT INTO Contrato (idJugador, idEquipo, fechaInicio, estado)
VALUES ((SELECT idJugador FROM Jugador WHERE alias = N'magixx'), 1, '2024-01-01', 'Activo'),
       ((SELECT idJugador FROM Jugador WHERE alias = N'zont1x'), 1, '2024-01-01', 'Activo');

BEGIN TRY
    INSERT INTO Contrato (idJugador, idEquipo, fechaInicio, estado)
    VALUES ((SELECT idJugador FROM Jugador WHERE alias = N'hally'), 1, '2024-04-01', 'Activo');
END TRY
BEGIN CATCH
    PRINT 'Prueba 2 rechazada: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 3 (SP): transferir a frozen a FaZe, donde ya tiene contrato activo
BEGIN TRY
    EXEC sp_RegistrarTransferencia @idJugador = 4, @idEquipoDestino = 2, @fecha = '2024-05-01';
END TRY
BEGIN CATCH
    PRINT 'Prueba 3 rechazada: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 4 (CHECK): un mapa empatado 13 a 13
BEGIN TRY
    INSERT INTO Partida (idSerie, idMapa, rondasEquipoA, rondasEquipoB) VALUES (7, 2, 13, 13);
END TRY
BEGIN CATCH
    PRINT 'Prueba 4 rechazada: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 5 (UNIQUE): cargar dos veces las estadisticas de frozen en el mismo mapa
BEGIN TRY
    INSERT INTO EstadisticaCS2 (idPartida, idJugador, idEquipo, kills, deaths, assists, adr, kast, rating2)
    VALUES (10, 4, 2, 10, 10, 1, 70.0, 70.0, 1.00);
END TRY
BEGIN CATCH
    PRINT 'Prueba 5 rechazada: ' + ERROR_MESSAGE();
END CATCH;
GO

-- ============================= 9. CONSULTAS =================================

-- 1. Antes vs despues de un fichaje: FaZe con la llegada de frozen
DECLARE @equipo_analisis NVARCHAR(100) = N'FaZe Clan CS2';
DECLARE @fecha_fichaje DATE = '2023-12-04';

SELECT 'Antes' AS periodo, COUNT(*) AS mapas_jugados,
       CAST(AVG(CAST(gano AS DECIMAL(5,2))) AS DECIMAL(5,2)) AS win_rate,
       CAST(AVG(ranking_rival * 1.0) AS DECIMAL(5,2)) AS nivel_rival_promedio,
       SUM(rondas_a_favor) - SUM(rondas_en_contra) AS diferencial_rondas
FROM vw_ResultadoEquipo
WHERE equipo = @equipo_analisis AND fecha < @fecha_fichaje
UNION ALL
SELECT 'Despues', COUNT(*),
       CAST(AVG(CAST(gano AS DECIMAL(5,2))) AS DECIMAL(5,2)),
       CAST(AVG(ranking_rival * 1.0) AS DECIMAL(5,2)),
       SUM(rondas_a_favor) - SUM(rondas_en_contra)
FROM vw_ResultadoEquipo
WHERE equipo = @equipo_analisis AND fecha >= @fecha_fichaje;
GO

-- 2. Jugadores con contrato activo y salario
SELECT j.alias, e.nombre AS equipo, c.fechaInicio,
       ISNULL(CAST(c.salarioMensual AS VARCHAR(20)), 'No divulgado') AS salario_mensual
FROM Jugador j
JOIN Contrato c ON j.idJugador = c.idJugador
JOIN Equipo e ON c.idEquipo = e.idEquipo
WHERE c.estado = 'Activo'
ORDER BY e.nombre, j.alias;

-- 3. Historial de transferencias, de mayor a menor monto
SELECT t.fecha, j.alias,
       ISNULL(org_origen.nombre, N'Libre') AS origen,
       org_destino.nombre AS destino,
       t.monto
FROM Transferencia t
JOIN Jugador j ON t.idJugador = j.idJugador
LEFT JOIN Equipo eo ON t.idEquipoOrigen = eo.idEquipo
LEFT JOIN Organizacion org_origen ON eo.idOrganizacion = org_origen.idOrganizacion
JOIN Equipo ed ON t.idEquipoDestino = ed.idEquipo
JOIN Organizacion org_destino ON ed.idOrganizacion = org_destino.idOrganizacion
ORDER BY t.monto DESC;

-- 4. Costo de cada fichaje por mapa jugado en el nuevo equipo (usa la funcion)
SELECT j.alias, t.monto, COUNT(est.idPartida) AS mapas_jugados,
       dbo.fn_CostoPorMapa(t.idTransferencia, COUNT(est.idPartida)) AS costo_por_mapa
FROM Transferencia t
JOIN Jugador j ON t.idJugador = j.idJugador
LEFT JOIN EstadisticaCS2 est ON j.idJugador = est.idJugador AND est.idEquipo = t.idEquipoDestino
GROUP BY j.alias, t.idTransferencia, t.monto;

-- 5. Victorias de cada equipo en Mirage
SELECT e.nombre AS equipo, m.nombre AS mapa, COUNT(p.idPartida) AS jugados,
       SUM(CASE WHEN (s.idEquipoA = e.idEquipo AND p.rondasEquipoA > p.rondasEquipoB) OR
                     (s.idEquipoB = e.idEquipo AND p.rondasEquipoB > p.rondasEquipoA) THEN 1 ELSE 0 END) AS victorias
FROM Equipo e
JOIN Serie s ON e.idEquipo IN (s.idEquipoA, s.idEquipoB)
JOIN Partida p ON s.idSerie = p.idSerie
JOIN Mapa m ON p.idMapa = m.idMapa
WHERE m.nombre = 'Mirage'
GROUP BY e.nombre, m.nombre
ORDER BY victorias DESC;

-- 6. Top 3 jugadores por rating promedio
SELECT TOP 3 alias, equipo_actual, mapas_jugados, rating_promedio, total_kills, kd_ratio
FROM vw_RendimientoJugadores
ORDER BY rating_promedio DESC;

-- 7. Historial de auditoria: bloqueos de los triggers y transferencias registradas
SELECT * FROM Auditoria ORDER BY idAuditoria;

-- 8. ADR promedio por equipo
SELECT e.nombre, CAST(AVG(est.adr) AS DECIMAL(5,1)) AS adr_promedio_equipo
FROM EstadisticaCS2 est
JOIN Equipo e ON est.idEquipo = e.idEquipo
GROUP BY e.nombre
ORDER BY adr_promedio_equipo DESC;

-- 9. Mapas donde un jugador hizo 25 kills o mas
SELECT j.alias, p.idPartida, m.nombre AS mapa, est.kills, e.nombre AS equipo
FROM EstadisticaCS2 est
JOIN Jugador j ON est.idJugador = j.idJugador
JOIN Partida p ON est.idPartida = p.idPartida
JOIN Mapa m ON p.idMapa = m.idMapa
JOIN Equipo e ON est.idEquipo = e.idEquipo
WHERE est.kills >= 25
ORDER BY est.kills DESC;

-- 10. Equipos sin jugadores con contrato activo (subconsulta)
SELECT nombre
FROM Equipo
WHERE idEquipo NOT IN (SELECT idEquipo FROM Contrato WHERE estado = 'Activo');

-- Control: cantidad de filas por tabla
SELECT 'Organizacion' AS tabla, COUNT(*) AS filas FROM Organizacion UNION ALL
SELECT 'Equipo', COUNT(*) FROM Equipo UNION ALL
SELECT 'Jugador', COUNT(*) FROM Jugador UNION ALL
SELECT 'Contrato', COUNT(*) FROM Contrato UNION ALL
SELECT 'Transferencia', COUNT(*) FROM Transferencia UNION ALL
SELECT 'Serie', COUNT(*) FROM Serie UNION ALL
SELECT 'Partida', COUNT(*) FROM Partida UNION ALL
SELECT 'EstadisticaCS2', COUNT(*) FROM EstadisticaCS2 UNION ALL
SELECT 'Auditoria', COUNT(*) FROM Auditoria;
GO
