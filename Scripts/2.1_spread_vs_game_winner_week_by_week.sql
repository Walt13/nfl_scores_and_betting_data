/* See if we can figure out how often the spread favorite
 * correctly predicted the actual game winner (regardless of spread),
 * and see how this changes over the course of the season.
 */

/* First CTE (game_winner) figures out who won each game. 
 * Filtered out games with no lines and games that were a pick'em.
 * 
 * Second CTE (favorite_or_underdog) figures out if the team that actually won
 * the game was the spread favorite or not.
 * 
 * Main query gives us the results.
 */

WITH game_winner AS (
	SELECT 
		schedule_date,
		schedule_season,
		CASE
			WHEN schedule_week = 'Wildcard' THEN 20
			WHEN schedule_week = 'Division' THEN 21
			WHEN schedule_week = 'Conference' THEN 22
			WHEN schedule_week = 'Superbowl' THEN 23
			ELSE schedule_week::INT
		END AS schedule_week_int, -- The schedule_week column is a varchar and sorts lexicographically. Created schedule_week_int to fix this. 
		schedule_week,
		team_home,
		score_home,
		score_away,
		team_away,
		team_favorite_id,
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
), favorite_or_underdog AS (
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
)

SELECT
	schedule_week,
	schedule_week_int,
	spread_vs_game,
	COUNT(spread_vs_game),
	SUM(COUNT(spread_vs_game)) OVER (PARTITION BY schedule_week) AS total_weekly_games,
	ROUND(100 * COUNT(spread_vs_game) / SUM(COUNT(spread_vs_game)) OVER (PARTITION BY schedule_week), 1) AS percentage
FROM
	favorite_or_underdog
GROUP BY
	schedule_week_int,
	schedule_week,
	spread_vs_game
ORDER BY
	schedule_week_int,
	spread_vs_game
