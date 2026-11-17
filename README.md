# 👹 MOG MONSTERS

Et Roblox-spil med en lang **MOG ROAD** delt op i **8 zoner**. Hver zone kræver mere **MOG**,
og jo længere ud du kommer, desto sjældnere monstre finder du. **Mog** dem, så løber de hjem
til din base og tjener penge til dig.
Scriptet bygger selv hele kortet.

## 🎮 Sådan spilles det
1. **MOG ROAD:** Gå fra din base ud ad vejen. Den har 8 zoner med en port mellem hver.
2. **Portene:** Zone 1 er åben. De næste kræver mere MOG (zone 2: 40, zone 3: 200 … zone 8: 100M).
   Har du for lidt MOG, bliver du skubbet tilbage.
3. Monstrene går rundt i deres zone. Over hvert monster står, hvor meget **MOG** det kræver.
   **Grøn** betyder, at du kan mogge det. **Rød** betyder, at du skal træne mere MOG.
4. **Hold E** på monsteret (**"MOG IT!"**). Så flyver det hjem til din **indhegnede base**.
5. Monstrene i din base **tjener penge hvert sekund**.
6. Brug pengene i **UPGRADES**:
   - **Train MOG**, så du kan komme ind i nye zoner og mogge sjældnere monstre
   - **Money Boost**, så monstrene tjener mere
   - **Flere pladser** til monstre

## 🎲 Sjældenheder
| Zone | Sjældenhed | MOG for at komme ind | Penge/sek |
|---|---|---|---|
| 1 | Common | 0 | $2 |
| 2 | Uncommon | 40 | $6 |
| 3 | Rare | 200 | $25 |
| 4 | Epic | 1.500 | $100 |
| 5 | Legendary | 12.000 | $600 |
| 6 | Mythic | 100.000 | $4.000 |
| 7 | Secret | 2.000.000 | $50.000 |
| 8 | **GODLY: GIGAMOG**, chance **1 ud af 1.000.000.000** | 100.000.000 | $1.000.000 |

Jo længere ude zonen er, desto færre monstre er der ad gangen, og desto længere tid går der mellem nye.

## ✨ Niveauer
| Niveau | Chance | Bonus |
|---|---|---|
| Normal | | x1 |
| Golden | 1 ud af 25 | x2 |
| Diamond | 1 ud af 150 | x4 |
| Rainbow (skifter farve) | 1 ud af 1.000 | x8 |
| Cosmic | 1 ud af 10.000 | x20 |
| **Rainbow Cosmic** | **1 ud af 1.000.000** | **x100** |

Et højere niveau kræver også mere MOG for at blive mogget.
En **Rainbow Cosmic GIGAMOG** er 1 ud af en million milliarder. 😱

**Fusion Machine:** 2 ens monstre på samme niveau bliver til det næste niveau,
f.eks. 2 Blobby = Golden Blobby.

## 🦹 Stjæl og forsvar
- Gå ind i andres baser, og hold **E** for at **stjæle**. Ejeren får en alarm.
- Løb hjem, eller **kast monsteret ind i din base (F)**.
- **Mog Slap** (dit værktøj): Slå tyve, så de taber monsteret.
- **Vault:** Monstre i vaulten kan aldrig stjæles og beholdes ved rebirth.
- **LOCK-pladen:** Låser basen i 45 sekunder.

## 🔄 Rebirth (knap i højre side)
Hver rebirth giver **+1x penge OG +1x MOG**. Rebirth 2 og 5 giver flere vault-pladser,
rebirth 3+ gør dig hurtigere, og rebirth 10 giver en eksklusiv **Golden Phoenixmog**.

## 🌀 Events
- **Lucky Rush** hvert 10. minut: 3x held og monstre kommer 3x hurtigere i alle zoner i 60 sekunder.
- **Daily Reward**: Dag 7 giver et gratis Epic- eller Legendary-monster.
- Hele serveren får besked, når nogen mogger eller stjæler noget sjældent.

## 💰 Robux
| Gamepass | Forslag |
|---|---|
| 2x Money | 249 R$ |
| VIP | 399 R$ |
| +3 Monster Spots | 149 R$ |
| Fast Stealing | 199 R$ |
| +1 Vault Spot | 99 R$ |

| Developer Product | Forslag |
|---|---|
| 2x Server Luck (15 min, alle på serveren) | 99 R$ |
| Super Lock (3 min) | 29 R$ |
| Cash Pack | 49 R$ |

De sjældneste monstre kan **ikke** købes for Robux. Dem skal man selv mogge.

---

## 🛠️ Sådan starter du det (nemmest)
1. Download **`MogMonsters.rbxlx`**. Det er spilfilen med begge scripts i.
2. Åbn **Roblox Studio** → **File** → **Open from File…** → vælg filen.
3. Tryk på den blå **▶**.

I **Output** (fanen **Script** → **Output**) skal der stå:
```
MOG MONSTERS server v2 started OK!
MOG MONSTERS client v2 started OK!
```

### Eller sæt scripts ind selv
- `src/ServerScriptService/GameServer.server.lua` → **Script** i **ServerScriptService**
- `src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua` → **LocalScript** i **StarterPlayer › StarterPlayerScripts**

**Test tyveri:** Fanen **Test** → *Clients and Servers* → **2 Players** → **Start**.
**Tip:** Sæt `START_CASH = 1000000` i CONFIG for at teste hurtigt. Sæt den tilbage til `0`, før du udgiver.

## 🚀 Udgiv
1. **File → Publish to Roblox**.
2. **Game Settings → Security** → slå **Enable Studio Access to API Services** til, så spillet gemmer.
3. **Max Players = 8**, for der er 8 baser.
4. Opret gamepasses og products på **create.roblox.com → Monetization**, og sæt deres ID'er ind i **CONFIG**.
