# 🥚 Egg Heist: Throw & Steal

Et helt nyt Roblox-spil, der blander **stjæle**, **kaste** og **superkræfter**.
Scriptet bygger selv hele banen, så du ikke skal bygge noget i hånden.

## Sådan spiller man

1. **Køb æg** på **Egg Road** (transportbåndet i midten). Hold **E** på et æg.
2. Æggene flyver hjem til din **base** og giver **penge hvert sekund**.
3. **Stjæl æg** fra andres baser (hold **E** på deres æg). Ægget ligger nu på dit hoved.
4. **Det nye:** Tryk **F** for at **KASTE** ægget. Lander det i din base, er det dit!
   Lander det et andet sted, kan alle samle det op.
5. **Bonk Bat:** Slå en tyv, så taber de ægget. Ejeren kan samle det op og få det tilbage.
6. **Lås din base:** Stå på den røde **LOCK**-plade. Så bliver tyve smidt ud i 45 sekunder.
7. Når et æg **klækker**, giver det **dobbelt så mange penge**. Specielle æg giver en **SUPERKRAFT**:

| Æg | Sjældenhed | Superkraft |
|---|---|---|
| Zap Egg | Rare | ⚡ Super Speed: løb hurtigere |
| Bouncy Egg | Rare | 🦘 Mega Jump: hop højere |
| Muscle Egg | Epic | 💪 Strong Arm: kast meget længere |
| Phantom Egg | Legendary | 👻 Ghost: gå ind i låste baser |
| Titan Egg | Legendary | 🛡️ Iron Grip: du kan ikke blive slået, så du taber ægget |
| Cosmic Egg | **Mythic** | 💰 Kæmpe indtjening |

Der er 10 slags æg i 5 sjældenheder: Common, Rare, Epic, Legendary og Mythic.

## Sådan tjener du Robux

| Ting | Type | Forslag til pris |
|---|---|---|
| **VIP**: +3 ekstra æg-pladser og VIP-skilt | Game Pass | 249 R$ |
| **2x Cash**: dobbelt penge for altid | Game Pass | 199 R$ |
| **Lucky Egg**: få et Legendary- eller Mythic-æg | Developer Product | 99 R$ |
| **Super Lock**: lås basen i 3 minutter | Developer Product | 29 R$ |
| **+25K Cash** | Developer Product | 49 R$ |

**Lucky Egg** bliver annonceret for hele serveren, så de andre spillere kan se det, og det får dem til at ville have et.

---

## Trin 1: Sæt spillet ind i Roblox Studio

1. Åbn **Roblox Studio** → **New** → vælg **Baseplate**.
2. Find **ServerScriptService** i **Explorer** (fanen **View** → **Explorer**, hvis du ikke kan se den).
3. Hold musen over **ServerScriptService** → klik **+** → vælg **Script**.
4. Slet alt i det, og kopiér **hele** indholdet af
   [`src/ServerScriptService/GameServer.server.lua`](src/ServerScriptService/GameServer.server.lua) ind.
5. Åbn **StarterPlayer** → hold musen over **StarterPlayerScripts** → **+** → **LocalScript**.
6. Slet alt i det, og kopiér hele indholdet af
   [`src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua`](src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua) ind.
7. Tryk **Play**. Banen bygges automatisk! 🎉

> ⚠️ Det første skal være et **Script**, og det andet skal være et **LocalScript**.

### Test med flere spillere (for at prøve at stjæle)
Fanen **Test** → vælg **2 Players** under *Clients and Servers* → klik **Start**.
Så får du to vinduer og kan stjæle fra dig selv.

## Trin 2: Udgiv

1. **File** → **Publish to Roblox**.
2. **Game Settings** → **Security** → slå **Enable Studio Access to API Services** til, så spillet gemmer.
3. **Game Settings** → **Places**: sæt **Max Players** til **8**, for der er 8 baser.
4. På https://create.roblox.com: sæt spillet til **Public**.

## Trin 3: Opret Game Passes og Products

1. https://create.roblox.com → dit spil → **Monetization**.
2. Opret 2 **Passes**: VIP og 2x Cash.
3. Opret 3 **Developer Products**: Lucky Egg, Super Lock og 25K Cash.
4. Kopiér hvert **ID** ind i toppen af `GameServer` under **CONFIG**:

```lua
VIP_PASS_ID = 123456789,
DOUBLE_CASH_PASS_ID = 123456789,
LUCKY_EGG_PRODUCT_ID = 123456789,
SUPER_LOCK_PRODUCT_ID = 123456789,
CASH_PACK_PRODUCT_ID = 123456789,
```

5. Publish igen. Indtil et ID er sat, viser knappen bare "Coming soon!".

## Nemme ting at ændre (i CONFIG og EGGS)

- `EGGS`: tilføj nye æg med navn, pris, indtjening, farve og superkraft.
- `EGG_SPAWN_EVERY`, `ROAD_SPEED`: hvor tit og hvor hurtigt æggene kommer.
- `LOCK_TIME`, `THROW_POWER`, `START_CASH` osv.

## Få spillere

- Lav et sjovt **ikon** og **thumbnails**, f.eks. en figur der kaster et glødende æg.
- Opdatér tit med nye æg og superkræfter. "UPDATE 🥚 NEW MYTHIC EGG" i titlen virker godt.
- Få venner til at spille og trykke 👍.

## Rigtige penge
Robux kan veksles via **DevEx**. Du skal være mindst 13 år og have mindst 30.000 tjente Robux.
Hvis du er under 18, så tag en voksen med.
