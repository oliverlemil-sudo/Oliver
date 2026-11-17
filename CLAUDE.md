# MOG MONSTERS – Roblox-spil (overdragelse til Claude)

Ejeren hedder Oliver, taler **dansk** og er nybegynder i Roblox Studio (Mac → Cmd i stedet for Ctrl).
Forklar alt enkelt og trin for trin, på dansk. Teksten **inde i spillet** er på engelsk.
Oliver har pt. ikke adgang til sin Mac; vi arbejder fra en cloud-session og sender filer.

## Spillet (nuværende idé – Olivers egen)
"👹 MOG MONSTERS". Erstatter tidligere versioner (Floor is Lava, Egg Heist, Power Empire – ligger i git-historikken).
- **MOG ROAD** (x = 0 → 440) med **8 zoner** (én pr. sjældenhed, 55 studs lange). Port mellem zoner kræver MOG
  (zone k kræver RARITIES[k].Mog); spillere med for lidt MOG skubbes tilbage (server-loop).
  Monstre spawner i deres zone (Every/Max i ZONES) og vandrer rundt. Hold E ("MOG IT!") hvis MOG ≥ krav.
  GIGAMOG: 1/1.000.000.000 chance pr. spawn → zone 8.
- Oliver bad om "alt fra Steal an Egg" – vi kopierer IKKE andres spil (udseende/navne); vi tog kun zone-idéen.
- 8 **indhegnede baser** (hegn) i to rækker (x -300..-60, z ±88) ved en hub; Fusion Machine i hub (x -170).
  Monstre står på pladser og **tjener penge/sek**.
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
- Output ved start: `MOG MONSTERS server v2 started OK!` / `MOG MONSTERS client v2 started OK!`
- Testet i hjemmelavet Roblox-mock (API-dump-valideret, 2 spillere, ~13 min spil, med/uden DataStore) → 0 fejl.
  **Endnu ikke testet i rigtig Roblox Studio.**
- Kendte Studio-faldgruber vi allerede har løst: GetDataStore i pcall (ikke-udgivet place), ZIndexBehavior Sibling,
  karakterer via auto-load.

## Regenerér .rbxlx
Skriv en XML-place (`<roblox version="4">`) med ServerScriptService › Script "GameServer" og
StarterPlayer › StarterPlayerScripts › LocalScript "GameClient", Source i `<ProtectedString name="Source"><![CDATA[...]]>`.

## Vigtigt
- Udgivelse, gamepasses og alt med Robux/rigtige penge skal Oliver selv (eller en voksen) godkende.
- Ny Roblox Studio-UI: ingen "View"-fane. Explorer = knap øverst til højre. Output = fanen "Script" → "Output".
- Start-knappen er den blå ▶ øverst til venstre (ikke "Run" nederst).
