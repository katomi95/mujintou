# 無人島に持っていくもの

**遊ぶ: https://katomi95.github.io/mujintou/**

「無人島にひとつだけ持っていけるとしたら？」をそのままゲームにした短編コメディ（Godot 4.7 / Web）。
10個のアイテムを選ぶと、それぞれ30〜55秒の短い展開が流れる。どれを選んでも、主人公はまともに使わない。
全部見ると、選択画面が少し壊れる。

- 操作はマウス（クリック）だけ。演出中は押し続けで早送り、「やめる」で中断。
- 絵はすべてコード描画（素材ファイルなし）。音（BGM・効果音）は `tools/gen_audio.py` で合成。
- フォントは Noto Sans JP（SIL OFL）の使用文字サブセット。`fonts/OFL.txt` 参照。

## 開発メモ

```
py -3.10 tools/gen_audio.py        # 音の再生成
py -3.10 tools/make_font.py        # 文言を変えたら必ず再実行（scripts/*.gd の文字を拾う）
godot --headless --path . -- --all --fast=8 --quit --mute     # 全話を通して所要時間とエラーを確認
godot --path . -- --ep=3 --fast=3 --quit --mute --shots=shots --at=3,7,12   # 撮影（tools/shoot.ps1 で一括）
godot --headless --path . --export-release Web docs/index.html
```

構成: `scripts/stage.gd`（海・島・字幕・時間経過・SE）、`scripts/art.gd`（主人公と小物の描画）、
`scripts/episodes.gd`（10話）、`scripts/main.gd`（タイトル・選択・進行）。
