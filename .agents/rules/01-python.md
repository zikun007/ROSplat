# Python 开发规范

适用于 `rosplat/`、`tests/`、`misc/` 下的 Python 代码。

## 版本与依赖

- 固定 Python 3.12，不使用 3.13+ 语法。
- 新增运行时依赖时，同时更新 `pyproject.toml`、`docker/requirements.txt` 和 `pixi.toml`，并重新生成 `uv.lock` / `pixi.lock`。
- 不提交 `.venv/`、`.pixi/`、`build-native/`、`build-ros/`、`install-ros/`。

## 代码风格

- 4 空格缩进，模块/函数/变量使用 `snake_case`，类使用 `PascalCase`。
- 新增公共函数和方法写类型标注；短小的内部回调可以省略。
- 遵循现有模块结构：`core` 放数据与工具，`render` 放渲染，`gui` 放 ImGui，`ros` 放 ROS 接口。
- 不使用裸 `except:`；捕获具体异常并记录上下文。

## ROS 与 macOS 兼容

- ROS 相关导入必须允许缺失：使用 `try/except ImportError` 或延迟导入，保证 PLY-only 模式可运行。
- 不在模块顶层强制 `rclpy.init()`；由 `ROSNodeManager` 或 `main()` 负责生命周期。
- 线程间共享数据使用 `queue` / `threading.Lock`，不要在 ROS 回调线程直接操作 ImGui。

## 日志与测试

- 统一使用 `rosplat.core.util.logger`，不要用 `print` 输出运行日志。
- 新功能在 `tests/` 下补 `unittest` 用例，保持无 ROS 环境下可单独运行；需要 ROS 的测试显式导入并在 pixi 环境执行。
- 提交前至少运行：

```bash
pixi run bash -lc 'source install-ros/setup.bash && python -m unittest discover -s tests -v'
```

## 原生渲染边界

- `SpirulaRenderer` 通过 ctypes 调用 `librosplat_spirula`，新增 C 函数时同步维护 `argtypes` / `restype`。
- 渲染结果通过调用方持有的 CPU RGBA8 buffer 返回，不假设与 wgpu 共享 Vulkan 设备。
