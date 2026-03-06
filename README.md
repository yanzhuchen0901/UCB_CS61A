# Ants vs. SomeBees（中文项目说明）

> 一句话：这是一个面向对象 (OOP) 的塔防小游戏。你要在蚂蚁王国的隧道里部署不同类型的蚂蚁，用有限的食物资源抵挡一波波蜜蜂入侵。

这个仓库是 UC Berkeley CS 61A Project 3 “Ants Vs. SomeBees” 的改编版本：核心逻辑在 `ants.py`，并提供了一个基于 Flask + Socket.IO 的网页 GUI（运行 `gui.py` 会自动打开浏览器）。

---

## 你将完成什么

你要在 `ants.py` 里把一套“未实现的骨架代码”补全，让游戏从**可导入但功能缺失**变成**可玩、可测、可视化**：

- 建模游戏世界：格子（Place）如何连接、昆虫（Insect）如何进出格子。
- 用继承/多态实现不同单位：采集、攻击、范围限制、爆炸、抗打、吞食、容器、防水、王后增益……
- 让整套规则在自动化测试（OK）与 GUI 中表现一致。

---

## 最终实现效果（你做完以后会看到什么）

完成必做题后，你应该能：

- 在浏览器中看到一张隧道网格和蜂巢入口；点击 **START** 开始游戏。
- 每回合显示 **Food**（食物）与 **Turn**（回合数），并根据食物数量解锁可部署的蚂蚁类型。
- 在某个格子部署蚂蚁后：
  - 采集蚂蚁会稳定产粮；
  - 投手会对射程内最近的一格蜜蜂随机投掷并造成伤害；
  - 短/长投手会体现射程限制；
  - 火蚂蚁在受击时会对同格蜜蜂造成灼烧，死亡时会产生额外爆炸伤害；
  - 墙蚂蚁不攻击但能长期阻挡；
  - 饥饿蚂蚁可以“吃掉”同格一只蜜蜂，然后进入咀嚼冷却；
  - 护卫/坦克等容器蚂蚁可以与另一只蚂蚁同格：容器在前承伤，被保护的蚂蚁照常行动；
  - 水域格会“淹死”非防水昆虫；潜水投手能在水里正常工作；
  - 王后会攻击并强化身后的蚂蚁伤害（且胜负条件会与王后相关）。
- 游戏结束条件清晰：
  - 蜜蜂到达基地（隧道尽头）或王后死亡会失败；
  - 消灭所有进攻蜜蜂会获胜。

---

## 快速开始（网页 GUI）

在仓库根目录运行：

```bash
python gui.py
```

- 程序会自动选择可用端口，并打开浏览器页面。
- 终端按 `Ctrl + C` 停止服务器。
- 刷新网页会开始新一局。

### 难度与地图选项
GUI 读取 `ants_plans.py:create_game_state()` 的命令行参数，因此你可以这样启动：

```bash
# 简单/普通/困难/额外困难（不写 -d 默认 normal）
python gui.py -d easy
python gui.py -d normal
python gui.py -d hard
python gui.py -d extra-hard

# 启用带水域的地图
python gui.py --water

# 测试时给更多初始食物
python gui.py --food 10
```

> 提示：参数也可以组合使用，例如 `python gui.py -d easy --water --food 8`。

---

## 自动测试（OK）

这个仓库使用 OK（`ants.ok` 配置）来跑单元测试。

```bash
# 跑默认题目（00~12）
python ok

# 只跑某一题，例如 Problem 4
python ok -q 04

# 失败时进入交互式调试
python ok -q 07 -i

# 不联网（只在本地跑）
python ok --local
```

额外挑战与可选题也提供了测试（例如 `EC1`、`optional1`），可以按题号单独运行：

```bash
python ok -q EC1
python ok -q optional1
```

---

## 作业主线任务（按题号概览）

> 下面是“你要实现什么”，不是“怎么写”。写代码时建议：先跑一次 `python ok -q XX` 看清测试期望，再去 `ants.py` 定位对应 `BEGIN Problem XX`。

