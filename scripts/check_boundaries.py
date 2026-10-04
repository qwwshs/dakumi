"""静态边界检查：插件 UI 上下文与下层模块的依赖方向。"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
failures = []
for path in (ROOT / "plugins").rglob("*.lua"):
    source = path.read_text(encoding="utf-8")
    for line, text in enumerate(source.splitlines(), 1):
        if not text.lstrip().startswith("--") and re.search(r"(?<![\w.])Nui\s*:", text):
            failures.append(f"{path.relative_to(ROOT)}:{line}: 插件必须通过 ctx.ui 调用 UI")
for directory in ("src/models",):
    for path in (ROOT / directory).rglob("*.lua"):
        if re.search(r"require\s*\(?\s*['\"]src\.(services|objects|core)\.", path.read_text(encoding="utf-8")):
            failures.append(f"{path.relative_to(ROOT)}: 数据模型引用了上层模块")
for name in ("event", "note", "track"):
    path = ROOT / f"src/utils/{name}.lua"
    if re.search(r"require\s*\(?\s*['\"]src\.services\.", path.read_text(encoding="utf-8")):
        failures.append(f"{path.relative_to(ROOT)}: 工具模块引用了服务层")
for failure in failures:
    print(failure)
print(f"静态边界检查：{len(failures)} 个问题")
sys.exit(bool(failures))
