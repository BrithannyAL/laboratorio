
--RESPALDO DE ANTES DE EJECUTAR EL PROCEDIMIENTO ALMACENADO
BACKUP DATABASE [covid19] TO 
DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\covid19.bak' WITH NOFORMAT, 
NOINIT,  
NAME = N'covid19-Full Database Backup', 
SKIP, 
NOREWIND, 
NOUNLOAD,  
STATS = 10
GO


--Respaldo direfencial de la base de datos

BACKUP DATABASE [covid19] TO  
DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\covid19.bak' WITH  DIFFERENTIAL , 
NOFORMAT, 
NOINIT,  
NAME = N'covid19-Full Database Backup', 
SKIP, 
NOREWIND, 
NOUNLOAD,  
STATS = 10
GO
