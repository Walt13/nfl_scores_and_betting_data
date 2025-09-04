-- How often did the spread favorite cover the spread?
-- Filtering out games without spreads and pick'em games

-- This CTE is to figure out who won each game
WITH game_winner AS (
	SELECT 
		team_home,
		score_home,
		score_away,
		team_away,
		team_favorite_id,
		ABS(spread_favorite) AS spread_favorite_line,
		ABS(score_home - score_away) AS margin_of_victory,
		CASE
			WHEN score_home > score_away THEN team_home
			WHEN score_home < score_away THEN team_away
			ELSE 'Tie Game'
		END AS winning_team
	FROM
		game_info
	WHERE
		spread_favorite IS NOT NULL AND
		team_favorite_id != 'PICK'
),
-- CTE to figure out if the spread favorite won the game (not accounting for spread yet)	
   favorite_or_underdog AS (
	SELECT
		gw.*,
		t.team_id,
		CASE
			WHEN t.team_id = team_favorite_id THEN 'Spread favorite won game'
			WHEN t.team_id IS NULL THEN 'Tie game'
			ELSE 'Underdog won game'
		END AS spread_vs_game
	FROM
		game_winner gw
		LEFT JOIN nfl_teams t ON gw.winning_team = t.team_name
),
-- CTE to figure out if the favorite covered or not
   against_the_spread AS (
	SELECT
		fou.*,
		CASE
			WHEN fou.spread_vs_game = 'Spread favorite won game' THEN
				CASE
					WHEN margin_of_victory > spread_favorite_line THEN 'Favorite covers'
					WHEN margin_of_victory = spread_favorite_line THEN 'Push'
					ELSE 'Did not cover'
				END
			ELSE 'Did not cover'
		END AS fav_against_spread
	FROM
		favorite_or_underdog fou
)

SELECT
	fav_against_spread,
	COUNT(fav_against_spread),
	SUM(COUNT(fav_against_spread)) OVER() AS total_games,
	ROUND(100 * (COUNT(fav_against_spread) / SUM(COUNT(fav_against_spread)) OVER()), 1) AS percentage
FROM against_the_spread
GROUP BY
	fav_against_spread
ORDER BY
	fav_against_spread
