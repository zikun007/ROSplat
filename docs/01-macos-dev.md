# macOS（Apple Silicon）本地开发环境

上游只支持 Ubuntu 26.04 + ROS 2 Lyrical + Docker。本机（macOS 27.2 / Apple M2）
已经验证两条可用的开发路径：

1. **uv 环境 + 原生 Spirula/MoltenVK**：PLY 离线查看，最低依赖。
2. **pixi 环境 + ROS 2 Jazzy（RoboStack）**：完整 ROS 2 消息链路，
   但仍不是上游指定的 ROS 2 Lyrical。

所有环境配置都在仓库根目录，不再依赖仓库外的目录。

## 配置文件

| 文件 | 作用 |
| --- | --- |
| `pyproject.toml` | uv 的 Python 依赖声明（替代手工 `uv pip install`） |
| `uv.lock` | uv 锁文件，`uv sync --frozen` 可复现 `.venv` |
| `docker/requirements.txt` | 上游 Docker 使用的依赖清单，与 pyproject 保持一致 |
| `pixi.toml` | ROS 2 Jazzy、colcon、GUI 依赖 |
| `pixi.lock` | pixi 锁文件 |

生成的 `.venv/`、`.pixi/`、`build-native/`、`build-ros/`、`install-ros/`
都已在 `.gitignore` 中。

## 路径 A：uv + PLY 离线模式

```bash
cd ~/Workspace/ROSplat

# 创建/同步 Python 环境（首次会创建 .venv）
uv sync --frozen

# 构建原生 Spirula/MoltenVK 桥
cmake -S . -B build-native -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build-native --target rosplat_spirula

# 运行
.venv/bin/python -m rosplat.main
```

首次 `cmake` 配置会下载固定版本的 Slang 编译器（2026.12.1）和 MoltenVK 1.4.2，
并编译 692 个 SPIR-V shader，耗时较长；之后增量构建很快。
macOS 产物是 `librosplat_spirula.dylib`，加载器也可以被
`ROSPLAT_SPIRULA_LIBRARY=/path/to/librosplat_spirula.dylib` 覆盖。

## 路径 B：pixi + ROS 2 Jazzy

### 源说明

- 公司内网 Artifactory 代理**没有** RoboStack：`robostack-jazzy` 等频道返回空
  repodata（0 包 / 404）。conda-forge 等普通频道正常。
- 当前 `pixi.toml` 临时使用外部 `https://prefix.dev/robostack-jazzy`，
  conda 依赖走内网 conda-forge 代理。
- 若后续内网代理补齐 RoboStack，把 `pixi.toml` 中的频道换回
  `conda-proxy-custom_channels/robostack-jazzy` 即可。

### 安装环境

```bash
cd ~/Workspace/ROSplat
pixi install
```

关键依赖：`ros-jazzy-ros-base`、`rclpy`、`sensor-msgs`、`geometry-msgs`、
`rosidl-default-generators/runtime`、`rmw-cyclonedds-cpp`、`colcon-common-extensions`、
`cmake/ninja/cxx-compiler`，以及 `imgui-bundle==1.93.0`、`pyglfw`、`pyglm`、`pillow`；
PyPI 侧为 `wgpu==0.32.0`、`rendercanvas`、`plyfile`、`loguru`。

### 构建 ROS 消息

ROSplat 根目录本身有一个 CMake 包，colcon 默认不会下钻到 `gaussian_interface`，
必须显式指定 `--base-paths`：

```bash
cd ~/Workspace/ROSplat
pixi run bash -lc '
  colcon build --base-paths gaussian_interface \
    --packages-select gaussian_interface \
    --build-base build-ros --install-base install-ros \
    --event-handlers console_direct+
'
```

### 运行 GUI（ROS 2 可用）

```bash
cd ~/Workspace/ROSplat
pixi run bash -lc '
  source install-ros/setup.bash
  PYTHONPATH=$PWD:$PYTHONPATH python -m rosplat.main
'
```

或直接使用脚本：

```bash
./scripts/run_ros2.sh
```

### 端到端验证

终端 1 发布合成 PLY：

```bash
cd ~/Workspace/ROSplat
pixi run bash -lc '
  source install-ros/setup.bash
  python misc/generate_gaussian_bag.py \
    --ply-path /tmp/rosplat_synthetic.ply \
    --topic /gaussian_test --batch-size 500 --rate 10
'
```

或：

```bash
./scripts/stream_ply.sh /tmp/rosplat_synthetic.ply /gaussian_test
```

终端 2 在 GUI 的 Streams 标签页订阅 `/gaussian_test`。已用无 GUI 脚本验证：
2000 个 Gaussian 通过 4 个 `GaussianArray` 批次进入 `WorldSettings`，
再由 Spirula 渲染为 1280×720 RGBA 图像。

