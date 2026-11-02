Milena Medjak

## OPIS PROJEKTA

Projekat u okviru IT bootcamp.

Zadaci za proveru znanja iz SQL-a. 

Zadaci se rešavaju nad dostupnim tabelama u Databricksu.


### PRETPOSTAVKE:

A7: Auto gol ('own_goal') nije računat u postognute golove igrača.
B3: Utakmice za koje nije zabelezena poseta nisu ukljucene u izracunavanje proseka.
C3: Auto gol ('own_goal') nije računat u poslednje golove kluba; event_id je korišćen da dodatno sortira vreme postizanja gola sa pretpostavkom da se gol koji je kasnije unet u bazu (sa većim event_id) dogodio kasnije.

Napomena za Deo D: Tabele iz bootcamp.northernstar sheme koje se koriste za izradu ovog zadatka prvo su kopirane u shemu bootcamp.sandbox2 kao {tabela}_copy, pa su tako korišćene za izradu zadatka u cilju održanja integriteta podataka.

### Model kreiran u Delu D

U ovoj vežbi kreirana je zvezdasta šema tabela koja prikazuje kartone lige (žuti, drugi žuti i crveni) kao pojedinačne redove u središnjoj tabeli fact_card. U tabelama direktno povezanim sa središnjom tabelom prikazani su dodatni podaci vezani za tim, igrača, sudiju i datum iz određenog događaja dodele kartona.

Tabela fact_card je kreirana na osnovu tabele match_events_copy iz koje su preuzeti podaci o izabranim događajima (samo događaji čiji je tip yellow_card, second_yellow ili red_card), utakmici, klubu, igraču i tipu kartona, dok je iz povezane tabele matches_copy preuzet datum odigravanja utakmice i identifikator sudije. Dodatno je korišćena tabela players_copy kao kontrola da se u novu tabelu unesu ispravni podaci, odnosno da se podaci o nepoznatim igračima jasno razdvoje (player_id = -1).

Na ovaj način je kreirana fact_card tabela u kojoj jedan red predstavlja jedan događaj dodele kartona u određenoj utakmici.

Tabela fact_card povezana je sa drugim kreiranim tabelama koje obezbeđuju dodatne informacije na sledeći način:
* tabela dim_date preko date_key
* tabela dim_player preko player_id
* tabela dim_referee preko referee_id
* tabela dim_team preko team_id
