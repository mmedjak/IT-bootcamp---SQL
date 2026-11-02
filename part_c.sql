-- Део В - прозорске функције
-- Свако питање мора да користи бар једну прозорску функцију.

-- 1. Колики удео у укупном броју голова лиге у сезони 2024/25 има сваки клуб? Ко има највећи удео?

WITH all_matches AS (
                SELECT -- tim kao domacin
                   m.match_id,
                   t.team_id,
                   t.team_name,
                   m.home_goals AS goals_for,
                   m.away_goals AS goals_against
                FROM matches m
                JOIN teams t ON t.team_id = m.home_team_id 
                WHERE m.status = 'played'
                    AND m.season = '2024/25' 
               
             UNION ALL

                SELECT -- tim kao gost
                    m.match_id,
                    t.team_id,
                    t.team_name,
                    m.away_goals AS goals_for,
                    m.home_goals AS goals_against
                FROM matches m
                JOIN teams t ON t.team_id = m.away_team_id 
                WHERE m.status = 'played'
                    AND m.season = '2024/25'
        ) 
    SELECT DISTINCT
        am.team_id,
        t.team_name,
        sum (am.goals_for) OVER (PARTITION BY am.team_id) sum_goals,
        round (100* sum (am.goals_for) OVER (PARTITION BY am.team_id) / sum (am.goals_for) OVER (), 2) AS goals_share_pct
    FROM all_matches am
    JOIN teams t ON t.team_id = am.team_id
    ORDER BY goals_share_pct DESC;

-- C1 --> Najveći udeo u ukupnom broju golova u sezoni 2024/25 ima klub Kingsbridge City (7,6%, odnosno 83 gola).

-- 2. Која су три стадиона са највећом просечном посетом у сезони 2024/25?


SELECT DISTINCT
   m.stadium_id,
   s.stadium_name,
   round (avg (m.attendance) OVER (PARTITION BY m.stadium_id), 2) AS avg_attendance
FROM matches m
JOIN stadiums s ON s.stadium_id = m.stadium_id 
WHERE m.season = '2024/25'
ORDER BY avg_attendance DESC
LIMIT 3;


-- C2 --> To su Harbourside Park, Kingsbridge Stadium i Northport Arena.

-- 3. За сваки клуб, ко је дао последњи гол клуба у сезони 2024/25 и када? Који клуб је последњигол дао најраније?

-- Autogolovi nisu računati u poslednje golove kluba. Za hronološko sortiranje golova pored vremena početka utakmice je korišćen i event_id pod pretpostavkom da se gol koji je kasnije unet u bazu (sa većim event_id) dogodio kasnije.


WITH rn AS (
            SELECT
                e.event_id,
                date (m.kickoff_ts) AS goal_date,
                e.player_id,
                p.first_name,
                p.last_name,
                t.team_name,
                row_number () OVER (PARTITION BY e.team_id ORDER BY m.kickoff_ts DESC, e.event_id DESC) as rn
            FROM match_events e
            JOIN matches m ON m.match_id = e.match_id
            JOIN teams t ON t.team_id = e.team_id
            JOIN players p ON p.player_id = e.player_id
            WHERE event_type IN ('goal', 'penalty_goal')
                AND m.season = '2024/25'
)
SELECT 
    goal_date AS last_goal_date,
    team_name,
    concat (first_name, ' ', last_name) AS player
FROM rn
WHERE rn = 1
ORDER BY goal_date;

-- C3 --> Poslednji gol u sezoni je najranije dao Marko Stanković za Elmsworth Wanderers, 3. maja 2025.

-- 4. За домаће утакмице клуба Northport United у сезони 2024/25 прикажите посету и промену уодносу на претходну домаћу утакмицу. Где је највећи пад?

SELECT 
    t.team_name,
    date (m.kickoff_ts) AS match_date,
    lag (m.attendance) OVER (ORDER BY m.kickoff_ts) AS previous_attendance,
    m.attendance,
    lag (m.attendance) OVER (ORDER BY m.kickoff_ts) - m.attendance AS attendance_diff
FROM matches m
JOIN teams t ON t.team_id = m.home_team_id
WHERE t.team_name = 'Northport United'
    AND season = '2024/25'
ORDER BY attendance_diff DESC
;

-- C4 --> Najveći pad posete zabeležen je na utakmici 10.novembra 2024 u odnosu na prethodnu.

-- 5. Пратите бодове клуба Northport City утакмицу по утакмицу у сезони 2024/25. У којој утакмици по реду и ког датума је прешао 50 бодова?

WITH all_matches_points AS (
                                SELECT -- tim kao domacin
                                    m.match_id,
                                    m.kickoff_ts,
                                    t.team_id,
                                    t.team_name,
                                    m.home_goals AS goals_for,
                                    m.away_goals AS goals_against
                                FROM matches m
                                JOIN teams t ON t.team_id = m.home_team_id 
                                WHERE m.season = '2024/25'
                                    AND t.team_name = 'Northport City'
                            
                            UNION ALL

                                SELECT -- tim kao gost
                                    m.match_id,
                                    m.kickoff_ts,
                                    t.team_id,
                                    t.team_name,
                                    m.away_goals AS goals_for,
                                    m.home_goals AS goals_against
                                FROM matches m
                                JOIN teams t ON t.team_id = m.away_team_id 
                                WHERE m.season = '2024/25'
                                    AND t.team_name = 'Northport City'
                )
        SELECT
                date (kickoff_ts) AS match_date,
                sum (CASE
                        WHEN goals_for > goals_against THEN 3
                        WHEN goals_for = goals_against THEN 1
                        ELSE 0
                    END) OVER (PARTITION BY team_id ORDER BY kickoff_ts ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sum,
                ROW_NUMBER() OVER (PARTITION BY team_id ORDER BY kickoff_ts) AS rn
        FROM all_matches_points;



WITH running_sum AS
                (WITH all_matches_points AS (
                                SELECT -- tim kao domacin
                                    m.match_id,
                                    m.kickoff_ts,
                                    t.team_id,
                                    t.team_name,
                                    m.home_goals AS goals_for,
                                    m.away_goals AS goals_against
                                FROM matches m
                                JOIN teams t ON t.team_id = m.home_team_id 
                                WHERE m.season = '2024/25'
                                    AND t.team_name = 'Northport City'
                            
                            UNION ALL

                                SELECT -- tim kao gost
                                    m.match_id,
                                    m.kickoff_ts,
                                    t.team_id,
                                    t.team_name,
                                    m.away_goals AS goals_for,
                                    m.home_goals AS goals_against
                                FROM matches m
                                JOIN teams t ON t.team_id = m.away_team_id 
                                WHERE m.season = '2024/25'
                                    AND t.team_name = 'Northport City'
                )
        SELECT
                date (kickoff_ts) AS match_date,
                sum (CASE
                        WHEN goals_for > goals_against THEN 3
                        WHEN goals_for = goals_against THEN 1
                        ELSE 0
                    END) OVER (PARTITION BY team_id ORDER BY kickoff_ts ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sum,
                ROW_NUMBER() OVER (PARTITION BY team_id ORDER BY kickoff_ts) AS rn
        FROM all_matches_points)

SELECT 
    match_date,
    rn AS match_number
FROM running_sum
WHERE running_sum > 50
ORDER BY match_date
LIMIT 1
;
-- C5 --> Tim Northport City je prešao 50 bodova na 21. utakmici po redu odigranoj 12. januara 2025. 