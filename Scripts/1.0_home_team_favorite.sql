/* How often is the home team the favorite? */

/* Filtered out pick-em games, games with no lines, and neutral site games */

WITH favorite AS (
	SELECT 
		g.team_home,
		t.team_id AS home_id,
		g.team_away,
		g.team_favorite_id,
		g.spread_favorite,
		CASE
			WHEN t.team_id = g.team_favorite_id THEN 'Home team is favorite'
			ELSE 'Visiting team is favorite'
		END AS home_or_visitor_favorite	
	FROM
		game_info g
		LEFT JOIN nfl_teams t ON g.team_home = t.team_name 
	WHERE
		spread_favorite IS NOT NULL AND
		team_favorite_id != 'PICK' AND
		stadium_neutral IS FALSE
)

SELECT
	home_or_visitor_favorite,
	COUNT(home_or_visitor_favorite) AS number_of_games,
	SUM(COUNT(home_or_visitor_favorite)) OVER() AS total_games,
	ROUND(100 * (COUNT(home_or_visitor_favorite) / SUM(COUNT(home_or_visitor_favorite)) OVER()), 1) AS percentage
FROM
	favorite
GROUP BY
	home_or_visitor_favorite

