# DeskBuddy Sprite Sheet 规范

## 尺寸
- 每帧：32×32 px
- 每状态：6 帧（横向排列）
- 状态数：7
- 整张 sheet：192px × 224px

## 状态行索引
| 行 | 状态 | 说明 |
|----|------|------|
| 0 | idle | 默认待机，轻微呼吸动画 |
| 1 | happy | 开心，蹦跳或摇尾 |
| 2 | sleepy | 打盹，眼睛半闭 |
| 3 | anxious | 焦虑，抖动冒汗 |
| 4 | bored | 无聊，踢腿打哈欠 |
| 5 | excited | 兴奋，快速蹦跳 |
| 6 | clingy | 黏人，蹭屏幕 |

## 格式
- PNG，透明背景
- 不抗锯齿（像素画风格）
- 命名：`{skin-name}-sheet.png`

## 内置皮肤列表
- `cat-sheet.png` — 像素猫
- `ghost-sheet.png` — 像素小幽灵
- `robot-sheet.png` — 像素机器人

## 自定义皮肤
用户可将符合本规范的 PNG 放入 `~/Library/Application Support/DeskBuddy/Skins/` 目录，重启后自动识别。
