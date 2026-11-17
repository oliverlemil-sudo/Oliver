# ⚡ POWER EMPIRE: Steal, Build & Become OP

Et Roblox-spil, hvor du bygger dit eget **Power Empire**. Du køber, **stjæler**, **kaster**
og **fusionerer** superkræfter, og du bliver hele tiden stærkere end dine venner.

Scriptet bygger selv hele kortet: 8 baser i en cirkel og et fælles område i midten.

---

## 🎮 Det er i spillet

### 🏠 Din base
- Du starter med **6 pladser** til kræfter og kan købe op til 12 for penge (+3 med gamepass).
- Hver kraft står på sin egen plads og **tjener penge hvert sekund**.
- **Vault** bagerst i basen: Kræfter i vaulten **kan aldrig blive stjålet** og **beholdes ved rebirth**.
  Du flytter en kraft ind eller ud ved at holde **E** på den.

### 🛒 Power Market (midt på kortet)
- **Begrænset lager:** 10 kræfter ad gangen. Der kommer nye **hvert 90. sekund**.
- Lageret består af 5 billige, 3 mellem, 1 Epic/Legendary og **1 speciel plads**, hvor der kan komme **Mythic** eller **Secret**.
- Køber en anden spiller den sjældne kraft først, må du vente til næste gang. Det giver konkurrence!

### 🦹 Stjæl fra dine venner
- Gå ind i en andens base og hold **E** på en kraft. Jo sjældnere den er, desto længere tager det.
- **Alarmen** går i gang: Ejerens skærm blinker rødt, og der kommer rødt lys i basen.
- Løb hjem med kraften, eller **KAST den ind i din base (F)**. Det er vores egen mekanik!

### 🛡️ Forsvar
| Forsvar | Hvad det gør |
|---|---|
| **Laser-lås** | Stå på den røde LOCK-plade. Tyve bliver smidt ud i 45 sekunder |
| **Turret** (3 levels) | Skyder automatisk på tyve, så de taber kraften |
| **Alarm** | Advarer dig, når nogen stjæler |
| **Vault** | Dine bedste kræfter er 100 % sikre |
| **Power Blast** | Skyd tyven, så de taber kraften |

### 🧪 Power Fusion (unik funktion)
Kombinér 2 kræfter ved **Fusion Station** og få en ny og stærkere kraft.
**16 hemmelige opskrifter** skal spillerne selv finde frem til. De bliver gemt i **INDEX**.

| Opskrift | Resultat |
|---|---|
| Fire + Lightning | Plasma |
| Ice + Shadow | Frozen Darkness |
| Dragon + Lightning | Thunder Dragon |
| …og 13 hemmelige mere | (spoilers 🤫) |

Kombinerer man to kræfter, der ikke er en opskrift, får man en tilfældig kraft, og nogle gange er den en sjældenhed højere.

### ✨ Mutationer
| Mutation | Indtjening |
|---|---|
| Neon | x1.5 |
| Golden | x2 |
| Corrupted | x3 |
| Rainbow (skifter farve) | x5 |
| Galaxy | x10 |

En **Rainbow Thunder Dragon** er altså *ekstremt* sjælden og værdifuld.

### 🔄 Rebirth
| Rebirth | Bonus |
|---|---|
| Hver gang | +1x penge (Rebirth 1 = 2x, Rebirth 2 = 3x …) |
| 2 og 5 | +1 vault-plads |
| 3+ | Løb hurtigere |
| 10 | Eksklusiv **Golden Phoenix**-kraft |

Ved rebirth mister du penge og kræfterne udenfor vaulten. Vault-kræfter, turret og opskrifter beholder du.

### ⚔️ Battle Arena
Udstyr **Power Blast** og kæmp. Din **bedste kraft bestemmer dit angreb**:
- Fire: ildkugler
- Ice: fryser modstanderen
- Lightning: hurtige skud
- Shadow: du bliver usynlig
- Gravity: trækker modstanderen hen til dig
- Dragon: et kæmpe angreb

