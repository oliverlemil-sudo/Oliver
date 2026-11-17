# 🎮 Udviklingsprompt: "MOG MONSTERS" – et komplet Roblox-spil om at mogge monstre

> Kopiér hele denne prompt ind til en AI-udvikler (eller brug den som designdokument).
> Den beskriver et **originalt** spil. Det er inspireret af *gameplay-følelsen* i et populært
> Roblox "mog/steal"-spil, men har **egne navne, egne monstre, et eget kort og et eget UI-design**.

---

## 0. DIN ROLLE

Du er en erfaren **Roblox-spiludvikler, game designer og Luau-programmør**. Du skal bygge et
**komplet, poleret og fuldt fungerende** Roblox-spil i Roblox Studio ud fra denne specifikation.
Det må ikke være en prototype. Alle systemer skal virke, hænge sammen og være testet.

**Arbejd i denne rækkefølge, og stop ikke halvvejs:**
1. Læs hele specifikationen, og skriv en kort teknisk plan (moduler, remotes, datamodel).
2. Byg kernen: data, valuta, MOG POWER, monstre, kampsystemet.
3. Byg kortet, zonerne og boss-arenaerne.
4. Byg UI/HUD og menuerne.
5. Tilføj animationer, effekter, lyd og "juice".
6. Test alt (se tjekliste i afsnit 15), ret fejl, og balancér økonomien.
7. Forbedr spillet, indtil acceptkriterierne i afsnit 16 er opfyldt.

---

## 1. ORIGINALITET (SKAL OVERHOLDES)

- Spillet må **ikke** kopiere referencespillets **navn, logo, figurer, monster-designs, kort,
  tekster eller præcise UI-layout**.
- Det **må gerne** bruge samme **genre og mekanikker**: monstre der vandrer rundt, en kamp-minigame
  med klik, kombo-tæller, monstre der følger dig hjem, tyveri ude i verden, fælder, auto-knap,
  sjældenheder, størrelser/vægt, events med timer, daglig gave osv. Den slags er fælles for genren.
- Alle navne, farver, ikoner og tekster skal være **vores egne**.

---

## 2. HVAD REFERENCEMATERIALET VISER (mekanik-analyse)

Det følgende er **observeret** i referencevideoen. Det er beskrevet som mekanikker, ikke som noget, der skal kopieres:

| Observation | Hvad vi tager med (som idé) |
|---|---|
| Kampen er en **tovtræknings-bar** nederst på skærmen: spilleren til venstre, monsteret til højre | En kamp-minigame, hvor spilleren klikker og skubber en bar mod monsteret |
| **Kombo-tæller** (x8 → x35), der stiger ved hurtige klik | Kombo-system, der giver mere kraft |
| **Hype-ord** flyver rundt om monsteret ved hvert klik i mange farver og vinkler | Flyvende tekst-feedback (egne ord) |
| **Sigte/target-cirkel** på monsteret, og kameraet er tæt på | Kamera-zoom og et sigte under kampen |
| Monsteret har **sjældenhed, vægt (kg), penge/sek. og sværhedsgrad** (Easy/Medium/Hard) | Monster-stats og en sværhedsgrad ud fra spillerens styrke |
| Efter sejr **følger monsteret spilleren** med en **taleboble**, og **røde pile på jorden** viser vej hjem | Følge-system og guide-pile |
| HUD: menuknapper i siden, stats nederst til venstre (styrke, fart, penge med "+$"), stor **Auto**-knap, hotbar med slagvåben og fælde, **event-timer**, banner med **gratis gave** | Tilsvarende *funktioner*, men vores eget layout og design |
| Spillere kan **stjæle** monstre fra hinanden ude i verden og bruge **fælder** | Tyveri kun ude i verden, plus fælder |

**Antagelser** (kunne ikke ses tydeligt): præcis hvordan fælden og "Evolve" virker, og hvilke lyde der bruges.
Lav dem selv på en fornuftig måde.

---

## 3. KONCEPT OG CORE LOOP

**Pitch:** *"Train your MOG, battle monsters, drag them home, and become the strongest on the server."*

**Core loop (30 sekunder):**
1. Træn **MOG POWER** ved din træningsstation.
2. Gå ud i en **zone**, og vælg et monster, du kan klare (sværhedsgraden står over det).
3. Vind en **MOG BATTLE** (afsnit 6).
4. Monsteret **følger dig hjem**. Andre spillere kan prøve at stoppe dig.
5. Monsteret går rundt i din **indhegning** og tjener **Coins** hvert sekund.
6. Brug Coins, Gems og XP på opgraderinger. Bliv stærkere, og lås nye zoner og bosser op.

