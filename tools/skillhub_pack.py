from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 4:
        raise SystemExit(
            "用法：skillhub_pack.py <SkillHub CLI> <Skill目录> <输出ZIP>"
        )
    cli_path = Path(sys.argv[1]).resolve()
    skill_dir = Path(sys.argv[2]).resolve()
    zip_path = Path(sys.argv[3]).resolve()
    sys.path.insert(0, str(cli_path.parent))
    spec = importlib.util.spec_from_file_location("skillhub_cli", cli_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"无法加载 SkillHub CLI：{cli_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.pack_skill_zip(skill_dir, zip_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
