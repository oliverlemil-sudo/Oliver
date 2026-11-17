# Power Empire – Roblox-spil (overdragelse til Claude)

Ejeren hedder Oliver, taler **dansk** og er nybegynder i Roblox Studio (bruger Mac → Cmd i stedet for Ctrl).
Forklar alt enkelt og trin for trin, på dansk. Teksten **inde i spillet** er på engelsk (større publikum).

## Hvad spillet er
"⚡ POWER EMPIRE – Steal, Build & Become OP". Et "steal"/tycoon-spil Oliver selv har designet:
- 8 baser i en cirkel om en plads i midten. Kræfter (glødende kugler) på piedestaler tjener penge/sek.
- **Power Market** midt på (10 podier, begrænset lager, restock hvert 90. sek; plads 10 kan give Mythic/Secret).
- **Stjæl** fra andres baser (hold E), alarm hos ejeren, løb hjem eller **kast** (F) kraften ind i egen base.
- Forsvar: laser-lås (rød LOCK-plade), turret (3 levels), alarm, **vault** (kan ikke stjæles, overlever rebirth).
- **Power Fusion** station (16 hemmelige opskrifter, 28 kræfter), **mutationer** (Neon/Golden/Corrupted/Rainbow/Galaxy).
- **Rebirth** via knap i højre side (IKKE en station på kortet – Oliver ville have den i siden af skærmen).
- **Battle Arena**: "Power Blast"-tool, bedste kraft bestemmer angreb. Udenfor arenaen kun mod tyve.
- Secret Portal-event, daily rewards, 2x Server Luck, gamepasses + developer products (IDs i CONFIG, 0 = "coming soon").
- Oliver ønsker: Secret-kræfter må IKKE kunne købes direkte for Robux.

## Filer
- `src/ServerScriptService/GameServer.server.lua` → **Script** i ServerScriptService. Bygger hele kortet selv.
- `src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua` → **LocalScript** i StarterPlayer › StarterPlayerScripts.
- `README.md` → dansk guide til Oliver (opsætning, udgivelse, gamepasses).
- `default.project.json` → Rojo (valgfrit).

Kun to scripts – al bygning sker i kode, så Oliver kun skal kopiere/indsætte.

## Status (version 4)
- Når det kører rigtigt, står der i Output:
  `POWER EMPIRE server v4 started OK!` og `POWER EMPIRE client v4 started OK!`
- v1 crashede i Studio fordi `DataStoreService:GetDataStore` kastede fejl i et ikke-udgivet place → ingen figur,
  markedet tomt, timere 0:00. Rettet (pcall). Gemning virker først når spillet er udgivet og
  "Enable Studio Access to API Services" er slået til.
- v3: karakterer spawner via Roblox' auto-load (Players.RespawnTime), REBIRTH er en knap i højre menu.
- v3 er testet i en hjemmelavet Roblox-mock (API-dump-valideret) med 2 spillere: køb, tyveri, kast, blast,
  fusion, rebirth, vault, alle knapper, død/respawn, 12 min spil → 0 fejl. **Endnu IKKE bekræftet i rigtig Roblox Studio.**
- Sidst vi hørte fra Oliver kørte han sandsynligvis stadig den gamle server-version (samme symptomer som v1).

## Næste skridt
1. Sørg for at BEGGE scripts i Studio er den nyeste version fra denne branch (se Output-linjerne ovenfor).
2. Tryk Play, tjek Output for røde fejl, ret dem.
3. Test: gå til markedet, hold E på en kugle ("Buy $100"), se den flyve hjem, penge stiger.
4. Test med 2 spillere: fanen Test → Clients and Servers → 2 Players.
5. Bagefter: polish (flottere kort/baser), flere kræfter, evt. væsner der vogter basen (Oliver nævnte væsner som idé).

## Vigtigt
- Udgivelse, gamepasses og alt med Robux/rigtige penge skal Oliver selv (eller en voksen) godkende.
- Ny Roblox Studio-UI: der er ingen "View"-fane. Explorer = knap øverst til højre. Output = fanen "Script" → "Output".
- Start-spillet-knappen er den blå ▶ øverst til venstre (ikke "Run" nederst, det er kommandolinjen).
- v4: flottere kort (stier fra baser til pladsen, lygtepæle, ~70 træer, Atmosphere/Bloom/ColorCorrection/SunRays),
  partikel-burst + svævende tekst ved køb/tyveri/fusion/portal (RemoteEvent "Effect"),
  5 nye markedskræfter (Sand, Water, Crystal, Light, Time) og 5 nye opskrifter (Glass, Tsunami, Prism, Chrono Dragon, Supernova).
  Testet i mock: 0 fejl. Oliver har pt. ikke adgang til sin Mac – vi arbejder videre herfra.