**Mellemlang loop (5–30 min):** opgradér hammer og evner, lås næste zone op, fang sjældne niveauer
(Silver → Rainbow Cosmic), fusionér dubletter, og deltag i events (Lucky Rush, Boss Rush).

**Lang loop (timer og dage):** Rebirth, sjældne bosser, Index-samling, leaderboard, daglige streaks og ugentlige quests.

---

## 4. VERDEN, KORT OG ARENAER

**Stil:** Lys, mættet, "blocky men poleret" Roblox-stil. Rene flader, bløde skygger og glade farver.
Brug **Terrain-græs**, `Atmosphere`, `Clouds`, `Bloom`, `ColorCorrection` (mættet) og `SunRays`.
Ingen mørk eller grå stemning, undtagen i boss-arenaer.

**Opbygning:**
- **Hub** (spawn): 8 indhegninger i to rækker. I midten: Fusion Machine, Shop-kiosk, Leaderboard-tavle,
  Daily-gave-podie og Quest-tavle. Mure rundt om hele kortet.
- **MOG ROAD:** en lang, bred vej med glatte, lyse mure og **8 zoner**. Hver zone har sit eget tema, sin egen farve
  og en port, der kræver MOG POWER:

| Zone | Tema | Monster-tier | MOG for at komme ind |
|---|---|---|---|
| 1 Meadow | grøn eng, blomster | Weak | 0 |
| 2 Old Farm | hø, hegn, lade | Normal | 40 |
| 3 Moon Forest | blå nat, svampe | Strong | 200 |
| 4 Haunted Manor | lilla tåge, gravsten | Epic | 1.500 |
| 5 Frost Peaks | is, sne, krystaller | Legendary | 12.000 |
| 6 Lava Rift | sort sten, glødende revner | Mythic | 100.000 |
| 7 Void Gate | stjernehimmel, svævende øer | Secret | 2.000.000 |
| 8 Celestial Throne | guld, skyer, lys | GODLY | 100.000.000 |

- **Boss-arenaer:** For enden af zone 2, 4, 6 og 8 ligger en rund arena med en port, der åbner med en
  nedtælling. Bossen spawner hvert 10. minut (se afsnit 5.3).
- **Indhegning (base):** hvidt hegn, græs, dam, foderkrybbe og en **træningsstation** (MOG Stone)
  ved porten. Monstrene **går frit rundt** derinde. Ingen kan stjæle fra basen.

---

## 5. MONSTRE

### 5.1 Tiers
| Tier | Farve | Typisk MOG-krav | Penge/sek. |
|---|---|---|---|
| Weak | grå | 10 | 2 |
| Normal | grøn | 40 | 6 |
| Strong | blå | 200 | 25 |
| Epic | lilla | 1.500 | 100 |
| Legendary | guld | 12.000 | 600 |
| Mythic | pink | 100.000 | 4.000 |
| Secret | sort | 2.000.000 | 50.000 |
| GODLY | hvid/regnbue | 100.000.000 | 1.000.000 (1 ud af 1.000.000.000 pr. spawn) |

### 5.2 Monster-liste (eksempler, inspireret af myter og sagn, så de er frie at bruge)
Mindst **2 monstre pr. tier** og **mindst 20 i alt**. Hvert monster har en kropstype:
humanoid, firbenet, fugl, slange, spøgelse eller drage. Det har også en farvepalet, en unik detalje (hat, kappe, horn, vinger,
9 haler …) og en kort beskrivelse til Index.
Eksempler: Zombie, Redcap, Leprechaun, El Cadejo, Werewolf, Kelpie, Vampire, Banshee, Troll, Kitsune,
Bigfoot, Mothman, Grootslang, Ancient Dragon, Wendigo, Jörmungandr-hatchling, Golem King, GIGAMOG.

**Variationer på hvert monster:**
- **Niveau:** Normal → Silver (1/10, x1,5) → Golden (1/40, x2) → Diamond (1/250, x4) → Rainbow (1/1.500, x8)
  → Cosmic (1/15.000, x20) → Rainbow Cosmic (1/1.000.000, x100). Niveauet maler hele kroppen og giver partikler.
- **Størrelse:** 0,8–1,3x, og 1 ud af 60 er **HUGE** (1,8x). Vises i **KG**. Indtjening × størrelse^1,5.