### 测试

```bash
cd ~/Workspace/ROSplat
pixi run bash -lc '
  source install-ros/setup.bash
  python -m unittest discover -s tests -v
'
```

pixi 环境下 15/15 全部通过；uv 环境下因没有 `rclpy`，有 2 个测试模块无法导入。

## 版本注意：imgui-bundle 必须是 1.93.0+

上游 `docker/requirements.txt` 固定 `imgui-bundle==1.92.900`，但 `wgpu==0.32.0` 的
ImGui 后端会访问 `ImDrawData.cmd_lists_count`，1.92.900 只暴露 `cmd_lists`，
导致 GUI 每帧 `AttributeError`。将 `imgui-bundle` 升到 `1.93.0` 后正常。
`pyproject.toml`、`docker/requirements.txt` 与 pixi env 均已按 1.93.0 配置。

## 本地兼容性补丁（相对上游 `8509253`）

1. `rosplat/main.py`
   - macOS 上默认 `WGPU_BACKEND_TYPE=Metal`（wgpu-py 的 macOS wheel 只带 Metal）。
   - `rclpy` 改为可选导入，缺失时不初始化/关闭 ROS。
   - 后端检查在 Darwin 上放行 Metal。

2. `rosplat/gui/imgui_manager.py`
   - `rosplat.ros` 导入失败时使用 `_NullROSNodeManager`，Streams 标签页显示空列表。

3. `rosplat/config/world_settings.py`
   - `gaussian_interface.msg` 不存在时用占位类，PLY 路径不依赖 ROS 消息。

4. `rosplat/render/renderer/SpirulaRenderer.py`
   - 原生库候选路径增加 `.dylib`。

### 为什么 Metal + MoltenVK 可以共存

两者**不共享** Vulkan 设备或纹理：Spirula 渲染到调用方提供的 CPU RGBA8 buffer
（`rosplat_spirula_render_rgba8`），Python 侧再用 wgpu 把它上传成 ImGui 纹理。
因此 wgpu 走 Metal、Spirula 走 MoltenVK 不会冲突。

## 无 GUI 的自检

```python
import numpy as np
from PIL import Image
from rosplat.config.world_settings import WorldSettings
from rosplat.core.gaussian_representation import from_ply

ws = WorldSettings()
g = from_ply("/path/to/scene.ply")
ws.gaussian_set = g
ws._gaussian_count = len(g)
ws._full_scene_dirty = True
ws.create_gaussian_renderer(None)          # 不经过 GUI/纹理注册表

rgba = ws.gauss_renderer.render_rgba8()
print(ws.gauss_renderer.device_name, ws.gauss_renderer.splat_count, rgba.shape)
Image.fromarray(rgba, mode="RGBA").save("/tmp/render.png")
ws.shutdown()
```

合成 PLY 的最小字段集：`x y z f_dc_0 f_dc_1 f_dc_2 opacity scale_0..2 rot_0..3`
（SH degree 0 即 `sh_dim=3`）。

## 限制

- 当前 ROS 2 版本是 **Jazzy**，不是上游文档的 Lyrical；ROSplat 用到的
  `rclpy` / `sensor_msgs` / `geometry_msgs` API 在两者间基本一致，但上游没有在
  Jazzy 上验证过。
- pixi 的 ROS 2 频道是外部 `prefix.dev`，仅作临时开发环境；合规要求严格时应
  等内网 Artifactory 补齐 RoboStack。
- `Frames` / `IMU` 标签页的代码路径已经可用，但 macOS 没有相机/IMU 驱动，
  需要自己发布 `sensor_msgs/Image`、`sensor_msgs/Imu` 话题。
- 需要与上游完全一致的 ROS 2 Lyrical + Vulkan 环境时，仍应使用 Linux x86_64
  + Vulkan 1.2 GPU 和 README 的 Docker 路径。

## 公司内网 conda 源（已配置）

`~/.condarc` 指向 Artifactory 代理：

```yaml
channels:
  - defaults
  - conda-forge
show_channel_urls: true
default_channels:
  - https://art-internal.hobot.cc/artifactory/api/conda/conda-proxy
custom_channels:
  conda-forge: https://art-internal.hobot.cc/artifactory/api/conda/conda-proxy-custom_channels
channel_priority: strict
auto_activate: false
remote_read_timeout_secs: 30.0
use_only_tar_bz2: false
```

注意该代理只缓存 `.conda` 包、首次拉取可能较慢；不要加清华源。
Python 包也可以走 `https://pypi.hobot.cc/simple`。
