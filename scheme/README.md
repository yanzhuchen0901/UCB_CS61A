# Scheme Interpreter 项目说明

这个仓库是一个简化版 Scheme 解释器项目。你的目标不是“从零重写一门语言”，而是在已经搭好的骨架上，把缺失的求值、环境、特殊形式和若干 Scheme 函数补全，最后得到一个可以交互运行的 Scheme 解释器。

项目完成后，你将能够：

- 在 REPL 中输入 Scheme 表达式并得到结果。
- 支持变量绑定、函数定义、匿名函数、词法作用域。
- 支持 quote、begin、and、or、cond、let 等特殊形式。
- 支持动态作用域的 mu。
- 在 Scheme 文件中实现 enumerate、merge 等函数。
- 使用测试系统逐题验证实现是否正确。

## 1. 你到底需要做什么

这个项目的核心是补全以下 4 个文件中的空白部分：

- `scheme_classes.py`
- `scheme_eval_apply.py`
- `scheme_forms.py`
- `questions.scm`

题目编号从 1 到 16，对应的实现位置已经在源码里用 `BEGIN PROBLEM` 和 `*** YOUR CODE HERE ***` 标出来了。

## 1.1 先理解几个核心对象

在开始写题之前，建议你先把这个项目里最关键的几个对象看明白。很多题表面上是在“填空”，本质上是在让这些对象按正确的方式协作。

### Frame 是什么

`Frame` 表示一个环境帧，也可以理解成“一层作用域”。

它有两个核心属性：

- `bindings`：一个 Python 字典，用来保存“符号 -> 值”的映射。
- `parent`：指向父环境帧。

你可以把环境想成一条链：

```text
当前 Frame -> 父 Frame -> 更外层 Frame -> Global Frame
```

例如下面这个 Scheme 程序：

```scheme
(define x 10)
(define (f y) (+ x y))
(f 3)
```

运行时会有这样一个查找过程：

- 全局环境里绑定了 `x -> 10`
- 调用 `(f 3)` 时会新建一个子 Frame，里面绑定 `y -> 3`
- 计算 `(+ x y)` 时，先在当前 Frame 找 `x`
- 当前帧没有 `x`，就去 `parent` 里找
- 最后在全局 Frame 找到 `x = 10`

所以 `Frame.lookup` 的本质就是“沿着环境链向外找名字”。

### 为什么需要 Frame

如果没有 `Frame`，解释器就没法回答下面这些问题：

- `x` 现在绑定的是什么值？
- 函数调用时参数该放在哪里？
- 局部变量为什么不会污染全局变量？
- 为什么内层作用域能访问外层作用域的名字？

也就是说，`Frame` 是整个解释器里“变量、作用域、闭包”成立的基础。

### Global Frame 是什么

全局环境是整个解释器启动时创建的第一层环境。

它通常包含：

- 算术函数，比如 `+`、`-`、`*`、`/`
- 列表操作，比如 `car`、`cdr`、`cons`
- 谓词函数，比如 `null?`、`pair?`、`symbol?`
- 解释器支持的一些特殊内建行为，比如 `eval`、`apply`

在这个项目里，全局环境是通过 `create_global_frame()` 创建出来的。

### Procedure 是什么

`Procedure` 是“过程对象”的统一抽象。你可以把它理解成“所有可调用东西的父类”。

在 Scheme 里，像下面这些都属于“可以被调用的过程”：

```scheme
+
car
(lambda (x) (* x x))
(mu (x) (+ x y))
```

这个项目里具体分成三种：

- `BuiltinProcedure`
- `LambdaProcedure`
- `MuProcedure`

### BuiltinProcedure 是什么

`BuiltinProcedure` 代表“底层由 Python 实现的 Scheme 函数”。

例如：

- `+`
- `-`
- `car`
- `cdr`
- `display`

这些过程本质上不是用 Scheme 写的，而是 Python 函数包装后暴露给 Scheme。

它的重要属性有：

- `py_func`：真正要调用的 Python 函数。
- `need_env`：调用时是否还需要把当前环境传进去。
- `name`：打印显示用的名字。

所以 Problem 2 其实就是在做一件事：

- 把 Scheme 参数表拆开
- 转成 Python 参数
- 调用 `py_func`

### LambdaProcedure 是什么

`LambdaProcedure` 代表由 `lambda` 或函数形式的 `define` 创建出来的用户过程。

它有三个关键属性：

- `formals`：形参列表
- `body`：函数体，是一个 Scheme 表达式列表
- `env`：定义这个函数时所在的环境

