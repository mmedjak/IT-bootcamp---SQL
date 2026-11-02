-- D1:

USE bootcamp.sandbox2;

--Napomena: Tabele iz bootcamp.northernstar sheme koje se koriste za izradu ovog zadatka prvo su kopirane u shemu bootcamp.sandbox2 kao {tabela}_copy, pa su tako korišćene u cilju održanja integriteta podataka.

-- Kopirane Tabele teams, players, referees, match_events i matches u novu shemu:
CREATE OR REPLACE TABLE teams_copy AS 
SELECT * FROM bootcamp.northern_star.teams;

CREATE OR REPLACE TABLE players_copy AS 
SELECT * FROM bootcamp.northern_star.players;

CREATE OR REPLACE TABLE referees_copy AS 
SELECT * FROM bootcamp.northern_star.referees;

CREATE OR REPLACE TABLE match_events_copy AS 
SELECT * FROM bootcamp.northern_star.match_events;

CREATE OR REPLACE TABLE matches_copy AS 
SELECT * FROM bootcamp.northern_star.matches;


-- Kreirana nova dim_team tabela sa svim kolonama i klubovima iz teams_copy:
CREATE OR REPLACE TABLE dim_team AS
SELECT * FROM teams_copy;

-- Kreiran kalendar dim_date kao nova tabela:
CREATE OR REPLACE TABLE dim_date AS 
SELECT 
    CAST(DATE_FORMAT(d, 'yyyyMMdd') AS INT) AS date_key, 
    d AS full_date,
    DATE_FORMAT(d, 'EEEE') AS weekday_name, 
    DAYOFWEEK(d) IN (1, 7) AS is_weekend, 
    CASE 
        WHEN MONTH(d) >= 7 THEN CONCAT(YEAR(d), '/', SUBSTRING(CAST(YEAR(d) + 1 AS STRING), 3, 2)) 
        ELSE CONCAT(YEAR(d) - 1, '/', SUBSTRING(CAST(YEAR(d) AS STRING), 3, 2)) 
        END AS season 
    FROM (SELECT EXPLODE(SEQUENCE(DATE'2023-07-01', DATE'2025-06-30', INTERVAL 1 DAY)) AS d);

-- Kreirana nova tabela dim_player sa svim kolonama i igračima iz players_copy uz dodatni red za nepoznatog igrača
CREATE OR REPLACE TABLE dim_player AS
SELECT * FROM players_copy
UNION ALL 
SELECT -1, 'Još nije određen', 'Još nije određen', NULL, NULL, NULL, NULL, NULL, NULL;


-- Kreirana nova tabela dim_referee sa svim kolonama i sudijama iz referees_copy
CREATE OR REPLACE TABLE dim_referee AS
SELECT * FROM referees_copy;

--Kreirana nova tabela fact_card prema zahtevu iz zadatka, korišćen je LEFT JOIN sa players_copy tabelom kako bi se identifikovali igrači bez podataka kojima se dodeljuje id -1, s obzirom da u match_events_copy tabeli nema redova sa NULL vrednostima za player_id.
CREATE OR REPLACE TABLE fact_card AS 
SELECT
    ec.event_id,
    ec.match_id,
    CAST(DATE_FORMAT(mc.kickoff_ts, 'yyyyMMdd') AS INT) AS date_key,    
    ec.team_id,
    COALESCE(pc.player_id, -1) AS player_id,
    mc.referee_id,
    ec.event_type AS card_type
FROM match_events_copy ec
JOIN matches_copy mc ON mc.match_id = ec.match_id
LEFT JOIN players_copy pc ON pc.player_id = ec.player_id
WHERE ec.event_type IN ('yellow_card', 'second_yellow', 'red_card');
    
  
-- D2: Упитом покажите да fact_card има исто редова колико има картонских догађаја:

SELECT count (*)
FROM fact_card; --2678 redova

SELECT count (*)
FROM match_events_copy
WHERE event_type IN ('yellow_card', 'second_yellow', 'red_card'); --2678 redova


-- D2 -- > Upiti iznad (kojima se vraća broj redova iz fact_card i match_events_copy za događaje koji uključuju žuti karton, drugi žuti karton i crveni karton) vraćaju isti broj redova.


-- D3. Колико картона има player_id = -1?

SELECT *
FROM fact_card
WHERE player_id = -1;

-- D3 --> Player_id = -1 ima 2 kartona, žuta.
