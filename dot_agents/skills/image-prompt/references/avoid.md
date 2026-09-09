# AI っぽさを削るブロック集

`HUMAN-MADE CHARACTER` と `AVOID` に差し込む断片。**全部入れない**。被写体に該当するものだけを選び、合計 6 行程度に収める（盛りすぎ自体が AI っぽさの原因になる）。

出典の考え方: maeda-niku18「AI っぽくない画像生成プロンプト集」（Qiita, <https://qiita.com/maeda-niku18/items/b633dda178c505461080>）の 4 戦略を参考に、英語表現は本ファイルで独自に記述している。

## 4 つの戦略

生成物が「AI っぽい」と感じられる原因は、たいてい次の 4 つの裏返しである。プロンプトを書くときはこの 4 つを意識して断片を選ぶ。

1. **不完全さを名指しで要求する** — 「自然に」では効かない。`slightly irregular` `uneven line pressure` のように、どこがどう狂うのかを書く
2. **物理的な質感を借りる** — 紙の目、インクのにじみ、版ズレ。実在の画材の癖を指定すると手作り感が出る
3. **余白と色数を数字で縛る** — `limited three-to-five-color palette` `at most three objects in frame`。制限がないと画面が埋まり、それが AI っぽさになる
4. **禁止事項を先に潰す** — `AVOID` ブロックで、出てほしくないものを明示する

## 1. 手作り感を残す（HUMAN-MADE CHARACTER）

```
preserve natural imperfections: uneven line pressure, slightly asymmetric shapes,
color that does not align perfectly with the outlines, small variations in stroke weight
```

## 2. ツルツルした質感を避ける（AVOID）

```
AVOID: glossy plastic surfaces, airbrushed gradients, glowing rim light,
3D-render sheen, digital bloom, perfectly smooth uniform fills
```

## 3. 情報の盛りすぎを避ける（COMPOSITION / AVOID）

```
COMPOSITION: one clear subject, at most three supporting objects, large calm empty areas,
plain uncluttered background
AVOID: busy backgrounds, floating decorative particles, unrelated props filling the margins
```

## 4. 人物を自然にする（HUMAN-MADE CHARACTER / AVOID）

```
figures in relaxed everyday postures with natural weight distribution, ordinary calm expressions
AVOID: exaggerated open-mouth smiles, mannequin poses, symmetrical model stances,
stock-photo enthusiasm, hands with wrong finger counts
```

## 5. 子どもの絵を自然にする

```
children drawn with age-appropriate head-to-body proportions, plain everyday clothing,
unposed natural expressions
AVOID: doll-like faces, oversized sparkling eyes, adult proportions on a child's body
```

## 6. 背景を AI っぽくしない（AVOID）

```
AVOID: repeating wallpaper-like patterns, impossible architecture, warped perspective,
signage with garbled lettering, endlessly receding identical objects
```

テキストを絵の中に入れたくないときは `no text, no lettering, no watermark, no logos` を足す（多くのモデルは文字を崩すため、既定で入れてよい）。

## 7. 色を AI っぽくしない（VISUAL STYLE / AVOID）

```
limited palette of three to five colors, slightly desaturated, one accent color only
AVOID: oversaturated rainbow palettes, neon glow, teal-and-orange grading, HDR contrast
```