最关键的是最后这个 `env`。

它意味着 `lambda` 会记住“定义时的外层环境”，这就是词法作用域，也是闭包成立的原因。

比如：

```scheme
(define n 5)
(define add-n (lambda (x) (+ x n)))
```

这里 `add-n` 不只是“代码”而已，它还携带了定义时的环境信息。以后调用它时，即使当前别处也有同名变量 `n`，它仍然优先按词法作用域规则去找当时那条环境链。

### MuProcedure 是什么

`MuProcedure` 和 `LambdaProcedure` 很像，但它不保存定义时环境。

它只有：

- `formals`
- `body`

它的特别之处在于：调用时用的是“当前调用点所在环境”。

这就是动态作用域。

所以：

- `LambdaProcedure` 看定义位置
- `MuProcedure` 看调用位置

Problem 11 的重点就是把这两者区分清楚。

### Pair 是什么

虽然你这次主要在做解释器，但很多数据其实都是通过 `Pair` 表示的。

`Pair` 是 Scheme 链表在 Python 里的表示方式。比如：

```scheme
(+ 2 3)
```

读入解释器以后，不是 Python 的普通列表，而更接近：

```python
Pair('+', Pair(2, Pair(3, nil)))
```

这意味着：

- 一个 Scheme 表达式通常不是 Python list
- 你需要通过 `.first` 和 `.rest` 遍历它
- 很多题里都要处理 `Pair` 组成的链式结构

你可以把它简单理解为“解释器内部的链表节点”。

### 一次函数调用时，这些对象是怎么配合的

以这段代码为例：

```scheme
(define (square x) (* x x))
(square 5)
```

解释器内部大致会发生这些事：

1. `(define (square x) (* x x))` 被识别为特殊形式 `define`。
2. `do_define_form` 创建一个 `LambdaProcedure` 对象。
3. 这个对象里保存：
	- `formals = (x)`
	- `body = ((* x x))`
	- `env = 当前定义时环境`
4. 全局 `Frame` 把 `square` 绑定到这个 `LambdaProcedure`。
5. 执行 `(square 5)` 时，`scheme_eval` 先求值 `square`，得到这个过程对象。
6. 再求值参数 `5`。
7. `scheme_apply` 调用该过程，用 `make_child_frame` 创建新 Frame，并绑定 `x -> 5`。
8. 在这个新 Frame 中执行 `(* x x)`。
9. 查找 `x` 时先在当前 Frame 找到 `5`，最后得到结果 `25`。

如果你把这条流程看明白，后面大多数题都会自然很多。

### 可以把整个解释器先粗略理解成这几个层次

- `Pair`：负责表示 Scheme 的列表和组合式结构。
- `Frame`：负责保存变量绑定和作用域链。
- `Procedure` 及其子类：负责表示“可调用对象”。
- `scheme_eval`：负责判断一个表达式该怎么求值。
- `scheme_apply`：负责把一个过程应用到一组参数上。
- `scheme_forms.py`：负责处理 `define`、`lambda`、`let` 等特殊形式。

### 1.2 Python 部分：解释器内核

#### Problem 1: 环境帧的定义与查找

文件：`scheme_classes.py`

你要完成：

- `Frame.define(self, symbol, value)`
- `Frame.lookup(self, symbol)`

你需要做的事：

- 把符号绑定到当前环境帧的字典里。
- 在当前帧找不到符号时，沿着 `parent` 向上查找。
- 一直找不到时抛出 `SchemeError`。

这一题完成后，解释器才真正拥有“环境”这个概念，也就是变量名可以对应到具体值。

#### Problem 2: 内建过程调用

文件：`scheme_eval_apply.py`

你要完成：

- `scheme_apply` 中对 `BuiltinProcedure` 的处理。

你需要做的事：

- 把 Scheme 链表形式的参数 `args` 转成 Python 参数列表。
- 如果 `procedure.need_env` 为真，把当前环境也作为最后一个参数传进去。
- 正确调用 Python 函数。
- 只捕获参数数量不匹配导致的 `TypeError`，并转成 `SchemeError`。

这一题完成后，`+`、`-`、`car`、`cdr`、`length` 这类内建函数才能真正执行。

#### Problem 3: 组合式求值

文件：`scheme_eval_apply.py`

你要完成：

- `scheme_eval` 中普通组合式的求值逻辑。

你需要做的事：

- 先求值 operator。
- 再从左到右求值 operands。
- 最后把求值后的参数交给 `scheme_apply`。

