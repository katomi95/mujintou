# 各エピソードを窓ありで再生して画面を撮り、1話ごとの一覧画像にまとめる。
#   powershell -File tools/shoot.ps1 [話番号...]
$Eps = if ($args.Count) { $args | ForEach-Object { [int]$_ } } else { 0..9 }
$gp = "C:\Users\katom\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
$root = Split-Path -Parent $PSScriptRoot
$times = @{
  0 = "2.5,6,12,18,24,29"; 1 = "3,7,12,18,24,31"; 2 = "4,9,14,20,27,33,40,47"; 3 = "3,6,10,18,22,60";
  4 = "30,35,37,38.5"; 5 = "3,8,14,20,26,32"; 6 = "2,6,11,16,22,25,28,32"; 7 = "3,6,10,16,22,28,35";
  8 = "3,10,15,20,26,29.5,32"; 9 = "2,4,7,12,18,26,36,44,50"
}
Set-Location $root
Remove-Item "$root\shots\ep*","$root\shots\sheet*" -ErrorAction SilentlyContinue
foreach ($e in $Eps) {
  & $gp --path . --resolution 1280x720 -- "--ep=$e" "--fast=3" "--quit" "--mute" "--shots=$root/shots" "--at=$($times[$e])" 2>&1 | Out-Null
}
py -3.10 "$root\tools\sheet.py"
