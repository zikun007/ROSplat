# 项目规范整理（草案）

- 状态：草案，待主人审核
- 审核通过后移动到 `.agents/project/01-project-standards.md`

## 1. `<workspace>` 约定

本文中的 `<workspace>` 指仓库根目录 `~/Workspace/ROSplat`。
所有项目级数据放在仓库内，便于随 git 一起版本化。

## 2. 目录结构

```text
<workspace>/
├── .agents/
│   ├── memory/     # 开发进度、bug、调试记录，01-*.md 编号
│   ├── project/    # 审核通过的项目方案，01-*.md 编号
│   └── rules/      # 语言/流程规范，01-*.md 编号
├── docs/           # 草案与说明文档，01-*.md 编号
├── scripts/        # 可复现的开发/运行脚本
├── pyproject.toml  # uv 依赖声明
├── uv.lock
├── pixi.toml       # ROS 2 / colcon / GUI 环境
└── pixi.lock
```

`docs/pdf/` 为上游技术报告，保留原状，不参与编号。

## 3. 工作流

1. 新需求先在 `docs/NN-<description>.md` 写草案。
2. 方案经主人审核后，移入 `.agents/project/NN-<description>.md`。
3. 开发过程在 `.agents/memory/NN-<description>.md` 记录进度、bug 和验证结果。
4. memory 过长时删除最旧文件并重新编号；需要长期保留的内容移入 `.agents/project/`。
5. 语言与流程规范放在 `.agents/rules/NN-<description>.md`。

## 4. 环境管理

- Python 依赖：`pyproject.toml` 为准，`uv.lock` 锁定；使用 `uv sync --frozen`。
- ROS 2 / colcon / GUI 依赖：`pixi.toml` 为准，`pixi.lock` 锁定；使用 `pixi install`。
- `docker/requirements.txt` 与 `pyproject.toml` 的版本保持一致，兼容上游 Docker 流程。
- 构建产物与虚拟环境不进入 git。

## 5. 提交规范

- 使用 Conventional Commits：`<type>(<scope>): <summary>`。
- 一个提交一个逻辑改动。
- 提交前必须展示 `git status`、`git diff --stat` 和提交信息，经主人批准后执行。
- 禁止未经确认的 `push`、`reset --hard`、`clean -fd`。

## 6. 当前环境事实

- macOS 使用 uv（PLY 模式）与 pixi（ROS 2 Jazzy）。
- 内网 conda 代理没有 RoboStack，pixi 临时使用外部 `prefix.dev`。
- `imgui-bundle` 必须 `>=1.93.0`。
- 详细步骤见 `docs/01-macos-dev.md`。
