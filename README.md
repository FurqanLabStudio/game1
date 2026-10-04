# Party Games (game1)

Aik phone par 2 se 4 dost mil kar khelein. Abhi is mein 2 games hain:

**Snakes**: har player ke paas do buttons hain (left / right). Daba kar rakho to snake mudta rehta hai. Kisi ke jism, apne jism ya deewar se takraye to out. Safed dane khao to snake lamba hota hai. Aakhri zinda snake jeetta hai.

**Paint Fight**: har player ki patti joystick hai. Jahan ungli rakho wahin joystick ban jata hai, phir ghaseeto. Brush chalta rehta hai aur zameen ko tumhare rang se rangta hai. 40 second baad jiska rang sab se zyada, wo jeeta.

Players ki jagah: P1 (Red) neeche left, P2 (Blue) upar, P3 (Green) neeche right, P4 (Yellow) upar left. Upar wale players ke controls ulte hain taake saamne baith kar khel sakein.

Flutter mein bana hai, isliye aik hi code Android aur iOS dono par chalega.

## 1. Code GitHub par daalna

Computer par (git install hona chahiye):

```bash
unzip game1.zip
cd game1
git init
git add .
git commit -m "Snakes aur Paint Fight"
git branch -M main
git remote add origin https://github.com/ObaidTech/game1.git
git push -u origin main
```

Agar repo mein pehle se README waghera hai aur push reject ho jaye:

```bash
git pull origin main --allow-unrelated-histories
git push -u origin main
```

## 2. APK khud ban jayegi

Har push ke baad GitHub Actions APK banata hai (5 se 10 minute). Repo ke **Actions** tab mein progress dekh sakte hain.

Banne ke baad APK yahan milegi: https://github.com/ObaidTech/game1/releases/latest

## 3. Phone par install

1. Phone ke browser mein upar wala Releases link kholo (repo private hai to GitHub mein login karna hoga).
2. `party-games-XX.apk` download karo aur kholo.
3. Android "unknown apps" ki ijazat maange to de do (Settings → is browser ke liye "Allow from this source").
4. Install karo. Naya version aaye to wahi APK dobara install kar do, purani app update ho jayegi.

## Apne computer par chalana (optional)

Agar Flutter install hai:

```bash
flutter create --project-name game1 --org com.obaidtech --platforms android,ios .
flutter run
```

`flutter create .` sirf `android/` aur `ios/` folders banata hai, `lib/` ka code nahi chhedta. Chahein to ye folders bhi repo mein commit kar dein.

## iOS

Code tayyar hai. iPhone par chalane ke liye Mac + Xcode chahiye: `flutter create` ke baad `open ios/Runner.xcworkspace`, apni Apple ID se signing set karo aur phone par run karo. App Store ke liye Apple Developer account ($99 saal) lagta hai.

## Code ka naqsha

```
lib/
  main.dart                      app shuru, portrait lock
  core/players.dart              4 players ke rang, naam, jagah
  core/game_engine.dart          har game ka common interface
  screens/home_screen.dart       menu: players ki tadaad + games
  screens/game_shell.dart        game loop, 3-2-1, pause, result, score
  widgets/control_layout.dart    upar/neeche controls ki patti
  widgets/turn_controls.dart     Snakes ke left/right buttons
  widgets/joystick_zone.dart     Paint Fight ka joystick
  games/snakes/snake_game.dart   Snakes ki logic + drawing
  games/paint/paint_game.dart    Paint Fight ki logic + drawing
.github/workflows/build-apk.yml  APK banane wala GitHub Action
```

Nayi game daalni ho to `GameEngine` ko implement karo aur `home_screen.dart` ki `_games` list mein add kar do.