这一题完成后，像 `(+ 2 3)`、`(* (+ 1 2) 4)` 这样的表达式就能跑通。

#### Problem 6: 顺序求值

文件：`scheme_eval_apply.py`

你要完成：

- `eval_all(expressions, env)`

你需要做的事：

- 依次求值一个表达式列表。
- 返回最后一个表达式的值。
- 空列表返回 `None`，表示 Scheme 里的 `undefined` 语义。

这一题会直接支持 `begin` 这种顺序执行结构。

#### Problem 8: 创建子环境

文件：`scheme_classes.py`

你要完成：

- `Frame.make_child_frame(formals, vals)`

你需要做的事：

- 创建当前环境的子帧。
- 把形式参数 `formals` 和实参 `vals` 一一绑定。
- 参数个数不一致时抛出 `SchemeError`。

这一题是函数调用真正成立的关键前提。

#### Problem 9: Lambda 过程调用

文件：`scheme_eval_apply.py`

你要完成：

- `scheme_apply` 中对 `LambdaProcedure` 的处理。

你需要做的事：

- 以 `procedure.env` 为父环境创建子帧。
- 把形参和实参绑定进去。
- 在新环境中执行函数体。

这一题完成后，闭包和词法作用域才会生效。

#### Problem 11: Mu 过程调用

文件：`scheme_eval_apply.py` 和 `scheme_forms.py`

你要完成：

- `do_mu_form`
- `scheme_apply` 中对 `MuProcedure` 的处理

你需要做的事：

- 构造 `MuProcedure` 对象。
- 调用时以“当前调用环境”作为父环境，而不是定义时环境。

这一题完成后，解释器会同时支持：

- `lambda` 的词法作用域
- `mu` 的动态作用域

这也是整个项目里最有区分度的一部分。

### 1.3 Python 部分：特殊形式

#### Problem 4: define 变量绑定

文件：`scheme_forms.py`

你要完成：

- `do_define_form` 中符号定义部分。

你需要做的事：

- 处理 `(define x expr)`。
- 先求值 `expr`，再把结果绑定给 `x`。
- 返回被定义的符号名。

#### Problem 5: quote

文件：`scheme_forms.py`

你要完成：

- `do_quote_form`

你需要做的事：

- 直接返回被引用的表达式本身，不进行求值。

完成后，`'hello`、`'(1 2 3)` 这种写法就会正常工作。

#### Problem 7: lambda

文件：`scheme_forms.py`

你要完成：

- `do_lambda_form`

你需要做的事：

- 校验形式参数。
- 构造并返回 `LambdaProcedure(formals, body, env)`。

#### Problem 10: define 的函数缩写形式

文件：`scheme_forms.py`

你要完成：

- `do_define_form` 中过程定义部分。

你需要做的事：

- 处理 `(define (f x y) body...)`。
- 本质上把它转换成：给 `f` 绑定一个 `LambdaProcedure`。

完成后你就可以写：

```scheme
(define (square x) (* x x))
```

而不是只能写：

```scheme
(define square (lambda (x) (* x x)))
```

#### Problem 12: and / or

文件：`scheme_forms.py`

你要完成：

- `do_and_form`
- `do_or_form`

你需要做的事：

- 实现短路求值。
- `and` 在遇到假值时立刻返回。
- `or` 在遇到真值时立刻返回。
- 没有表达式时返回各自的单位值。

这一题非常适合检查你是否真的理解了“特殊形式”和“普通函数调用”的区别。

#### Problem 13: cond

文件：`scheme_forms.py`

你要完成：

- `do_cond_form`

你需要做的事：

- 依次检查每个子句。
- 找到第一个测试结果为真值的子句后执行它。
- 支持 `else` 分支。
- 如果子句只有测试部分而没有 body，要返回测试值。

#### Problem 14: let

文件：`scheme_forms.py`

你要完成：

- `make_let_frame`

你需要做的事：

- 校验每个 binding 的格式。
- 在当前环境中计算各个绑定表达式。
- 收集名字和值。
- 创建新的子环境返回。

重点要注意：

- `let` 的每个右侧表达式都在“原环境”里求值。
- 不能边绑定边让后一个 binding 看到前一个 binding。
- 同名绑定、非法 binding 都要报错。

### 1.4 Scheme 部分：语言层函数

#### Problem 15: enumerate

文件：`questions.scm`

你要完成：

- `enumerate`

你需要做的事：

- 输入一个列表。
- 返回 `((索引 元素) ...)` 这种二元列表组成的列表。