Når du vinder en kamp, får du penge. Du **mister aldrig kræfter** i arenaen.
Udenfor arenaen virker angrebet kun mod tyve, så man ikke kan genere folk tilfældigt.

### 🌀 Events og belønninger
- **Secret Portal:** Åbner hvert 10. minut i 60 sekunder og giver en gratis kraft med ekstra held.
- **Daily Rewards:** Bonussen bliver større for hver dag i træk, du logger ind. **Dag 7 giver en gratis Epic-kraft eller bedre.**
- **Beskeder til hele serveren**, når nogen stjæler, finder eller laver noget sjældent. Det er her, man kan drille sine venner!

### 💎 Sjældenheder (28 kræfter)
Common → Uncommon → Rare → Epic → Legendary → Mythic → **Secret**

---

## 💰 Sådan tjener spillet Robux

| Gamepass | Forslag |
|---|---|
| 2x Money | 249 R$ |
| VIP (tag, +20 % penge, 2x daily) | 399 R$ |
| +3 Extra Pedestals | 149 R$ |
| Fast Stealing | 199 R$ |
| +1 Vault Slot | 99 R$ |

| Developer Product | Forslag |
|---|---|
| 2x **Server Luck** i 15 min (for alle på serveren!) | 99 R$ |
| Super Lock (3 min) | 29 R$ |
| Cash Pack (10 min indtjening) | 49 R$ |

Som du ønskede, kan **Secret-kræfter ikke købes direkte**. Man finder dem kun ved at spille.
Server Luck er god at sælge, fordi alle på serveren får glæde af den, og alle kan se, hvem der købte den.

---

## 🛠️ Trin 1: Sæt spillet ind i Roblox Studio

1. Åbn **Roblox Studio** → **New** → **Baseplate**.
2. I **Explorer**: hold musen over **ServerScriptService** → **+** → **Script**.
3. Slet alt i det, og kopiér hele indholdet af
   [`src/ServerScriptService/GameServer.server.lua`](src/ServerScriptService/GameServer.server.lua) ind.
4. Åbn **StarterPlayer** → hold musen over **StarterPlayerScripts** → **+** → **LocalScript**.
5. Slet alt i det, og kopiér hele indholdet af
   [`src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua`](src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua) ind.
6. Tryk **Play** 🎉

> ⚠️ Det første skal være et **Script**, og det andet skal være et **LocalScript**.

**Test stjæling:** Fanen **Test** → *Clients and Servers* → **2 Players** → **Start**.

**Tip til test:** Sæt `START_CASH = 1000000` i CONFIG, så du kan prøve alt med det samme.
Husk at sætte den tilbage til `150`, før du udgiver.

## 🚀 Trin 2: Udgiv

1. **File → Publish to Roblox**.
2. **Game Settings → Security**: slå **Enable Studio Access to API Services** til, så spillet gemmer.
3. **Game Settings → Places**: sæt **Max Players = 8**, for der er 8 baser.
4. Sæt spillet til **Public** på https://create.roblox.com.

## 💳 Trin 3: Gamepasses og Products

1. https://create.roblox.com → dit spil → **Monetization**.
2. Opret 5 **Passes** og 3 **Developer Products** (se tabellerne ovenfor).
3. Kopiér hvert **ID** ind i toppen af `GameServer` under **CONFIG**, f.eks. `DOUBLE_MONEY_PASS_ID = 123456789,`
4. Publish igen. Indtil et ID er sat, viser knappen "Coming soon!".

## ✏️ Nemt at ændre
- **`POWERS`**: tilføj nye kræfter (navn, pris, indtjening, farve, angreb).
- **`RECIPES`**: tilføj nye hemmelige fusioner.
- **`MUTATIONS`**: chancer og gangefaktorer.
- **`CONFIG`**: restock-tid, priser, lås-tid osv.

## 📈 Idéer til opdateringer (hold spillerne tilbage)
- Nye kræfter og opskrifter hver uge ("UPDATE 2 ⚡ NEW SECRET POWER")
- **Væsner**, der vogter basen, og fælder
- Weekend-events med 2x luck
- Leaderboard over de rigeste spillere i hele spillet
