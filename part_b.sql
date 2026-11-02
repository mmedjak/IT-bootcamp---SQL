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

-- Dodato: prosečna poseta i popunjenost po stadionu:

SELECT 
    s.stadium_id,
    s.stadium_name,
    m.match_id 
FROM stadiums s
LEFT JOIN matches m ON m.stadium_id = s.stadium_id 
        AND m.season = '2024/25'
WHERE m.match_id IS NULL; -- stadion Fairhaven Lane (stadium_id = 20) nije korišćen u sezoni 2024/25.

--prosecna poseta i popunjenost po stadionu, utakmice bez podatka o poseti su izostavljene
SELECT 
    s.stadium_id,
    s.stadium_name,
    round (avg (m.attendance), 2) AS avg_attendance,
    round (avg (100* m.attendance / s.capacity), 2) AS avg_occupancy
FROM stadiums s
JOIN matches m ON m.stadium_id = s.stadium_id 
WHERE m.attendance IS NOT NULL
        AND m.season = '2024/25'
GROUP BY s.stadium_id, s.stadium_name
ORDER BY avg_occupancy DESC
; 

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

SELECT DISTINCT event_type
FROM match_events;

SELECT 
    match_id,
    count (*) AS total_goals
FROM match_events e
WHERE event_type IN ('goal', 'penalty_goal', 'own_goal')
GROUP BY match_id;

WITH total_goals AS
        (SELECT 
            match_id,
            count (*) AS total_goals
        FROM match_events e
        WHERE event_type IN ('goal', 'penalty_goal', 'own_goal')
        GROUP BY match_id
        )
SELECT 
    m.home_team_id,
    m.away_team_id,
    tg.match_id,
    tg.total_goals AS goals_from_matchevents,
    m.home_goals + m.away_goals AS goals_from_matches
FROM total_goals tg
JOIN matches m ON m.match_id = tg.match_id
WHERE m.season = '2024/25'
    AND tg.total_goals <> m.home_goals + m.away_goals; 
 
SELECT * FROM match_events WHERE match_id = 2227; -- ht, ht own goal, awt 1:2 
SELECT * FROM matches WHERE match_id = 2227; --3:1  ht 21 awt 12

WITH goals_from_mevents AS
    (SELECT 
        m.match_id,
        sum (CASE 
            WHEN e.event_type IN ('goal', 'penalty_goal') AND e.team_id = ht.team_id
                OR e.event_type = 'own_goal' AND e.team_id = awt.team_id 
                THEN 1
            ELSE 0        
        END) AS home_goals_from_matchevents,
        sum (CASE 
            WHEN e.event_type IN ('goal', 'penalty_goal') AND e.team_id = awt.team_id
                OR e.event_type = 'own_goal' AND e.team_id = ht.team_id 
                THEN 1
            ELSE 0        
        END) AS away_goals_from_matchevents
    FROM match_events e
    JOIN matches m ON m.match_id = e.match_id
    JOIN teams ht ON ht.team_id = m.home_team_id
    JOIN teams awt ON awt.team_id = m.away_team_id 
    GROUP BY m.match_id
)


SELECT 
m.match_id,
date (m.kickoff_ts),
concat (ht.team_name, ' - ', awt.team_name) AS match_between,
concat (m.home_goals, ' : ', m.away_goals) AS result_from_matches,
concat (gfe.home_goals_from_matchevents, ' : ', gfe.away_goals_from_matchevents) AS result_from_matchevents

FROM matches m
JOIN goals_from_mevents gfe ON gfe.match_id = m.match_id
JOIN teams ht ON ht.team_id = m.home_team_id
JOIN teams awt ON awt.team_id = m.away_team_id
WHERE m.match_id = 2227
;


-- Upitima iznad sam ustanovila da postoji neslaganje u podacima o golovima za utakmicu sa match_id 2227, odnosno da je prema tabeli match_events rezultat bio 1:2, a prema tabeli matches 3:1.


-- SELECT DISTINCT team_id
-- FROM manager_spells ms
-- WHERE NOT EXISTS (
--     SELECT 1
--     FROM match_events e
--     WHERE e.team_id = ms.team_id
-- )
-- ;

SELECT 
    ms.team_id,
    t.team_name, 
    ms.manager_name,
    ms.start_date,
    ms.end_date,
    ms.is_caretaker
FROM manager_spells ms
JOIN teams t ON t.team_id = ms.team_id
WHERE start_date < '2025-05-20' AND (end_date > '2024-08-01' OR end_date IS NULL)
ORDER BY ms.team_id;

-- Pregledom podataka dobijenih ovim upitom ustanovila sam da je Westmere Town bio bez trenera između 27. februara i 3. marta 2025, kao i da postoje duplirani podaci za tim 7.