示例：

```scheme
(enumerate '(a b c))
; => ((0 a) (1 b) (2 c))
```

#### Problem 16: merge

文件：`questions.scm`

你要完成：

- `merge`

你需要做的事：

- 输入一个比较函数 `ordered?` 和两个已按顺序排列的列表。
- 按相同顺序把它们归并成一个新列表。

示例：

```scheme
(merge < '(1 4 6) '(2 5 8))
; => (1 2 4 5 6 8)
```

### 1.5 可选题

#### Optional Problem 1: 尾递归优化

文件：`scheme_eval_apply.py`

这是解释器层面的进阶实现，目标是支持 proper tail recursion。

#### Optional Problem 2: let-to-lambda

文件：`questions.scm`

目标是把含有 `let` 的表达式转换成等价的 `lambda` 形式。

这两题不影响主线完成，但适合理解解释器设计和语法转换。

## 2. 推荐完成顺序

虽然题号基本按依赖关系设计，但你最好按下面顺序做，这样调试成本最低：

1. Problem 1：先让环境能定义和查找变量。
2. Problem 2：让内建函数调用起来。
3. Problem 3：让普通表达式求值跑起来。
4. Problem 4、5：先补最基础的特殊形式 `define` 和 `quote`。
5. Problem 6：支持顺序求值，为 `begin` 打基础。
6. Problem 7、8、9：完成 `lambda` 创建、调用环境构造和闭包调用。
7. Problem 10：补齐函数定义语法糖。
8. Problem 11：完成 `mu` 和动态作用域。
9. Problem 12、13、14：补完控制流与局部绑定。
10. Problem 15、16：最后写 `questions.scm` 里的 Scheme 函数。

## 3. 你主要会改哪些文件

### `scheme_classes.py`

负责环境和过程对象。

- `Frame` 是环境帧。
- `BuiltinProcedure` 包装 Python 内建函数。
- `LambdaProcedure` 表示词法作用域函数。
- `MuProcedure` 表示动态作用域函数。

### `scheme_eval_apply.py`

负责解释器最核心的“求值-应用”流程。

- `scheme_eval` 决定表达式怎么求值。
- `scheme_apply` 决定过程怎么调用。
- `eval_all` 负责顺序执行一串表达式。

### `scheme_forms.py`

负责所有特殊形式。

也就是那些“参数不是先全部求值再调用”的语言结构，比如：

- `define`
- `quote`
- `lambda`
- `and`
- `or`
- `cond`
- `let`
- `mu`

### `questions.scm`

这是用 Scheme 自己写 Scheme 函数的部分。前面 Python 实现的是解释器；这里实现的是运行在解释器上的 Scheme 程序。

## 4. 如何运行和测试

### 4.1 进入项目目录

在当前仓库根目录下执行。

Windows 常见用法：

```powershell
py ok -q 01
```

如果你的环境里 `python` 命令可用，也可以：

```powershell
python ok -q 01
```

### 4.2 按题测试

每做完一道题，立刻测对应编号：

```powershell
py ok -q 01
py ok -q 02
py ok -q 03
...
py ok -q 16
```

有些题是 Python 解释器部分，有些题是 Scheme 文件部分，但都能用 `ok` 测试系统统一验证。

### 4.3 跑整个项目测试

```powershell
py ok
```

如果你只想测试解释器核心，也可以跑默认测试中的某一组。

### 4.4 运行 Scheme 解释器

启动交互解释器：

```powershell
py scheme.py
```

启动后你可以手动输入：

```scheme
(+ 2 3)
(define x 10)
(* x 2)
(define (square n) (* n n))
(square 5)
```

### 4.5 加载 Scheme 文件

如果你想让解释器加载某个 `.scm` 文件再进入交互模式，可以使用：

```powershell
py scheme.py -i tests.scm
```

如果要测试你在 `questions.scm` 里写的函数，也可以在 REPL 中执行：

```scheme
(load 'questions)
(enumerate '(a b c))
(merge < '(1 3 5) '(2 4 6))
```

## 5. 完成后最终能实现什么效果

如果你把主线题全部完成，最终得到的不是“几个零散函数”，而是一个完整的、能交互运行的迷你 Scheme 解释器。

### 5.1 基础表达式求值

你将能够执行：

```scheme
scm> (+ 2 3)
5
scm> (* (+ 1 2) 4)
12
```

这说明：

- 符号查找正常
- 组合式求值正常
- 内建过程调用正常

### 5.2 变量与函数定义

