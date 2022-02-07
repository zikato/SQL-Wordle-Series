USE [master]
ALTER DATABASE [Wordle] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
go 
DROP DATABASE [Wordle]
GO
CREATE DATABASE Wordle;
GO

USE Wordle
GO

DROP TABLE IF EXISTS #Stage
CREATE TABLE #Stage
(
	  Word char(5) null
)

DROP TABLE IF EXISTS dbo.Solution
DROP TABLE IF EXISTS dbo.Available
DROP SEQUENCE IF EXISTS dbo.WordId

GO
CREATE SEQUENCE dbo.WordId
	AS smallint
	START WITH 0
	INCREMENT BY 1
	MINVALUE 0
	NO CYCLE
	CACHE 1000;

CREATE TABLE dbo.Solution
(
	Id smallint NOT NULL CONSTRAINT DF_Solution_Id  DEFAULT NEXT VALUE FOR WordId
	, Word char(5) NOT NULL UNIQUE
	, SolveDate AS DATEADD(DAY,Id,DATEFROMPARTS(2021,06, 19))
	, INDEX CX_Solution_Id CLUSTERED (Id)
	, CONSTRAINT PK_Solution_Word PRIMARY KEY NONCLUSTERED (Word)
)

CREATE TABLE dbo.Available
(
	Id smallint NOT NULL CONSTRAINT DF_Available_Id  DEFAULT NEXT VALUE FOR WordId
	, Word char(5) NOT NULL UNIQUE
	, INDEX CX_Available_Id CLUSTERED (Id)
	, CONSTRAINT PK_Available_Word PRIMARY KEY NONCLUSTERED (Word)
)

BULK INSERT #Stage
FROM 'D:\SQL-Wordle-Series\Lists\Solution.txt'
WITH
(
	FIRSTROW = 1,
	FIELDTERMINATOR = '',  --CSV field delimiter
	ROWTERMINATOR = '\n',   --Use to shift the control to next row
	TABLOCK
)

INSERT INTO dbo.Solution WITH (TABLOCKX)
(Word) 
SELECT s.Word FROM #Stage AS s
OPTION (MAXDOP 1)

TRUNCATE TABLE #Stage

BULK INSERT #Stage
FROM 'D:\SQL-Wordle-Series\Lists\Available.txt'
WITH
(
	FIRSTROW = 1,
	FIELDTERMINATOR = '',  --CSV field delimiter
	ROWTERMINATOR = '\n',   --Use to shift the control to next row
	TABLOCK
)

INSERT INTO dbo.Available WITH (TABLOCKX)
(Word) 
SELECT s.Word FROM #Stage AS s
OPTION (MAXDOP 1)

GO
CREATE OR ALTER VIEW dbo.AllWords
AS
SELECT 
	s.Id
	, s.Word
	, s.SolveDate
FROM dbo.Solution AS s
UNION ALL /* These two sets don't intersect */
SELECT
	a.Id
	, a.Word
	, NULL
FROM dbo.Available AS a

GO