### 5.3 Bosser
- 4 bosser (zone 2, 4, 6, 8), f.eks. **Barn Brute**, **Phantom Duke**, **Magma Colossus** og **The First Mog**.
- 3–5x større end almindelige monstre, med eget **boss-HP-bar** øverst og **faser** (66 % og 33 %), hvor
  bossen skifter angreb (chokbølge, der skal hoppes over, minions, raseri-mode).
- Flere spillere kan kæmpe sammen. Belønningen deles efter skade, og der er garanteret Gems og en chance for et **Boss-monster**.

### 5.4 Opførsel og animation
- Monstrene **går** rundt i deres zone: benene går skiftevis, armene svinger, vingerne basker og halerne svajer.
  De drejer blødt, accelererer og holder små pauser.
- Idle-animationer: kigger rundt, sætter sig ned, gaber. Boss-idle: brøl med kameraryst tæt på.
- Over hvert vildt monster: navn, tier, KG, penge/sek. og **sværhedsgrad**
  (EASY/MEDIUM/HARD/TOO STRONG) ud fra *din* MOG.

---

## 6. KAMPSYSTEMET – "MOG BATTLE"

Kampen er spillets kerne. Den skal føles **stærk, hurtig og tilfredsstillende**.

### 6.1 Start
- Tryk **E** på et monster. Kameraet zoomer ind (tween 0,45 sek.) bag spilleren og mod monsteret.
  Der kommer et roterende **sigte** på monsteret, og spilleren og monsteret vender mod hinanden.

### 6.2 To lag i kampen
**A) MOG CLASH (tovtræk):**
- En stor bar nederst: **spillerens avatar** (headshot) til venstre og **monsterets ikon** til højre.
- Klik eller tryk **hvor som helst** (eller tryk mellemrum). Hvert klik skubber baren.
- **Kombo:** klik inden 0,45 sek. giver kombo+1 (vises som "COMBO x24"), op til +100 % kraft.
- Monsteret skubber konstant tilbage (styrke afhænger af tier og forholdet MogReq/MOG).

