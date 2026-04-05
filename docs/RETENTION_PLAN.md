# 6-Month User Retention Strategy: Tetris Pro

## Overview
This document outlines the strategic approach for retaining users in "Tetris Pro" over a 6-month period using local notifications. The strategy focuses on three pillars: **Return Reminders**, **Progress Milestones**, and **Engagement Incentives**.

## 1. Inactivity & Return Reminders
We aim to bring users back with escalating value propositions.

### Inactivity Ladder (Dynamic & Randomized)
Each time the user plays, we reset this ladder and schedule:
- **Day 1 (24h)**: "We miss you! Your blocks are waiting." (100 randomized variations)
- **Day 3 (72h)**: "New challenge available! Come beat your score." (100 randomized variations)
- **Day 7 (1 Week)**: "💰 50 Coins Waiting!" (100 randomized variations focusing on the 50-coin bonus)
- **Day 30 (1 Month)**: "🏆 Legendary Status" (100 randomized variations for legendary return)

## 2. Implementation: The Sliding Window
To stay within mobile OS limits (generally 64 scheduled notifications), we've implemented:
- **Automatic Refresh**: Every time the app starts or a game ends, all old notifications are cleared and the next 30 days are re-scheduled.
- **Randomization**: The messages are pulled from a pool of 400+ strings stored in `lib/data/retention_data.dart` to ensure the user never sees the same reminder twice in a row.
- **Timing**: Notifications are scheduled for **6:00 PM**, an optimal time for high-engagement Tetris play.

## Implementation Technicalities
- **Sliding Window**: To stay within the 64-notification limit (OS restriction), the app refresh the next 30 days of schedules every time it launches.
- **Dynamic Scheduling**: Inactivity reminders are cancelled and rescheduled every time the user exits a game.
- **Offline First**: All notifications are local, requiring no internet connection.

---
*Created by Antigravity AI for Eugenex Lab.*
