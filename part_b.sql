-- Део Б - извештај о сезони 2024/25
-- Управа лиге тражи кратак извештај о сезони 2024/25. Предајете два фајла: извештај у формату по избору (Markdown, Txt или PDF) и part_b.sql са свим упитима које сте користили. За сваки одељак у извештају дајте малу табелу или неколико бројева, и реченицу или две шта ти бројеви значе.

-- 1. Преглед сезоне: број утакмица и голова, просечан број голова по утакмици, удео победадомаћина, нерешених и победа гостију.

SELECT 
    count (*) AS matches_count,
    sum (home_goals + away_goals) AS all_goals,
    round (sum (home_goals + away_goals) / count (match_id), 2) AS goals_per_match 
FROM matches
WHERE season = '2024/25'
    AND status = 'played';

-- B1: 380 utakmica, 1092 gola i 2,87 golova po utakmici.


WITH outcome AS (
SELECT
    count (match_id) AS matches_count,
    sum (CASE
            WHEN home_goals > away_goals THEN 1
            ELSE 0
        END) AS home_win, --157
    sum (CASE 
            WHEN home_goals = away_goals THEN 1
            ELSE 0
        END) AS draws, --95
    sum (CASE 
            WHEN home_goals < away_goals THEN 1
            ELSE 0
        END) as away_win    --128
FROM matches
WHERE season = '2024/25'
    AND status = 'played')

SELECT 
    matches_count,
    home_win,
    round (100* home_win / matches_count, 2) AS home_win_pct,
    draws,
    round (100* draws / matches_count, 2) AS draws_pct,
    away_win,
    round (100* away_win / matches_count, 2) AS away_win_pct

FROM outcome;


-- B1 --> matches_count	    home_win    	home_win_pct	    draws   	draws_pct	    away_win	away_win_pct
--              380	            157	                41.32	        95	            25	         128	      33.68



-- 2. По месецима: број утакмица и голова по месецима, и просечан број голова по утакмици у сваком месецу. Који месец се издваја?

SELECT 
    concat (month (kickoff_ts), ' / ', year (kickoff_ts)) AS month,
    count (*) AS matches_count,
    sum (home_goals + away_goals) AS all_goals,
    round (sum (home_goals + away_goals) / count (match_id), 2) AS goals_per_match 
FROM matches
WHERE season = '2024/25'
    AND status = 'played'
GROUP BY month
ORDER BY goals_per_match
;

-- 3. Публика: просечна посета и попуњеност по стадиону; утакмице без податка о посети иутакмица без публике.

SELECT count (*)
FROM matches
WHERE season = '2024/25'
    AND status = 'played'
    AND attendance IS NULL
; -- 9

SELECT *
FROM matches
WHERE season = '2024/25'
    AND status = 'played'
    AND attendance IS NOT NULL
; -- nema posete = 0, 371 utakmica sa zabelezenom posetom


SELECT 
    count (*) AS matches_count,
    round (avg (attendance), 2) AS avg_attendance 
FROM matches
WHERE season = '2024/25'
    AND status = 'played'
    AND attendance IS NOT NULL;

-- 371	24199.49


SELECT 
    round (avg (attendance), 2) AS avg_attendance,
    round (avg (100* m.attendance / s.capacity), 2) AS avg_occupancy_pct
FROM matches m
JOIN stadiums s ON s.stadium_id = m.stadium_id
WHERE season = '2024/25'
    AND status = 'played'
    AND attendance IS NOT NULL
; --24 199,49; 85,66


-- 4. Судије:за сваког судију број утакмица и картони по утакмици.


WITH cards_count AS
(SELECT 
    r.referee_name,
    count (DISTINCT m.match_id) AS matches_ref,
    sum (CASE
            WHEN e.event_type IN ('yellow_card', 'second_yellow', 'red_card') THEN 1
            ELSE 0
        END) AS total_cards_count
FROM matches m
JOIN referees r ON r.referee_id = m.referee_id
JOIN match_events e ON e.match_id = m.match_id
WHERE m.season = '2024/25'
    AND m.status = 'played'
GROUP BY r.referee_name
ORDER BY total_cards_count DESC)

SELECT *,
    round (total_cards_count/matches_ref, 2) AS cards_per_match
FROM cards_count
ORDER BY total_cards_count DESC
;


-- 5. Играчи: пет најбољих стрелаца и пет најбољих асистената.


SELECT 
    count (e.event_id) AS goals_scored,
    concat (p.first_name, ' ', p.last_name) AS player
FROM match_events e
JOIN matches m ON m.match_id = e.match_id
JOIN players p ON p.player_id = e.player_id
WHERE m.season = '2024/25'
    AND event_type IN ('penalty_goal', 'goal')
GROUP BY e.player_id, player
ORDER BY goals_scored DESC
LIMIT 5
;


SELECT 
    count (e.event_id) AS assistances,
    concat (p.first_name, ' ', p.last_name) AS player
FROM match_events e
JOIN matches m ON m.match_id = e.match_id
JOIN players p ON p.player_id = e.related_player_id
WHERE   m.season = '2024/25'
    AND event_type IN ('penalty_goal', 'goal')
GROUP BY e.related_player_id, player
ORDER BY assistances DESC
LIMIT 5
;


-- 6. Квалитет података: бар два проблема на која сте наишли у подацима (на пример утакмица чији резултат се не слаже са догађајима, догађаји са непостојећим играчем, дан без тренера), са упитима који их проналазе.