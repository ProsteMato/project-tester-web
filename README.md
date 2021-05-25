# Project Tester

author: xkocim05 (Martin Koči)

email: xkocim05@stud.fit.vutbr.cz

Jedná sa o webovú aplikáciu, kde si uživatelia vedia vytvárať zadania projektov. Následne riešitelia daných projektov si vedia stiahnúť zadanie a prípadne aj testovací skript. Na vebovej aplikácii je možnosť testovania projektu kedy sa cez WebSocket pripojíme na server a on nám otestuje odovzdaný projekt a priebežne vypisuje status testovania až dokým sa nevrátia výsledky testovania a neuložia sa do databáze.


## Požiadavky

Ubuntu >= [18.04]

swift >= [5.3.3]

vapor framework >= [4.45.5]

vapor toolbox >= [18.3.3]

## Databaza 

Použivíva sa databáza postregSQL. Konfigurácia databáza (Teba si vytvoriť):

Uživateľa menom a heslom postgres a tabulku tiež s názvom postgres

ak by ste mali inú treba zmeniť nastavenia v súbore `configuration.swift`

prípadne nastaviť enviromentálne premenné `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`,`DATABASE_PASSWORD`, `DATABASE_NAME`.

## Spustenie projektu

Najskôr sa použije príkaz `vapor build` pre preloženie projektu.

Následne treba zavolať `vapor run migrate` vytvorý databázové tabuľky.

A ako posledné treba spustiť server pomocou `vapor run`

## Otestovanie aplikácie

Testovací scenár:

1. Aktuálne sa nachádzate na prihlasovacek stránke. Prejdite na registráciu.
2. Vytvorte si profil musíte zadať všetky políčka. Zaregistrujte sa.
3. Prihláste sa s vytvorených učtom v predchádzajúcom kroku.
4. Po prihlásení ste na stránke projektov a môže si vytvoriť projekt.
5. Vytvorete si projekt klikuným na `Create projekt` v pravo hore. Musite zadať všetky možnosti. Pre jednoduchosť v repozitáry projektu je repozitár `Tests/` v ktorom sa nachádzajú všetky súbory ktoré sa dajú použiť pri vytváraní projektu a jeho odovzdávani. Nachádza sa tam aj `project-tester.pdf` a `project-tester.sh` tieto použite pre vytvorenie projektu.
6. Ste na stránke projektov kliknite na práve vytvorený projekt.
7. Môžete ho skúsiť otestovať v pravo hore mala by sa ukázať chyba.
8. Odovzdate projekt. Nahrajte súbor `Tests/project-tester.zip` a znova skúste otestovať.

## Vlastne skripty

Pri vytváraní vlastných skriptov treba myslieť na to že skript berie jeden argument a to je projekt ktorý bude práve testovať. Následne skripty si musia riešiť rozbalienie a zmazanie súborov `.zip` archívu same.





