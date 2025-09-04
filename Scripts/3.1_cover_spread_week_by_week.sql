-- How often did the spread favorite cover the spread, week by week?

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
), against_the_spread AS (
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
	schedule_week,
	schedule_week_int,
	fav_against_spread,
	COUNT(fav_against_spread),
	SUM(COUNT(fav_against_spread)) OVER (PARTITION BY schedule_week) AS total_weekly_games,
	ROUND(100 * COUNT(fav_against_spread) / SUM(COUNT(fav_against_spread)) OVER (PARTITION BY schedule_week), 1) AS percentage
FROM against_the_spread
GROUP BY
	schedule_week_int,
	schedule_week,
	fav_against_spread
ORDER BY
	schedule_week_int,
	fav_against_spread