**B) HEALTH-KAMP (nyt lag, som du ønskede):**
- Monsteret har **HP** (HP-bar over hovedet og i kamp-UI'en). Hvert klik giver **skade** =
  `MOG POWER × hammer-multiplikator × kombo-bonus`.
- **Damage-tal** flyver op fra monsteret (hvide = normal, gule = kritisk ×2 med 10 % chance, røde = kombo-finisher).
- **Impact:** monsteret blinker hvidt (Highlight 0,08 sek.), ryster let og laver en lille partikel-gnist og kameraryst.
- Monsteret **angriber tilbage** hvert 3.–5. sekund. En advarselscirkel vises 1 sek. før, og spilleren kan **undvige**
  med en dodge-knap. Ellers falder en **MOG-meter** (spillerens "HP" i kampen).
- Sejr: monsterets HP = 0 **eller** baren skubbet helt over. Nederlag: MOG-meter = 0 **eller** tiden løber ud (15 sek.).

### 6.3 Evner (låses op med levels)
| Evne | Level | Effekt | Cooldown |
|---|---|---|---|
| Power Stare | 5 | Næste 5 klik giver ×3 skade | 20 s |
| Flex | 12 | Monsteret lammes i 2 s (skubber ikke tilbage) | 30 s |
| Aura Burst | 25 | Stor eksplosion, 15 % af max HP i skade | 45 s |
| Sigma Shield | 40 | Ignorer næste monster-angreb | 40 s |
| Final Mog | 60 | Hvis monsterets HP < 25 %: øjeblikkelig sejr | 90 s |

Evnerne vises som runde knapper med cooldown-animation (radial fill) over hotbaren.

### 6.4 Feedback og "juice"
- Flyvende **hype-ord** ved hvert klik ("LOCKED IN", "+AURA", "GOATED", "BEAST MODE"), med tilfældig farve, vinkel og et pop.
- **Sejr:** slow-motion (0,3 sek.), konfetti, et stort "+1000 AURA", fanfare, og monsteret laver en "bøje sig"-animation.
- **Nederlag:** monsteret laver en drillende animation, og spilleren skubbes lidt tilbage.
- **AUTO MOG**-knap: klikker 4 gange i sekundet (svagere end manuelt) og bruger ikke evner.

### 6.5 Efter kampen
- Vundet monster **følger spilleren** med en taleboble ("Lead the way, chief!"), og **lysende pile** viser vejen hjem.
- Andre spillere kan **slå** (hammer) eller lægge en **fælde**. Så stikker monsteret af og kan tages af andre.
- Belønninger ved sejr: XP, Coins, en lille chance for Gems og **"First Mog"-bonus** første gang man fanger en art (Index).

---

## 7. PROGRESSION OG ØKONOMI

### 7.1 Valutaer
| Valuta | Fås fra | Bruges til |
|---|---|---|
| **Coins** | monstre i indhegningen, sejre, daglig gave | hammer, træningsfart, indhegning, money boost |
| **Gems** | bosser, quests, level-ups, sjældne sejre | auras, evne-opgraderinger, kosmetik, ekstra fælder |
| **XP** | sejre (mere for sværere monstre), træning, quests | levels → nye evner og bonusser |
| **MOG POWER** | træning (hammer × aura × rebirth) | adgang til zoner, kampstyrke |

### 7.2 Levels
- XP til næste level: `100 × level^1,5`. Hvert level giver +2 % skade og Gems (5 × level).
  Hvert 5. level giver en evne eller et nyt kosmetisk item.

### 7.3 Opgraderinger
- **Hammer** (15 levels, MOG pr. slag 1 → 40.000), **Swing Speed** (8 levels, 1 s → 0,15 s),
  **Enclosure** (6 → 20 monstre), **Money Boost** (x1 → x60), **Trap Mastery** (flere og længere fælder),
  **Dodge** (kortere cooldown).
- **Auras** (Gems eller Coins): Spark ×1,25 … Rainbow ×12 MOG.
- **Fusion:** 2 ens monstre på samme niveau giver det næste niveau.
- **Evolve:** 5 af samme art + Gems → en "Elder"-form med nyt udseende og ×3 indtjening.
- **Rebirth:** nulstiller Coins, MOG, monstre og opgraderinger. Giver +1x MOG og penge for altid, plus et rebirth-skilt.
  Rebirth 10 giver et eksklusivt monster.

### 7.4 Balancering (startværdier)
- Hammer-pris: `50 × 3,2^(level−1)`. Swing-pris: `100 × 4^(level−1)`. Rebirth: `1M × 5^rebirths`.
- Mål: zone 2 efter ca. 3 min, zone 3 efter ca. 10 min, zone 5 efter ca. 1 time, zone 7 efter ca. 1 dags spil.

---

## 8. QUESTS, EVENTS OG BELØNNINGER
- **Daglig gave** (blinkende banner, når den er klar). Dag 7 giver et gratis Epic-monster.
- **Daglige quests** (3 pr. dag), f.eks. "Win 10 battles", "Mog a HUGE monster" eller "Train 500 MOG". Belønning: Gems og XP.
- **Lucky Rush** hvert 10. min (3x held og flere monstre), **Boss Rush** hver time og **Weekend 2x XP**.
- **Index:** alle arter og niveauer. Fyldt Index giver titler og bonusser.
- **Leaderboard-tavler:** MOG, Coins og Bosser besejret (OrderedDataStore).

---

## 9. UI / HUD (vores eget design)
**Stil:** afrundede kort, tykke mørke kanter, gradient efter tier, store tydelige tal og FredokaOne-font.
Alt skal skalere (UIScale/UISizeConstraint) og virke på PC, mobil og tablet.

- **Øverst i midten:** Coins (med "+$"-popups) og Gems.
- **Nederst til venstre:** MOG POWER, Level med XP-bar og fart.
- **Højre side:** menuknapper: SHOP, UPGRADES, AURAS, QUESTS, INDEX og REBIRTH.
- **Nederst i midten:** AUTO MOG-knap og en hotbar (Hammer, Trap og evner).
- **Øverst til højre:** event-timer (Lucky Rush/Boss Rush) og server-luck.
- **Kamp-UI:** avatar mod monster-ikon, tovtræk-bar, monster-HP-bar, spillerens MOG-meter, kombo, timer og evneknapper.
- **Menuer:** kort side om side med en roterende 3D-forhåndsvisning (ViewportFrame), et badge ("x5 MOG") og en stor knap.
- **Notifikationer:** toast-beskeder og server-annonceringer for sjældne fangster.

---

## 10. ANIMATIONER, EFFEKTER OG LYD
- Spiller: hammer-sving (Tool.Grip eller Animation), træningsloop, sejrsdans og en skubbe-tilbage-animation.
- Monstre: gang (skiftevise ben), idle, angreb, "bøje sig" ved nederlag, og flyvende/svævende typer.
- Effekter: partikel-burst ved klik, kritiske slag og sejre. Aura-partikler på spilleren. Glød på sjældne niveauer.
  Regnbue-farveskift. Kameraryst og slow-motion ved sejr.
- Lyd (brug Roblox' gratis lydbibliotek): klik-pop, kritisk slag, monsterbrøl, sejrsfanfare, mønt-lyd,
  baggrundsmusik pr. zone og boss-musik.

---

## 11. MULTIPLAYER OG SOCIALT
- 8 spillere pr. server, én indhegning hver.
- Tyveri **kun ude i verden**, når et monster følger nogen. Hammerslag og fælder gør monsteret "loose".
- Bosser kan besejres i fællesskab. Venner kan give "high five" for +5 % XP i 5 min.
- Server-annonceringer for HUGE, Rainbow, Cosmic og GODLY.

---

## 12. MONETIZATION (fair)
- Gamepasses: 2x Coins, 2x MOG, VIP (tag og +20 %), +5 monster-pladser og ekstra fælde-slot.
- Developer products: Server Luck (15 min for alle), Coin Pack og Gem Pack.
- **De sjældneste monstre (Secret og GODLY) og bosserne kan IKKE købes.**

---

## 13. TEKNISK ARKITEKTUR (Roblox Studio)
- **Struktur:**
  - `ServerScriptService/Main` (Script) + ModuleScripts:
    `DataService`, `MonsterService`, `BattleService`, `ZoneService`, `EconomyService`, `QuestService`, `BossService`.
  - `ReplicatedStorage/Shared` (ModuleScripts): `Config` (alle tal og tabeller), `Types` og `Util`.
  - `StarterPlayerScripts/ClientMain` (LocalScript) + moduler: `HUD`, `Menus`, `BattleUI`, `Effects` og `Animator`.
  - `ReplicatedStorage/Remotes`: RemoteEvents og RemoteFunctions med tydelige navne.
- **Server-autoritet:** serveren bestemmer HP, skade, belønninger og ejerskab. Klienten sender kun input
  (klik med tidsstempel). Serveren rate-limiter klik (maks. ca. 20/sek.) og validerer afstand og tid.
- **Data:** DataStore med pcall, retries, auto-save hvert 2. min, gem ved udlogning og BindToClose,
  og versionsnummer i data. Spillet skal virke uden gemning i et ikke-udgivet place.
- **Performance:** animér kun monstre tæt på kameraet (< 200 studs). Højst ca. 80 monstre på serveren.
  Pool effekter. StreamingEnabled er slået til.
- **3D-modeller:** monstre kan bygges af Parts/MeshParts. Understøt en `ServerStorage/MonsterModels`-mappe,
  hvor en model med samme navn som arten erstatter den byggede krop (scripts i modellen fjernes).

---

## 14. LEVERANCER
1. En komplet `.rbxl`/`.rbxlx`-fil, der kan åbnes og spilles med det samme.
2. Alle scripts med **præcis placering** (sti i Explorer) og **hele koden**, ikke uddrag.
3. En kort spillerguide og en udviklerguide (hvordan man tilføjer et nyt monster, en zone eller en evne i `Config`).
4. En liste over antagelser og kendte begrænsninger.

---

## 15. TEST-TJEKLISTE (skal gennemføres)
- [ ] Spillet starter uden røde fejl i Output (også uden DataStore-adgang).
- [ ] Træning giver MOG. Opgraderinger øger den korrekt.
- [ ] Zone-porte blokerer spillere med for lidt MOG.
- [ ] Kamp: kombo, skade-tal, HP-bar, monster-angreb, dodge, evner, sejr og nederlag virker.
- [ ] Monsteret følger spilleren. Pile vises. Hammer og fælde gør det løst. En anden spiller kan tage det.
- [ ] Monstre går rundt i indhegningen og tjener Coins. Ingen kan stjæle fra basen.
- [ ] Boss: faser, fælles kamp og delte belønninger virker.
- [ ] Level-ups, XP-bar, Gems, quests, daglig gave, Index, Fusion, Evolve og Rebirth virker.
- [ ] Alle knapper i alle menuer virker på PC og mobil.
- [ ] Data gemmes og indlæses korrekt efter rejoin.
- [ ] Ingen frame-drops med 8 spillere og ca. 80 monstre.

---

## 16. ACCEPTKRITERIER
Spillet er færdigt, når en ny spiller inden for 10 minutter kan:
træne → vinde sin første kamp → føre monsteret hjem → tjene Coins → købe en opgradering → låse zone 2 op.
Kampen skal føles **kraftfuld** (impact, tal, kombo, lyd). Spilleren skal tydeligt mærke,
at monstre, der før var "TOO STRONG", senere bliver "EASY". Alle systemer i afsnit 3–12 skal virke.
