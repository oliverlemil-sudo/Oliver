# MOG MONSTERS – Roblox-spil (overdragelse til Claude)

Ejeren hedder Oliver, taler **dansk** og er nybegynder i Roblox Studio (Mac → Cmd i stedet for Ctrl).
Forklar alt enkelt og trin for trin, på dansk. Teksten **inde i spillet** er på engelsk.
Oliver har pt. ikke adgang til sin Mac; vi arbejder fra en cloud-session og sender en færdig `.rbxlx`-fil.

## Spillet (Olivers egen idé, v4)
"👹 MOG MONSTERS". Tidligere versioner (Floor is Lava, Egg Heist, Power Empire) ligger i git-historikken.
- **MOG** er en stat man **træner**: MOG STONE ved hver base (prompt "Train") → hammeren slår automatisk.
  MOG pr. slag = HAMMERS[level].Power × aura × (1+rebirths) × 2x-pass. Slag-interval = SWINGS[level].Time.
- **AURAS** (købes for cash) ganger MOG-træning; vises som partikler på figuren.
- **MOG ROAD** (x 30 → 1150): 8 zoner à 140×110 med glatte lyse mure (ingen fakler/pynt – Oliver ville have rene mure).
  Port kræver RARITIES[k].Mog; for lidt MOG → skubbes tilbage.
- **MOG BATTLE** minispil (Clash = klik, Timing = stop nål) → vinder bærer monsteret hjem.
  Andre kan slå bæreren med **Hammer**-tool (Activated) → monster bliver "Loose" → kan samles op ("Grab").
- **INGEN tyveri fra baser** (Oliver: kun ude ved den lange gang). Ingen vault/lås længere.
- 8 indhegninger (96×80, hvidt hegn) i to rækker ved en hub; monstre går frit rundt. "Bigger enclosure" = flere pladser.
- Mure rundt om hele kortet, ingen træer, lyse farver (Lighting lysere, ColorCorrection mættet).
- **Leaderboard**-tavle i hub (x ≈ -486): OrderedDataStore "MogLeaderboard_v1" hvis muligt, ellers server-top.
- Niveauer: Normal, **Silver**, Golden, Diamond, Rainbow, Cosmic, Rainbow Cosmic. GIGAMOG 1/1.000.000.000.
- Monstre bygges af ellipsoider (SpecialMesh Sphere), cylindre og kugler med 8 kropstyper (Plan).
  Oliver vil have dem "realistiske" → ServerStorage › MonsterModels › <MonsterId> (Model) erstatter kroppen.
  Billeder kan ikke laves om til 3D-modeller af os; brug Toolbox-modeller. Forhåndsvisning: docs/monsters-preview.png.
- Oliver ønsker: de sjældneste ting må IKKE kunne købes for Robux.

## Filer
- `src/ServerScriptService/GameServer.server.lua` → **Script** i ServerScriptService. Bygger hele kortet.
- `src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua` → **LocalScript** i StarterPlayerScripts.
- `MogMonsters.rbxlx` → færdig place-fil (begge scripts + tom ServerStorage › MonsterModels). Regenerér ved ændringer.
- `README.md` → dansk guide til Oliver.

## Status
- Output: `MOG MONSTERS server v4 started OK!` / `MOG MONSTERS client v4 started OK!`
- Testet i hjemmelavet Roblox-mock (API-dump-valideret; 2 spillere; træning, kamp, bære, hammerslag, auras,
  leaderboard, fusion, alle knapper; med/uden DataStore) → 0 fejl. **Endnu ikke testet i rigtig Roblox Studio.**
- Kendte Studio-faldgruber vi har løst: GetDataStore i pcall, ZIndexBehavior Sibling, karakterer via auto-load.

## Vigtigt
- Udgivelse, gamepasses og alt med Robux/rigtige penge skal Oliver selv (eller en voksen) godkende.
- Ny Roblox Studio-UI: ingen "View"-fane. Explorer = knap øverst til højre. Output = fanen "Script" → "Output".
- Start-knappen er den blå ▶ øverst til venstre (ikke "Run" nederst).
