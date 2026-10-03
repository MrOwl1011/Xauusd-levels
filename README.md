<div align="center">

# 🥇 Golden Bar

**A weekly price-level Expert Advisor for Gold (XAUUSD) on MetaTrader 5**

![Platform](https://img.shields.io/badge/platform-MetaTrader%205-1f6feb)
![Language](https://img.shields.io/badge/language-MQL5-orange)
![Symbol](https://img.shields.io/badge/symbol-XAUUSD-gold)
![Version](https://img.shields.io/badge/version-15.7-brightgreen)
![Status](https://img.shields.io/badge/status-experimental-red)
![License](https://img.shields.io/badge/license-MIT-blue)

*Draws a ladder of levels every week. Trades the bounce when price touches one.*

[How it works](#-how-it-works) ·
[Level maths](#-how-the-levels-are-built) ·
[Filters](#-entry-filters) ·
[Inputs](#-inputs-reference) ·
[Install](#-installation) ·
[Limits](#-known-limitations)

</div>

---

## 📸 Preview

<div align="center">

<img src="docs/screenshot.png" alt="Golden Bar level grid on an XAUUSD chart" width="800">

*The weekly level grid on an XAUUSD chart: main levels in sky blue, minor levels in gold, base line thicker.*

</div>

---

## ✨ Features

- 📏 **Weekly level grid**: 50 main levels above and 50 below a base price, with a minor level between each pair. It redraws itself at the start of every week.
- 🔁 **Level-bounce entries**: waits for price to cross a level, then trades the pullback on the next candle.
- 🎛️ **Every rule is a switch**: ADX, DI direction, SMA, ratio and session filters can each be turned on or off in the inputs.
- 💰 **Risk levels**: six lot-size presets, from Low to Super High, with an optional dynamic lot size.
- 🛡️ **Break-even**: moves the stop loss to the entry price once a trade is in profit.
- 🧹 **Clean chart**: main lines in sky blue, minor lines in gold, and a thicker base line.

---

## 🧠 How it works

```
 Every week            Price crosses a level       Next candle closes
┌───────────────┐     ┌──────────────────────┐    ┌──────────────────────────┐
│ Pick a base   │ ──▶ │ Mark it with an arrow│ ─▶ │ Closed ABOVE the level?  │
│ level, draw   │     │ and remember the     │    │   → want to SELL         │
│ the ladder    │     │ level                │    │ Closed BELOW the level?  │
└───────────────┘     └──────────────────────┘    │   → want to BUY          │
                                                  └────────────┬─────────────┘
                                                               ▼
                                              All switched-on filters agree?
                                                   yes → open the trade
                                                   no  → skip
```

In one sentence: **the EA bets that price bounces back from a level it just touched.**

---

## 📐 How the levels are built

The base level comes from last week's open:

```
base = floor((lastWeekOpen − 140) / 10) × 10 + 3.6
```

**Example**

| Step | Value |
|---|---|
| Last week's open | `3350.40` |
| `(3350.40 − 140) / 10` | `321.04` |
| Cut to a whole number | `321` |
| Join with `"3.6"` as text | `"3213.6"` |
| **Base level** | **`3213.6`** |

So every main level ends in **.6** with a 3 before it (`3213.6`, `3223.6`, `3233.6`, …).

```
 3263.6  ─────────────  main  (+5 steps)
 3258.6  - - - - - - -  minor
 3253.6  ─────────────  main
   ⋮
 3223.6  ─────────────  main
 3218.6  - - - - - - -  minor
 3213.6  ━━━━━━━━━━━━━  BASE (thick line)
 3208.6  - - - - - - -  minor
 3203.6  ─────────────  main
   ⋮
```

| Setting | Value |
|---|---|
| Main level spacing | $10 |
| Minor level spacing | $5 |
| Main levels per side | 50 (about ±$500 around the base) |
| Redraw | at every new weekly bar, and once when attached |

---

## 🎚️ Entry filters

A trade opens only when **every filter you left ON agrees**. Defaults match the `d.set` preset. Turn them all OFF and every level touch becomes a trade.

| Filter | Input | What it checks | Default |
|---|---|---|---|
| **ADX strength** | `UseADXFilter` | ADX is above `ADXMinLevel` (a strong trend) | ON · 30 |
| **DI direction** | `UseDIFilter` | +DI/−DI agree with the trade (+DI above −DI for buys) | OFF |
| **SMA trend** | `UseSMAFilter` | Price is above both M1 SMAs for buys, below both for sells | ON · 45 / 150 |
| **Good ratio** | `UseRatioFilter` | The close is within about $0.20 of the level | ON · 4.5 |
| **Session** | `UseSessionFilter` | Only trade in the session windows (server time) | OFF · 4–7 and 10–3 |

---

## 🛠️ Inputs reference

### Lot size

| Input | Meaning |
|---|---|
| `UseDynamicLotSize` | Recalculate the lot from current equity for every trade |
| `RiskLevel` | Low (default) · Medium Low · Medium · Medium High · High · Super High |

Lot size is **account equity × a factor**:

| Risk level | Factor |
|---|---|
| Low | 0.0001 |
| Medium Low | 0.0002 |
| Medium | 0.0005 |
| Medium High | 0.0008 |
| High | 0.001 |
| Super High | 0.0015 (fixed) / 0.003 (dynamic) |

> ⚠️ These factors are large. For example, $10,000 equity at **Low** (the default) gives **1.00 lot**, and at **Medium** gives **5.00 lots**. Check the lot size on a demo account before going live.

### Break-even

| Input | Default | Meaning |
|---|---|---|
| `UseBreakEven` | ON | Move the stop loss to break-even once a trade is in profit |
| `BreakEvenTrigger` | 0.5 | Profit, in dollars of price move, that triggers it |
| `BreakEvenOffset` | 0.15 | The new SL sits this many dollars past the open price, which covers costs |

Example: a buy opened at 3250.00 reaches 3250.50, so the SL moves to 3250.15. The SL only ever moves in your favor and the take profit is kept.

### Filters

`UseADXFilter` · `ADXPeriod` (14) · `ADXMinLevel` (30) · `UseDIFilter` (off) · `UseSMAFilter` · `FastSMAPeriod` (45) · `SlowSMAPeriod` (150) · `UseRatioFilter` · `GoodRatioInput` (4.5) · `UseSessionFilter` (off) · `Session1StartHour` (4) · `Session1EndHour` (7) · `Session2StartHour` (10) · `Session2EndHour` (3)

### Fixed in code (edit the `.mq5` to change)

| Name | Value | Meaning |
|---|---|---|
| `Step` | 10.0 | Main level spacing in dollars |
| `MinorStep` | 5.0 | Minor level spacing in dollars |
| `LevelsCount` | 50 | Main levels per side |
| `sls` | 5 | Stop loss, dollars beyond the level |
| `tps` | 50 | Take profit, dollars from the level |

---

## 🚀 Installation

1. In MetaTrader 5, open **File → Open Data Folder → `MQL5` → `Experts`**.
2. Copy `Gold Bar.mq5` into that folder.
3. Open it in **MetaEditor** and press **F7** to compile.
4. Open an **XAUUSD** chart, drag **Gold Bar** onto it and enable **Algo Trading**.
5. Set your inputs. The level ladder appears on the first tick.

> 💡 **Test first.** Run it in the Strategy Tester or on a demo account before using real money.

---

## 📁 Repository layout

| File | What it is |
|---|---|
| `Gold Bar.mq5` | The current EA |
| `docs/screenshot.png` | Chart preview shown in this README |
| `d.set` | Preset with the default input values. In MT5 click **Load** in the Inputs tab to use it. |
| `LICENSE` | MIT license |

---

## ⚠️ Known limitations

- **No cap on open trades.** Several trades can open on the same level.
- **No spread or slippage check** before sending an order.
- **Trailing stop rarely fires.** It starts at 5000 points ($50 on gold), the same distance as the take profit.
- **Session hours use broker server time**, not GMT. A window whose end is before its start, like 10 → 3, wraps past midnight.
- **The base level uses last week's open**, not the current week's.
- **Fixed lot sizes are computed once** when the EA loads, so they don't follow equity changes. Use `UseDynamicLotSize` if you want that.

---

## 📄 License

Released under the [MIT License](LICENSE).

---

## 📜 Disclaimer

This software is provided for **educational purposes**. Trading gold and leveraged products carries a high risk of loss. Past results do not guarantee future results, and nothing here is financial advice. **You are responsible for any trades the EA makes.**

---

<div align="center">

Made by **Zaid Elamshaaly (Mr. Owl)**
[GitHub: MrOwl1011](https://github.com/MrOwl1011) · [Instagram: @coding_xaid](https://www.instagram.com/coding_xaid/)

⭐ If this helped you, give the repo a star.

</div>
