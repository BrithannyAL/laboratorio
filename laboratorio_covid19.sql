
use covid19
go

CREATE OR ALTER VIEW tabla_comun
AS
	SELECT id, nombre, total_casos
		FROM reportes r INNER JOIN paises p ON (r.id_pais=p.id)
GO

SELECT * FROM tabla_comun
GO

--VISTA DEL DÍA DE MAYOR CONTAGIO POR PAÍS
CREATE OR ALTER VIEW vista_contagios_max
AS
	WITH cte_contagios_max AS (
		SELECT id, nombre, total_casos,
			ROW_NUMBER() OVER (PARTITION BY nombre ORDER BY nombre, total_casos DESC) AS rn
		FROM tabla_comun
	)
	SELECT id, nombre, total_casos
	FROM cte_contagios_max WHERE rn = 1
	GO

SELECT * FROM vista_contagios_max
GO

--LOGIN PARA LA BASE DE DATOS

CREATE LOGIN [usr_covid19] WITH PASSWORD=N'12345', 
DEFAULT_DATABASE=[covid19], 
CHECK_EXPIRATION=OFF, 
CHECK_POLICY=OFF
GO

CREATE USER [usr_covid19] FOR LOGIN [usr_covid19]
GO

GRANT SELECT ON [dbo].[vista_contagios_max] 
	TO [usr_covid19]
GO

--PUNTO 3 DEL LABORATORIO

USE covid19
GO

ALTER TABLE paises
	ADD contagios_por_millon INT,
		fecha_dia_mayor_contagio DATE,
		cantidad_contagios INT
GO

CREATE OR ALTER PROCEDURE llenas_nuevas_columnas
AS
DECLARE
	@id_pais_def INT, @nuevos_casos_def INT,
	@id_pais_act INT, @nuevos_casos_act INT,
	@fecha_def DATE, @fecha_act DATE,
	@poblacion BIGINT,
	@contagios_ant INT, @contagios_act INT
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE cursor_pais CURSOR FOR
			SELECT id_pais, fecha, nuevos_casos, total_casos FROM reportes
		OPEN cursor_pais
		FETCH NEXT FROM cursor_pais INTO @id_pais_def, @fecha_def, @nuevos_casos_def, @contagios_ant
		WHILE @@FETCH_STATUS = 0
		BEGIN
			FETCH NEXT FROM cursor_pais INTO @id_pais_act, @fecha_act, @nuevos_casos_act, @contagios_act
			IF @id_pais_def <> @id_pais_act
			BEGIN
				SET @id_pais_def = @id_pais_act
				SET @fecha_def = NULL
				SET @nuevos_casos_def = 0
				UPDATE paises
				SET contagios_por_millon = CASE WHEN cantidad_contagios IS NOT NULL THEN (
											(@contagios_ant / CAST(@poblacion AS FLOAT)) * 1000000) ELSE NULL END
					WHERE id = @id_pais_def
			END
			IF @nuevos_casos_act > @nuevos_casos_def OR @nuevos_casos_act = @nuevos_casos_def
			BEGIN
				SET @id_pais_def = @id_pais_act
				SET @fecha_def = @fecha_act
				SET @nuevos_casos_def = @nuevos_casos_act
				SET @poblacion = (SELECT CAST(poblacion AS BIGINT) FROM paises WHERE id = @id_pais_def)
				UPDATE paises 
				SET fecha_dia_mayor_contagio = @fecha_act, cantidad_contagios = @nuevos_casos_act
					WHERE id = @id_pais_def
			END
			SET @contagios_ant=@contagios_act
		END
		CLOSE cursor_pais
		DEALLOCATE cursor_pais
		COMMIT TRANSACTION; 

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT 'Ocurrió un error: ' + ERROR_MESSAGE();
	END CATCH
END
GO


EXEC llenas_nuevas_columnas
GO

DROP PROCEDURE llenas_nuevas_columnas
GO

SELECT * FROM  paises
GO

SELECT * FROM reportes
GO
