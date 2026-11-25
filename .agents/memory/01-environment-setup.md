# 开发环境搭建与验证

- 日期：2026-11-25
- 状态：已完成，可用于开发

## 目标

在不使用 Docker 的 macOS（Apple M2）上搭建 ROSplat 开发环境，并验证渲染与 ROS 2 链路。

## 已完成

- 仓库：`~/Workspace/ROSplat`，子模块 `external/spirula-studio` 固定到 `8509253`。
- uv 环境：`pyproject.toml` + `uv.lock`，`.venv/` 内为 Python 3.12。
- 原生库：`build-native/librosplat_spirula.dylib`，MoltenVK 1.4.2，Apple M2 可用。
- pixi 环境：`pixi.toml` + `pixi.lock`，ROS 2 Jazzy（RoboStack）+ colcon + GUI 依赖。
- ROS 消息：`gaussian_interface` 构建到 `build-ros/` 与 `install-ros/`。
- 单元测试：pixi 环境下 15/15 通过。
- 端到端：2000 个 Gaussian 经 `GaussianArray` 话题进入 `WorldSettings`，Spirula 渲染出 1280×720 RGBA。
- GUI：pixi 环境下可启动，wgpu Metal + Spirula MoltenVK 正常初始化。

## 关键决策

- 公司内网 conda 代理没有 RoboStack（空 repodata），pixi 的 ROS 2 频道临时使用外部 `prefix.dev/robostack-jazzy`。
- `imgui-bundle` 必须 `>=1.93.0`，否则 `wgpu==0.32.0` 访问 `ImDrawData.cmd_lists_count` 时报错。
- macOS 上 wgpu 走 Metal，Spirula 走 MoltenVK；二者通过 CPU RGBA8 buffer 交互，不共享 Vulkan 纹理。

## 2026-11-25 仓库清理

- 删除所有 `__pycache__` 与 `log/`（colcon 日志），未提交任何缓存文件。
- `requirements.txt` 移至 `docker/requirements.txt`，同步更新 `docker/Dockerfile`、`.dockerignore`、docs 与 rules；根目录不再保留该文件。
- `.gitignore` 重写：统一忽略 `build*/`、`install*/`、`log/`、`.venv/`、`.pixi/`、Python 缓存与编译产物；`imgui.ini` 取消跟踪（文件保留在磁盘），仅保留源码、文档与数据。
- `__init__.py` 全部保留：7 个子包含 re-export，顶层 `rosplat/__init__.py` 虽为空但作为包标记保留。
- 全局 gitignore 的 `core` 规则会误伤 `rosplat/core/`，已在仓库 `.gitignore` 中用 `!rosplat/core/**` 显式恢复。

## 常用命令

```bash
cd ~/Workspace/ROSplat
uv sync --frozen
pixi install
./scripts/build_ros_msgs.sh
./scripts/run_ros2.sh
./scripts/stream_ply.sh /tmp/rosplat_synthetic.ply /gaussian_test
```

## 待办 / 注意

- ROS 2 版本是 Jazzy，不是上游的 Lyrical。
- `Frames` / `IMU` 尚无真实传感器驱动。
- 内网 RoboStack 补齐后，应把 `pixi.toml` 频道切回内网。
- 仓库外的旧环境 `~/Workspace/rosplat-ros2-pixi` 已不再需要，确认后可清理。
