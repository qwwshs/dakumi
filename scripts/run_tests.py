"""回归入口：LuaJIT 独立进程，或 Windows LÖVE 自带的 LuaJIT 动态库。"""
import argparse
import ctypes
import os
from pathlib import Path
import shutil
import subprocess
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
INTEGRATION = ("safe_input_love", "chart_change_love", "audio_service_love", "bpm_love", "spectrogram_love", "keybinding_love", "track_filter_love", "takana_import_love")
UI = ("editor_input_love",)

def library_case(library, path, syntax=False):
    lua = ctypes.CDLL(str(library))
    lua.luaL_newstate.restype = ctypes.c_void_p
    lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
    lua.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
    lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    lua.lua_tolstring.restype = ctypes.c_char_p
    lua.lua_close.argtypes = [ctypes.c_void_p]
    state = lua.luaL_newstate()
    if not state:
        raise RuntimeError("LuaJIT 状态创建失败")
    try:
        lua.luaL_openlibs(state)
        result = lua.luaL_loadfile(state, str(path).encode("utf-8"))
        if not result and not syntax:
            result = lua.lua_pcall(state, 0, -1, 0)
        if result:
            print(lua.lua_tolstring(state, -1, None).decode("utf-8", errors="replace"))
        return result
    finally:
        lua.lua_close(state)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua", default=shutil.which("luajit"))
    parser.add_argument("--lua-library", default=os.environ.get("DAKUMI_LUA_LIBRARY"))
    parser.add_argument("--love", default=shutil.which("love"))
    parser.add_argument("--integration", action="store_true")
    parser.add_argument("--ui", action="store_true")
    parser.add_argument("--syntax", action="store_true")
    parser.add_argument("--case", help=argparse.SUPPRESS)
    args = parser.parse_args()
    os.chdir(ROOT)
    if not args.lua_library and os.name == "nt":
        candidate = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "LOVE/lua51.dll"
        if candidate.is_file():
            args.lua_library = str(candidate)
    if args.case:
        return library_case(args.lua_library, args.case, args.syntax)
    if not args.lua and not args.lua_library:
        parser.error("需要 LuaJIT 命令或 --lua-library 指定的 LuaJIT 动态库")
    if (args.integration or args.ui) and not args.love:
        parser.error("集成测试需要 --love 指定 LÖVE 程序")
    (ROOT / ".zcode").mkdir(exist_ok=True)
    if args.syntax:
        tracked = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z", "*.lua"], text=True, encoding="utf-8")
        cases = sorted(set(filter(None, tracked.split("\0"))))
    else:
        cases = [str(p.relative_to(ROOT)) for p in sorted((ROOT / "tests").glob("*.lua"))]
    failures = []
    for case in cases:
        if args.lua:
            command = [args.lua, case]
            # -e 后的文件会被 LuaJIT 当主程序执行；语法检查仅通过环境传入路径。
            if args.syntax:
                command = [args.lua, "-e", "assert(loadfile(os.getenv('DAKUMI_SYNTAX_FILE')))" ]
        else:
            command = [sys.executable, str(Path(__file__).resolve()), "--lua-library", args.lua_library, "--case", case]
            if args.syntax:
                command.append("--syntax")
        env = dict(os.environ, DAKUMI_SYNTAX_FILE=case, ALSOFT_DRIVERS="null")
        result = subprocess.run(command, env=env, timeout=120)
        if result.returncode:
            failures.append(case)
    integration_count = 0
    if not args.syntax:
        for case in (INTEGRATION if args.integration else ()) + (UI if args.ui else ()):
            integration_count += 1
            print("LÖVE:", case, flush=True)
            try:
                result = subprocess.run([args.love, str(ROOT / "tests" / case)], env=dict(os.environ, ALSOFT_DRIVERS="null"), timeout=180)
                if result.returncode:
                    failures.append(case)
            except subprocess.TimeoutExpired:
                failures.append(case + " (超时)")
    print(f"{'语法检查' if args.syntax else '回归测试'}: {len(cases)} 个 Lua 文件，{integration_count} 个 LÖVE 测试；失败 {len(failures)} 项", flush=True)
    for failure in failures:
        print("FAIL:", failure)
    return bool(failures)

if __name__ == "__main__":
    sys.exit(main())
