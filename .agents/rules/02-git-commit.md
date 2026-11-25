# Git 提交规范

## 提交前审批

- 任何 `git commit` 之前必须先向主人展示 `git status`、`git diff --stat` 和拟用的提交信息，获得明确同意后再执行。
- 不执行 `git push`、`git reset --hard`、`git clean -fd` 等高风险操作，除非主人单独确认。

## 提交信息格式

采用 Conventional Commits：

```text
<type>(<scope>): <summary>

<optional body>

<optional footer>
```

- `type`：`feat`、`fix`、`docs`、`build`、`chore`、`refactor`、`test`。
- `scope`：`gui`、`render`、`ros`、`env`、`docs`、`tests` 等。
- `summary` 用祈使句，英文，尽量不超过 72 字符。
- body 说明“为什么”，不要重复 diff 内容。
- 一个提交只做一个逻辑改动；环境配置、文档、代码修复分开提交。

示例：

```text
build(env): add uv and pixi manifests for macOS development

fix(gui): require imgui-bundle 1.93 for wgpu draw data

docs(macos): document ROS 2 Jazzy and native rendering setup
```

## 不提交的内容

- `.venv/`、`.pixi/`、`build-native/`、`build-ros/`、`install-ros/`
- 运行生成的 `imgui.ini` 布局变化（如无功能意义）
- 包含本机绝对路径或密钥的临时配置
