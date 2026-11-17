# MOG MONSTERS – Roblox-spil (overdragelse til Claude)

Ejeren hedder Oliver, taler **dansk** og er nybegynder i Roblox Studio (Mac → Cmd i stedet for Ctrl).
Forklar alt enkelt og trin for trin, på dansk. Teksten **inde i spillet** er på engelsk.
Oliver har pt. ikke adgang til sin Mac; vi arbejder fra en cloud-session og sender filer.

## Spillet (nuværende idé – Olivers egen)
"👹 MOG MONSTERS". Erstatter tidligere versioner (Floor is Lava, Egg Heist, Power Empire – ligger i git-historikken).
- **MOG ROAD** (x = 20 → 740) med **8 store zoner** (90 lange, 80 brede, høje murstensmure). Port mellem zoner
  kræver MOG (zone k = RARITIES[k].Mog); for lidt MOG → skubbes tilbage (server-loop).
  Monstre spawner i deres zone (Every/Max i ZONES) og vandrer frit rundt.
- **MOG BATTLE** (minispil) når man trykker E: "Clash" (klik hurtigt / mellemrum) eller "Timing" (stop nålen i
  grøn zone 3 gange). Sværhed afhænger af rarity og MogReq/MOG. Klienten sender resultat (Request "BattleResult");
  serveren kræver ≥ 2 sek. Vinder man, BÆRER man monsteret hjem; andre kan Mog Slap'e én og samle det op ("Grab").
- Oliver bad om "alt fra Steal an Egg" – vi kopierer IKKE andres spil (udseende/navne); vi tog kun zone-idéen.
- 8 **indhegnede baser** (88x76, hegn) i to rækker (x -360..-60, z ±88) ved en hub; Fusion Machine i hub (x -210).
  Monstre **går frit rundt i indhegningen** (ingen piedestaler). Vault = glasbur bagerst, spillere kan ikke komme ind.
- Monstre bygges af klodser med 8 kropstyper (Plan: blob, beast, bird, spider, golem, serpent, ghost, dragon).
  Oliver vil have dem "realistiske": ServerStorage › MonsterModels › <MonsterId> (Model) erstatter klods-kroppen.
  Forhåndsvisning: docs/monsters-preview.png.
- Oliver ville IKKE have hul/graveri (det blev droppet midt i byggeriet). Monstre graver ikke.
- Sjældenheder Common → … → Secret (1/1M) → **GODLY: GIGAMOG 1 ud af 1.000.000.000**.
- Niveauer (variants): Normal, Golden, Diamond, Rainbow, Cosmic, **Rainbow Cosmic** (1/1M, x100).
- Opgraderinger (UPGRADES-menu): Train MOG, Money Boost, flere pladser.
- Beholdt fra Power Empire: stjæl + kast (F), Mog Slap-tool (forsvar), vault, LOCK-plade, alarm,
  Fusion Machine (2 ens samme niveau → næste niveau), Rebirth (knap i højre side, +1x penge og +1x MOG),
  Lucky Rush-event, daily rewards, gamepasses/products (IDs i CONFIG, 0 = "coming soon").
- Oliver ønsker: de sjældneste ting må IKKE kunne købes for Robux.

## Filer
- `src/ServerScriptService/GameServer.server.lua` → **Script** i ServerScriptService. Bygger hele kortet.
- `src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua` → **LocalScript** i StarterPlayerScripts.
- `MogMonsters.rbxlx` → færdig place-fil med begge scripts (genereres ud fra de to filer).
  Opdatér den hver gang scripts ændres (se nedenfor).
- `README.md` → dansk guide til Oliver.

## Status
- Output ved start: `MOG MONSTERS server v3 started OK!` / `MOG MONSTERS client v3 started OK!`
- Testet i hjemmelavet Roblox-mock (API-dump-valideret, 2 spillere, ~13 min spil, med/uden DataStore) → 0 fejl.
  **Endnu ikke testet i rigtig Roblox Studio.**
- Kendte Studio-faldgruber vi allerede har løst: GetDataStore i pcall (ikke-udgivet place), ZIndexBehavior Sibling,
  karakterer via auto-load.

## Regenerér .rbxlx
Skriv en XML-place (`<roblox version="4">`) med ServerScriptService › Script "GameServer" og
ServerStorage › Folder "MonsterModels" (tom) og StarterPlayer › StarterPlayerScripts › LocalScript "GameClient", Source i `<ProtectedString name="Source"><![CDATA[...]]>`.

## Vigtigt
- Udgivelse, gamepasses og alt med Robux/rigtige penge skal Oliver selv (eller en voksen) godkende.
- Ny Roblox Studio-UI: ingen "View"-fane. Explorer = knap øverst til højre. Output = fanen "Script" → "Output".
- Start-knappen er den blå ▶ øverst til venstre (ikke "Run" nederst).
