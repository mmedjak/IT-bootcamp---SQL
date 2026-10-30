-- Део А - питања о подацима
-- 1. Колико утакмица је одиграно у фебруару 2025?

SELECT
    count (*)
FROM matches
WHERE date (kickoff_ts) >= '2025-02-01'
    AND date (kickoff_ts) < '2025-03-01';

-- A1 --> 40 utakmica je odigrano u februaru 2025.

-- 2. Који стадион има највећи капацитет, а који је највећи стадион неког клуба?

SELECT * 
FROM stadiums
ORDER BY capacity DESC; -- National Stadium, kapacitet od 80 000 (stadium_id = 22)

SELECT * 
FROM teams
WHERE stadium_id = 22; -- nema tima

SELECT *
FROM teams t
INNER JOIN stadiums s ON s.stadium_id = t.stadium_id
ORDER BY s.capacity DESC;

-- A2 --> Stadion sa najvećim kapacitetom (80 000) je National Stadium u gradu Centralia, ali taj stadion nije stadion nijednog kluba. Najveći klupski stadion je Harbourside Park (klub Northport United) kapaciteta 52 000.

-- 3. Колико играча у лиги има српско држављанство (nationality = 'Serbia')?

SELECT count (*)
FROM players
WHERE nationality = 'Serbia';

-- A3 --> 42 igrača u ligi ima srpsko državljanstvo.

-- 4. Колико утакмица је завршено резултатом 1:1?

SELECT count (*)
FROM matches
WHERE home_goals = 1
    AND away_goals = 1
;

-- A4 --> 94 utakmice su se završile rezultatom 1:1

-- 5. Колика је просечна посета по сезони?

SELECT 
    season,
    round (avg (attendance), 2) AS avg_attendance
FROM matches
WHERE attendance IS NOT NULL
GROUP BY season;

-- A6 --> Prosečna poseta sezone 2023/24 bila je 24 252,95, a sezone 2024/25 nešto manja, 24 199,49.

-- 6. Колико голова је дато из пенала по сезони?

SELECT DISTINCT event_type
FROM match_events;

SELECT 
    m.season,
    count (e.event_id)
FROM match_events e
JOIN matches m ON m.match_id = e.match_id
WHERE event_type = 'penalty_goal'
GROUP BY season;

-- A6 --> U prvoj sezoni postiognuto je 104, a u drugoj 109 golova iz penala.

-- 7. Колико различитих играча је дало бар један гол у сезони 2024/25?

SELECT count (DISTINCT e.player_id)
FROM match_events e
JOIN matches m ON m.match_id = e.match_id
WHERE e.event_type IN ('goal', 'penalty_goal')
    AND m.season = '2024/25';

-- A7 --> 308 igrača se upisalo u strelce bar jednom u sezoni 2024-25 (ali autogolovi nisu računati).

-- 8. Који судија је највише пута судио утакмице клуба Northport United?

SELECT 
    m.referee_id,
    r.referee_name,
    count (*) AS matches_count
FROM matches m
JOIN teams ht ON ht.team_id = m.home_team_id
JOIN teams awt ON awt.team_id = m.away_team_id
JOIN referees r ON r.referee_id = m.referee_id
WHERE ht.team_name = 'Northport United' 
    OR awt.team_name = 'Northport United'
GROUP BY m.referee_id, r.referee_name 
ORDER BY matches_count DESC;

-- A8 --> Sudija Peter Lindgren (referee_id 4) je najviše puta (9) sudio utakmice kluba Northport United.


-- 9. Који судија је у сезони 2024/25 имао највећи удео утакмица у којима је досуђен бар један пенал, дат или промашен?


SELECT 
    m.referee_id,
    r.referee_name,
    count (DISTINCT e.match_id) AS penalty_matches
FROM match_events e
JOIN matches m ON m.match_id = e.match_id
JOIN referees r ON r.referee_id = m.referee_id
WHERE m.season = '2024/25'
    AND event_type IN ('penalty_goal', 'penalty_miss')
GROUP BY m.referee_id, r.referee_name
ORDER BY penalty_matches DESC
; 

SELECT 
    count (DISTINCT e.match_id) AS penalty_matches
FROM match_events e
JOIN matches m ON m.match_id = e.match_id
WHERE m.season = '2024/25'
    AND event_type IN ('penalty_goal', 'penalty_miss');


-- A9 --> Sudija Peter Lindgren je imao najveći udeo utakmica u kojima je dosuđen bar jedan penal (dat ili promašen) sa 9 utakmica od ukupnih 105 utakmica sa penalima.

-- 10. Који тренер је освојио највише бодова у утакмицама у којима је његов тим губио на полувремену? Рачунајте и домаће и гостујуће утакмице.
-- Ovaj zadatak nije zavrsen, vraticu se kasnije na njega.
WITH all_matches AS (
                SELECT -- tim kao domacin
                    m.match_id,
                    t.team_name,
                    m.home_goals_ht AS goals_for_ht,
                    m.home_goals AS goals_for,
                    m.away_goals_ht AS goals_against_ht,
                    m.away_goals AS goals_against
                FROM matches m
                JOIN teams t ON t.team_id = m.home_team_id 
                WHERE m.status = 'played'
                AND m.season = '2024/25'

                UNION ALL

                SELECT -- tim kao gost
                    m.match_id,
                    t.team_name,
                    m.away_goals AS goals_for,
                    m.away_goals_ht AS goals_for_ht,
                    m.home_goals AS goals_against,
                    m.home_goals_ht AS goals_against_ht
                FROM matches m
                JOIN teams t ON t.team_id = m.away_team_id 
                WHERE m.status = 'played'
                AND m.season = '2024/25'
) 


SELECT 
        sum (goals_for + goals_against) AS total_goals
FROM all_matches am
JOIN manager_spells
WHERE goals_for_ht < goals_against_ht
    AND goals_for > goals_against
ORDER BY match_id;