你将能够执行：

```scheme
scm> (define x 10)
x
scm> x
10
scm> (define (square n) (* n n))
square
scm> (square 6)
36
```

这说明解释器已经支持：

- 名称绑定
- 匿名函数与具名函数
- 函数调用

### 5.3 闭包与词法作用域

你将能够写出依赖外层环境的函数：

```scheme
scm> (define n 5)
n
scm> (define add-n (lambda (x) (+ x n)))
add-n
scm> (add-n 7)
12
```

这表示 `lambda` 会记住定义时环境，也就是闭包语义已经成立。

### 5.4 特殊形式和控制流

你将能够使用：

```scheme
scm> (quote (1 2 3))
(1 2 3)
scm> (begin (define x 1) (+ x 2))
3
scm> (and 1 2 3)
3
scm> (or #f #f 42)
42
scm> (cond ((> 2 3) 5)
....       ((< 2 3) 6)
....       (else 7))
6
```

这说明解释器已经能处理“不按普通函数规则求值”的语法结构。

### 5.5 let 与局部作用域

你将能够执行：

```scheme
scm> (let ((x 5) (y 3)) (+ x y))
8
```

这说明局部环境构造正确，而且 binding 的求值时机也处理对了。

### 5.6 mu 与动态作用域

你将能够观察到 `mu` 和 `lambda` 的差异：

```scheme
scm> (define y 1)
scm> (define f (mu (x) (+ x y)))
scm> (define g (lambda (x y) (f (+ x x))))
scm> (g 3 7)
13
```

这里 `f` 中的 `y` 会从调用环境里找，而不是定义环境里找。这就是动态作用域。

### 5.7 Scheme 层函数

完成 `questions.scm` 后，你将能够执行：

```scheme
scm> (load 'questions)
scm> (enumerate '(a b c))
((0 a) (1 b) (2 c))
scm> (merge < '(1 4 6) '(2 5 8))
(1 2 4 5 6 8)
```

这说明你写出来的解释器已经足够强，可以运行你自己写的 Scheme 程序。

## 6. 做题时最容易出错的地方

### 参数求值与特殊形式混淆

普通函数调用会先求值所有参数；特殊形式不会。

例如：

- `(+ 1 2)` 会先求值 `+`、`1`、`2`
- `(and expr1 expr2)` 不一定会求值到 `expr2`
- `(quote x)` 不会对 `x` 求值

### `let` 的求值环境弄错

`let` 中右侧表达式都应该在旧环境中计算，不是在新环境中边定义边计算。这个错误非常常见。

### `lambda` 和 `mu` 的父环境弄反

- `lambda` 用定义时环境
- `mu` 用调用时环境

如果这两者写反，Problem 11 的行为会明显不对。

### 不要修改输入结构

多个测试都会检查表达式、参数列表、bindings 是否被意外修改。实现时尽量只遍历，不要原地改链表结构。

### 只捕获该捕获的异常

尤其是 `scheme_apply` 里调用 Python 内建函数时，只应把参数数量错误转成 `SchemeError`，不要把其他异常误吞掉。

## 7. 一份可执行的完成策略

如果你想高效做完，建议直接照这个节奏推进：

1. 打开 `scheme_classes.py`，完成 Problem 1 和 Problem 8。
2. 打开 `scheme_eval_apply.py`，完成 Problem 2、3、6。
3. 运行 `py ok -q 01` 到 `py ok -q 06`。
4. 打开 `scheme_forms.py`，完成 Problem 4、5、7、10。
5. 再完成 Problem 9 和 Problem 11，把函数调用和作用域跑通。
6. 运行 `py ok -q 07` 到 `py ok -q 11`。
7. 完成 Problem 12、13、14。
8. 运行 `py ok -q 12` 到 `py ok -q 14`。
9. 打开 `questions.scm`，完成 Problem 15、16。
10. 最后运行 `py ok` 做总测试。

## 8. 总结

这个项目的本质，是把你从“会写函数”推进到“理解一门语言是怎么运行的”。

你真正要完成的，不只是填空，而是逐步搭起下面这条链路：

- 表达式读取后如何区分类型
- 符号如何在环境中查找
- 普通过程如何求值并调用
- 特殊形式为什么不能按普通函数来处理
- 词法作用域和动态作用域的区别是什么
- Scheme 程序如何运行在你自己写的解释器上

如果主线全部完成，这个仓库最后会变成一个可以交互使用、支持核心特性的 Scheme 解释器，而不再只是课程骨架代码。