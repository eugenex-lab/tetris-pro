Ah! Perfect — you’re using **Flutter / Dart**, not React Native. That changes things — we need the master prompt to tell Antigravity to **generate a full Flutter project** for **Tetris Pro**, keeping all your advanced features, dark wooden theme, coins, skins, AdMob integration, Supabase backend, leaderboard, rewarded ads, and stages.

Here’s the **optimized master Flutter prompt** you can paste into your Antigravity skill:

---

### **Master Antigravity Prompt — Tetris Pro Flutter Edition**

You are an expert **Flutter / Dart mobile game developer**. Create a full **Flutter mobile game project** called **“Tetris Pro”**, optimized for **iOS and Android**, with **dark wooden theme** and advanced mobile game features. Follow these exact specifications:

---

#### **1️⃣ Theme & UI**

* Dark app background with subtle **wooden textures**.
* Default block skin: **Walnut**.
* Additional skins: Light Oak, Maple, Mahogany, Burnt Wood, Painted Cedar.
* Wooden-themed buttons for **Rotate, Move Left, Move Right, Drop, Pause**.
* Top HUD: **Hearts, Coins, Level, Score**.
* **Next block preview** and **Hold block feature**.
* Persistent **AdMob banner** at bottom.
* Smooth animations:

  * Blocks slide with slight bounce.
  * Line clears → wood chip particle effect.
* Dark mode by default; coins and hearts clearly visible.

---

#### **2️⃣ Gameplay Mechanics**

* Standard **Tetris 10x20 grid**.
* Falling blocks, line clearing, rotation, hold, and drop mechanics.
* Levels with **progressive speed**.
* **Lives / Health system**:

  * Start with **3 hearts**.
  * Losing all hearts triggers **Game Over modal**:

    * Option: watch **rewarded ad** → +1 heart.
    * Option: spend coins → +1 heart.
* **Stage unlocking system**:

  * Player earns points to unlock stages.
  * Stages can have unique challenges or skins.

---

#### **3️⃣ Coins & Rewards**

* Coins earned per line, combos, and level completion.
* Coins spent to:

  * Buy block skins.
  * Unlock stages.
  * Revive hearts.
* Transparent, top HUD coin display.
* **Rewarded ads** give coins instantly.
* Skins and stages unlockable via coins or ads.

---

#### **4️⃣ Ads Integration (AdMob)**

* **Banner ad** persistent at bottom.
* **Interstitial ad** triggers when user leaves and comes back.
* **Rewarded ads** for extra coins, hearts, or unlocking stages/skins.
* Ads for in-app purchases like coin bundles.

---

#### **5️⃣ Supabase Backend**

* Store **user data**:

  * `id, username, coins, hearts, level, score, skin, last_played`.
* **Leaderboard**:

  * Top 10 daily scores.
  * Reset daily at midnight.
* Functions for:

  * Loading user data.
  * Updating coins, hearts, score in real-time.
  * Updating leaderboard after each game.

---

#### **6️⃣ Game Screens / Components**

* **HomeScreen**: Play button, Skin Shop, Leaderboard.
* **GameScreen**: Tetris board, controls, next block, hold, HUD.
* **GameOverModal**: Final score, coins earned, revive options.
* **SkinShop**: Display all skins, coin cost, highlight equipped skin.
* **LeaderboardScreen**: Daily top 10 scores.

---

#### **7️⃣ Advanced Features**

* Stage-based progression with unlockable skins and stages.
* Dynamic speed adjustment as player levels up.
* Smooth animations for blocks, line clears, and stage unlocks.
* Coin & ad system fully integrated and tracked.
* Dark wooden theme consistent across all screens.

---

#### **8️⃣ Project Structure Recommendation**

```

---

#### **9️⃣ Output Requirements for Antigravity**

* Full **Flutter project** ready for iOS/Android.
* Include **Supabase integration** for users and leaderboard.
* Include **AdMob integration** (banner, interstitial, rewarded).
* Default **Walnut skin** and example other skins.
* Coins, hearts, levels, stage progression implemented.
* Dark wooden theme and smooth animations.
* Modular code for easy maintenance.

---

If you want, I can **also generate the full starter Flutter project code** for you right now, including:

* Tetris logic (grid, blocks, rotation, line clearing)
* HUD with coins, hearts, score, level
* Supabase setup with leaderboard
* AdMob integration (banner, interstitial, rewarded)
* Skin shop and stage unlock system
* Dark wooden theme UI

It’ll be **ready to run** in Flutter with minimal setup.

Do you want me to do that next?
