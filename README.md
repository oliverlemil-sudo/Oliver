# 🔥 Floor is Lava Obby

Et færdigt Roblox-spil, som du kan sætte ind i Roblox Studio på 5 minutter.
Scriptet **bygger selv hele banen**, så du ikke skal bygge noget i hånden.

## Hvad er der i spillet?

- **30 stages** med 6 slags forhindringer: hop, lava-striber, forsvindende glasplader,
  roterende lava-stang, line-gang og klatring op ad et tårn
- Bliver **sværere og sværere** jo længere man kommer
- **Checkpoints**, så man starter ved sidste checkpoint, når man dør
- **Mønter**, man samler op og får for at nå nye stages
- **Shop** med trails (farvede spor efter spilleren), som købes for mønter
- **Gemmer** spillerens stage, mønter og trails
- **Leaderboard** (Stage, Coins, Wins)
- **Tjen Robux**:
  - Game Pass **VIP**: 2x mønter + eksklusivt Rainbow-trail
  - Game Pass **Speed**: løb hurtigere
  - Developer Product **Skip Stage**: spring en stage over (kan købes igen og igen)
  - Developer Product **+500 Coins**

Teksten i spillet er på engelsk, fordi de fleste Roblox-spillere taler engelsk.
Så kan flere spille det, og du kan tjene flere penge.

---

## Trin 1: Sæt spillet ind i Roblox Studio

1. Hent **Roblox Studio** på https://create.roblox.com og log ind.
2. Klik **New** → vælg **Baseplate**.
3. Find **ServerScriptService** i vinduet **Explorer** til højre.
   (Kan du ikke se Explorer? Gå til fanen **View** → klik **Explorer**.)
4. Hold musen over **ServerScriptService** → klik **+** → vælg **Script**.
5. Slet alt i det nye script, og kopiér **hele** indholdet af
   [`src/ServerScriptService/GameServer.server.lua`](src/ServerScriptService/GameServer.server.lua) ind.
6. Åbn **StarterPlayer** i Explorer → hold musen over **StarterPlayerScripts** → **+** → vælg **LocalScript**.
7. Slet alt i det, og kopiér hele indholdet af
   [`src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua`](src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua) ind.
8. Tryk **Play** (den blå knap øverst). Banen bygges automatisk! 🎉

> ⚠️ Vigtigt: Det første script skal være et **Script** (ikke LocalScript),
> og det andet skal være et **LocalScript**. Ellers virker det ikke.

## Trin 2: Udgiv spillet

1. **File** → **Publish to Roblox** → giv det et navn, f.eks. *Floor is Lava Obby*.
2. Gå til **Home** → **Game Settings** → **Security** → slå
   **Enable Studio Access to API Services** til. Så virker det også at gemme i Studio.
3. Gå til https://create.roblox.com → **Creations** → dit spil → sæt det til **Public**.

## Trin 3: Tjen penge (Game Passes og Products)

1. Gå til https://create.roblox.com → dit spil → **Monetization**.
2. Under **Passes**: opret to passes:
   - **VIP** (forslag: 199 Robux)
   - **Speed** (forslag: 99 Robux)
3. Under **Developer Products**: opret to produkter:
   - **Skip Stage** (forslag: 25 Robux)
   - **500 Coins** (forslag: 49 Robux)
4. Hvert pass og produkt har et **ID** (et langt tal). Kopiér dem ind i toppen af
   `GameServer`-scriptet under **CONFIG**:

```lua
VIP_PASS_ID = 123456789,
SPEED_PASS_ID = 123456789,
SKIP_STAGE_PRODUCT_ID = 123456789,
COINS_PRODUCT_ID = 123456789,
```

5. Publish igen (**File → Publish to Roblox**). Færdig!

Så længe et ID er `0`, viser knappen bare "Coming soon!", så spillet virker fint uden dem.

## Ting du nemt kan ændre (i CONFIG)

| Indstilling | Hvad den gør |
|---|---|
| `TOTAL_STAGES` | Antal stages (prøv 50!) |
| `SEED` | Skift tallet for at få en helt ny bane |
| `COIN_VALUE`, `STAGE_BONUS`, `FINISH_BONUS` | Hvor mange mønter man får |
| `TRAILS` | Tilføj nye trails med navn, pris og farver |

## Få spillere til spillet

- Lav et flot **ikon** og **thumbnails** (billeder af spillet). Det er det første, folk ser.
- Få venner til at spille det og give **likes**.
- Senere kan du bruge Robux på **annoncer** (Ads Manager på create.roblox.com).
- Opdatér spillet tit med nye stages og trails. Så kommer spillerne tilbage.

## Om at få rigtige penge

Robux kan veksles til rigtige penge med **DevEx**. Du skal være mindst 13 år
og have tjent mindst 30.000 Robux. Hvis du er under 18, så tag en voksen med på den del.

---

### For viderekomne: Rojo
Projektet har en `default.project.json`, så det kan synkes ind i Studio med
[Rojo](https://rojo.space), hvis du på et tidspunkt vil bruge VS Code.