### Phase 1：基础单位与隧道连接
- **Problem 1**：实现 `HarvesterAnt.action`，每回合为全局食物 +1，并补全相关 `food_cost` 设定。
- **Problem 2**：补全 `Place` 的入口/出口连接逻辑（让隧道能从蜂巢一路连到基地）。
- **Problem 3**：实现 `ThrowerAnt.nearest_bee`：沿着入口方向寻找“最近的、可攻击的”蜜蜂（蜂巢内的蜜蜂不可被攻击）。

### Phase 2：射程、爆炸、肉盾、吞食
- **Problem 4**：加入 `ShortThrower` / `LongThrower`，并扩展投手的“可攻击距离”规则。
- **Problem 5**：实现 `FireAnt.reduce_health`：受击时灼烧同格蜜蜂，死亡时造成额外爆炸伤害。
- **Problem 6**：实现 `WallAnt`：高生命值、阻挡但不进行攻击动作。
- **Problem 7**：实现 `HungryAnt`：能吃掉同格一只蜜蜂并进入冷却（冷却是实例属性）。

### Phase 3：容器系统与组合单位
- **Problem 8a**：实现 `ContainerAnt` 的“是否能容纳 / 存放 / 行动转发”逻辑。
- **Problem 8b**：改造 `Ant.add_to`：允许“一个容器 + 一个被保护者”同格共存（其它情况要抛出断言）。
- **Problem 8c**：实现 `BodyguardAnt`（容器蚂蚁的一种）。
- **Problem 9**：实现 `TankAnt`：既是容器，又能每回合对同格所有蜜蜂造成伤害。

### Phase 4：水域、防水与王后
- **Problem 10**：实现 `Water.add_insect`：非防水昆虫入水直接归零血量；防水的照常进入。
- **Problem 11**：实现 `ScubaThrower`：继承投手行为，但具备防水能力。
- **Problem 12**：实现 `QueenAnt` 与增益机制：
  - `QueenAnt.action`：像投手一样攻击，同时让身后蚂蚁伤害翻倍（每只蚂蚁最多翻倍一次）。
  - `QueenAnt.reduce_health`：王后死亡触发失败。
  - `Ant.double`：实现“只翻倍一次”的通用机制。

---

## 额外挑战（Extra Credit，可选）

这些题通常更考验“行为改写/高阶函数/状态机”的掌控：

- **EC1 SlowThrower**：命中后让蜜蜂进入减速状态。
- **EC2 ScaryThrower**：命中后让蜜蜂进入“后退”状态（且只能被恐吓一次）。
- **EC3 NinjaAnt**：不阻挡通道，但会对同格所有蜜蜂造成伤害；同时需要调整 `Bee.blocked` 逻辑。
- **EC4 LaserAnt**：沿路径对多目标造成衰减伤害（需要统计距离与已射击次数等）。

---

## 代码导览（你主要会碰到的文件）

- `ants.py`：作业主战场。所有核心类（Place/Insect/Ant/Bee/GameState/各类蚂蚁）都在这里。
- `ants_plans.py`：关卡/难度配置（蜂群波次、地图规模、水域布局）。
- `gui.py`：网页 GUI 服务器（Flask + Socket.IO），负责把后端事件同步到前端动画。
- `templates/index.html` + `static/`：前端界面与动画逻辑。
- `tests/`：OK 自动测试用例，按题号拆分。

---

## 验收清单（建议的完成顺序）

- 先把 Problem 1~3 跑通（基础可玩）。
- 再做 4~7（更多单位与局部规则）。
- 再做 8a~9（容器系统是全作业的核心难点）。
- 最后做 10~12（环境规则与王后机制）。

每完成一个题号：

```bash
python ok -q XX
```

通过后再进入 GUI 体验，能更快发现“规则一致性”问题。

---

## 致谢

- 原作业来自 UC Berkeley CS 61A（Ants Vs. SomeBees）。
- 本仓库的 GUI/改编版在 `gui.py` 文件末尾列出了贡献者与致谢信息。
