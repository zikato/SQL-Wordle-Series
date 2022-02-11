DROP TABLE IF EXISTS dbo.GameHistory
CREATE TABLE dbo.GameHistory
(
	SolutionId smallint NOT NULL
	, GuessAttempt tinyint NOT NULL
	, GuessId smallint NOT NULL
	, Score char(5) NOT NULL
	, CONSTRAINT PK_GameHistory PRIMARY KEY CLUSTERED (SolutionId, GuessAttempt)
)

GO 

CREATE OR ALTER PROCEDURE dbo.PlayWordle
(
	@guess char(5)
	, @date date = NULL
	, @wordleNum smallint = NULL	/* has precedence over @date */
)
AS
BEGIN
	SET XACT_ABORT ON
	BEGIN TRY
		/* Input handling */
		
		DECLARE 
			@guessId smallint
			, @solutionId smallint
			, @lastAttemptNum tinyint
			, @score char(5)

		/* Guessed word is valid */
		SET @guessId = (SELECT Id FROM dbo.AllWords WHERE Word = @guess)
		IF (@guessId IS NULL)
			RAISERROR('Guessed word "%s" is invalid', 11, 1, @guess)

		/* Solution Id is provided either directly or through a date */
		SET @solutionId = @wordleNum
		IF @solutionId IS NULL 
		BEGIN 
			SET @date = ISNULL(@date, GETDATE())

			IF (@date < '2021-06-19 00:00:00.000' OR @date > '2027-10-21 00:00:00.000')
				RAISERROR('Date must be between 2021-06-19 and 2027-10-21', 11, 1)
			SET @solutionId = (SELECT s.Id FROM dbo.Solution AS s WHERE s.SolveDate = @date)
		END 

		/* check if game is already finished */
		IF EXISTS 
		(
			SELECT 1/0 FROM dbo.GameHistory 
			WHERE SolutionId = @solutionId 
			AND GameHistory.Score = 'GGGGG'
		)
		BEGIN 
			SELECT 
				'Please reset using "EXEC dbo.ResetGame @wordleNum = ' + CAST(@solutionId AS varchar(5)) + '".' AS [You already won]
				, gh.GuessAttempt
				, aw.Word
				, gh.Score
			FROM dbo.GameHistory AS gh
			JOIN dbo.AllWords AS aw
				ON gh.GuessId = aw.Id
			WHERE gh.SolutionId = @solutionId
			ORDER BY gh.GuessAttempt

			RETURN
		END 

		/* Max number of attempts has not been reached yet */
		SET @lastAttemptNum = (SELECT MAX(GuessAttempt) FROM dbo.GameHistory WHERE SolutionId = @solutionId)
		IF (@lastAttemptNum >= 6)
			RAISERROR('Solution #%i already has 6 attempts. Please reset using "EXEC dbo.ResetGame @wordleNum = %i".',11, 1, @solutionId, @solutionId)

		/* Calculate current guess score */
		SELECT @score = sw.score FROM dbo.ScoreWordle(@guessId, @solutionId) AS sw

		/* Persist the guess attempt */
		INSERT INTO dbo.GameHistory 
		(SolutionId, GuessAttempt, GuessId, Score)
		SELECT
			@solutionId, ISNULL(@lastAttemptNum, 0) + 1, @guessId, @score

		SELECT 
			gh.GuessAttempt
			, aw.Word
			, gh.Score
		FROM dbo.GameHistory AS gh
		JOIN dbo.AllWords AS aw
			ON gh.GuessId = aw.Id
		WHERE gh.SolutionId = @solutionId
		ORDER BY gh.GuessAttempt

		/* Check for solution or end game condition */
		IF @score = 'GGGGG'
			SELECT CASE @lastAttemptNum + 1
				WHEN 1 THEN 'Genius'
				WHEN 2 THEN 'Magnificent'
				WHEN 3 THEN 'Impressive'
				WHEN 4 THEN 'Splendid'
				WHEN 5 THEN 'Great'
				WHEN 6 THEN 'Phew'
			ELSE 
				'You won'
			END AS Victory

		IF (@score <> 'GGGGG' AND @lastAttemptNum = 5)
			SELECT s.Word AS Solution
			FROM dbo.Solution AS s
			WHERE s.Id = @solutionId
	
	END TRY
	BEGIN CATCH
		;throw
	END CATCH
END

GO 
CREATE OR ALTER PROCEDURE dbo.ResetGame
(
	@wordleNum smallint
	, @deleteAll bit = 0
)
AS
BEGIN
	IF @deleteAll = 1
		TRUNCATE TABLE dbo.GameHistory
	ELSE
		DELETE FROM dbo.GameHistory
		WHERE SolutionId = @wordleNum
END
GO