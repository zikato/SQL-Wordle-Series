CREATE OR ALTER FUNCTION dbo.ScoreWordle
(
	@guessId smallint
	, @solutionId smallint
)
RETURNS TABLE
AS
RETURN
	WITH score AS
	(
		SELECT
			g.WordId AS guessWordId
			, s.WordId AS SolutionWordId
			, g.Letter
			, g.Position AS guessPosition
			, s.Position AS solutionPosition
			, ca.dist
			, ROW_NUMBER() OVER (PARTITION BY s.WordId, s.Letter, s.Position ORDER BY ca.dist) AS rn
		FROM
			dbo.WordLetter AS g
			JOIN dbo.WordLetter AS s
				ON g.Letter = s.Letter
			CROSS APPLY
			(VALUES (ABS(CAST(g.Position AS smallint) - s.Position))) AS ca(dist)
		WHERE
			g.WordId = @guessId
			AND s.WordId = @solutionId
	)
	SELECT
		CONCAT
		(
			  MAX(CASE WHEN s.guessPosition = 1 THEN ca.score ELSE 'B' END)
			, MAX(CASE WHEN s.guessPosition = 2 THEN ca.score ELSE 'B' END)
			, MAX(CASE WHEN s.guessPosition = 3 THEN ca.score ELSE 'B' END)
			, MAX(CASE WHEN s.guessPosition = 4 THEN ca.score ELSE 'B' END)
			, MAX(CASE WHEN s.guessPosition = 5 THEN ca.score ELSE 'B' END)
		) AS score
	FROM dbo.WordLetter AS wl
	LEFT JOIN score AS s
		ON wl.WordId = s.guessWordId
		AND s.rn = 1
		AND s.guessPosition = wl.Position
	CROSS APPLY
	(
		VALUES
		(
			CASE
				WHEN s.dist = 0 THEN 'G' /* Green = match letter and position */
				WHEN s.dist > 0 THEN 'O' /* Orange = correct letter, wrong position */
				ELSE 'B' /* Black = does not contain the letter */
			END
		)
	) ca (score)
	WHERE wl.WordId = @guessId
	GROUP BY wl.WordId

GO
