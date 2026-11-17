# 👹 MOG MONSTERS

Et Roblox-spil med en lang **MOG ROAD**, der er delt op i **8 store zoner med mure**. Hver zone kræver
mere **MOG**, og jo længere ud du kommer, desto sjældnere monstre er der.
Slå monstrene i en **MOG BATTLE**, **bær dem hjem**, før nogen slår dem ud af hånden på dig,
og lad dem gå frit rundt i din indhegning, hvor de tjener penge.

![Monstrene](docs/monsters-preview.png)

## 🎮 Sådan spilles det
1. **MOG ROAD:** Gå fra din base ud ad vejen. Den har 8 zoner med høje mure og en port mellem hver zone.
2. **Portene:** Zone 1 er åben. De næste kræver mere MOG (zone 2: 40, zone 3: 200 … zone 8: 100M).
   Har du for lidt MOG, bliver du skubbet tilbage.
3. Over hvert monster står, hvor meget MOG det kræver. **Grøn** betyder, at du kan prøve. **Rød** betyder, at du skal træne mere.
4. Tryk **E** (**"MOG BATTLE!"**), og et **minispil** starter. Det er et af to:
   - **CLICK!** Klik hurtigt (eller tryk **mellemrum**) for at skubbe baren helt over til højre.
   - **STOP!** Stop nålen i den **grønne zone** 3 gange. Du må misse 2 gange.
   Jo sjældnere monsteret er, og jo tættere din MOG er på dets MOG, desto sværere bliver det.
5. **Vinder du, bærer du monsteret over hovedet** og skal nå hjem til din base.
   Andre spillere kan **slå dig med Mog Slap**, så du taber det, og så kan de **samle det op**!
6. Hjemme går monstrene **frit rundt i din indhegning** og tjener penge hvert sekund.
7. Brug pengene i **UPGRADES**: Train MOG, Money Boost og plads til flere monstre.

## 👹 Monstrene
Hvert monster har sin egen krop:

| Zone | Sjældenhed | Monstre | Penge/sek |
|---|---|---|---|
| 1 | Common | Blobby (slim), Pebblo (stengolem) | $2 |
| 2 | Uncommon | Zappit (fugl), Mudmaw (dyr) | $6 |
| 3 | Rare | Frostfang (ulv), Emberclaw (edderkop) | $25 |
| 4 | Epic | Shadowgloom (spøgelse), Crystalix (krystalgolem) | $100 |
| 5 | Legendary | Thunderhorn (horndyr), Magmaroth (lavagolem) | $600 |
| 6 | Mythic | Voidwyrm (slange), Solaris (solfugl) | $4.000 |
| 7 | Secret | Celestion (drage), Glitchling (neon-edderkop) | $50.000 |
| 8 | **GODLY** | **GIGAMOG** (kæmpedrage), chance **1 ud af 1.000.000.000** | $1.000.000 |

### 🎨 Gør monstrene realistiske med rigtige 3D-modeller
Kode kan kun bygge monstrene af klodser. Vil du have rigtige 3D-modeller, gør du sådan her:
1. I Roblox Studio: **Explorer** → **ServerStorage** → mappen **MonsterModels** (den er der allerede i spilfilen).
2. Find en model i **Toolbox**, f.eks. ved at søge på "wolf".
3. Træk modellen ind i **MonsterModels**, og **omdøb** den til monsterets navn, f.eks. `Frostfang`.
4. Tryk ▶. Nu bruger spillet din model i stedet for klodserne.

Modellen skal kigge "fremad". Scripts inde i modellen bliver slettet automatisk for en sikkerheds skyld.

## ✨ Niveauer
| Niveau | Chance | Bonus |
|---|---|---|
| Normal | | x1 |
| Golden | 1 ud af 25 | x2 |
| Diamond | 1 ud af 150 | x4 |
| Rainbow (skifter farve) | 1 ud af 1.000 | x8 |
| Cosmic | 1 ud af 10.000 | x20 |
| **Rainbow Cosmic** | **1 ud af 1.000.000** | **x100** |

**Fusion Machine** (midt mellem baserne): 2 ens monstre på samme niveau bliver til det næste niveau.

## 🦹 Stjæl og forsvar
- **Stjæl** fra andres indhegning (hold **E**). Ejeren får en alarm.
- Løb hjem, eller **kast (F)** monsteret ind i din base.
- **Mog Slap:** Slå tyve og folk, der bærer et monster, så de taber det.
- **Vault** (glasburet bagerst): Monstre derinde kan aldrig stjæles og beholdes ved rebirth.
- **LOCK-pladen:** Låser basen i 45 sekunder.

## 🔄 Rebirth, events og Robux
- **Rebirth** (knap i højre side) giver +1x penge og +1x MOG. Rebirth 10 giver en eksklusiv **Golden Phoenixmog**.
- **Lucky Rush** hvert 10. minut: 3x held og 3x flere monstre.
- **Daily Reward**: Dag 7 giver et gratis Epic- eller Legendary-monster.
- **Robux**: 2x Money, VIP, +3 Monster Slots, Fast Stealing, +1 Vault Slot, Server Luck, Super Lock og Cash Pack.
  De sjældneste monstre kan **ikke** købes.

---

## 🛠️ Sådan starter du det
1. Download **`MogMonsters.rbxlx`**.
2. **Roblox Studio** → **File** → **Open from File…** → vælg filen.
3. Tryk på den blå **▶**.

Output (fanen **Script** → **Output**) skal sige:
```
MOG MONSTERS server v3 started OK!
MOG MONSTERS client v3 started OK!
```

**Test med 2 spillere:** Fanen **Test** → *Clients and Servers* → **2 Players** → **Start**.
**Tip:** Sæt `START_CASH = 1000000` i CONFIG for at teste hurtigt. Sæt den tilbage til `0`, før du udgiver.

## 🚀 Udgiv
1. **File → Publish to Roblox**.
2. **Game Settings → Security** → slå **Enable Studio Access to API Services** til, så spillet gemmer.
3. **Max Players = 8**.
4. Opret gamepasses og products på **create.roblox.com → Monetization**, og sæt deres ID'er ind i **CONFIG**.
