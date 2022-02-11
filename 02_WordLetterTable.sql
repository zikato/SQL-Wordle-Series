DROP TABLE IF EXISTS dbo.WordLetter
CREATE TABLE dbo.WordLetter
(
	WordId smallint NOT NULL
	, Word char(5) NOT NULL /* so I don't have to join */
	, Letter char(1) NOT NULL 
	, Position tinyint NOT NULL
	, CONSTRAINT PK_WordLetter PRIMARY KEY CLUSTERED (Letter, Position, WordId)
	, INDEX IX_WordLetter_Position NONCLUSTERED (Position)
)

/* Unpivot the table */
INSERT INTO dbo.WordLetter WITH (TABLOCKX)
(WordId, Word, Letter, Position)
SELECT 
	aw.Id
	, aw.Word
	, SUBSTRING(aw.Word, cj.Position, 1)
	, cj.Position
FROM dbo.AllWords AS aw
CROSS JOIN (VALUES (1), (2), (3), (4), (5)) AS cj(Position)