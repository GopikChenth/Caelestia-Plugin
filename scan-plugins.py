#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "caelestia"
PLUGINS_DIR = CONFIG_DIR / "plugins"

# Discovery directories for plugins
PLUGIN_DIRS = [PLUGINS_DIR]

# Optional development / extra directories if they exist
env_plugins_dir = os.environ.get("CAELESTIA_PLUGINS_DIR")
if env_plugins_dir and Path(env_plugins_dir).exists():
    PLUGIN_DIRS.append(Path(env_plugins_dir))

dev_plugins_dir = Path.home() / "Projects" / "Caelestia Plugins"
if dev_plugins_dir.exists() and dev_plugins_dir not in PLUGIN_DIRS:
    PLUGIN_DIRS.append(dev_plugins_dir)

STATE_FILE = CONFIG_DIR / "plugins-state.json"

def ensure_plugin_links():
    """Ensure any plugins in auxiliary folders are symlinked to config/plugins for unified resolution."""
    PLUGINS_DIR.mkdir(parents=True, exist_ok=True)
    for extra_dir in PLUGIN_DIRS:
        if extra_dir == PLUGINS_DIR or not extra_dir.exists():
            continue
        for p in extra_dir.iterdir():
            if p.is_dir() and (p / "manifest.json").exists():
                link_target = PLUGINS_DIR / p.name
                if not link_target.exists():
                    try:
                        link_target.symlink_to(p, target_is_directory=True)
                    except Exception:
                        pass

def get_enabled_state() -> dict:
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except Exception:
            return {}
    return {}

def save_enabled_state(state: dict):
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2))

def list_plugins():
    ensure_plugin_links()
    plugins = []
    seen = set()
    states = get_enabled_state()

    for d in PLUGIN_DIRS:
        if not d.exists():
            continue
        for p in d.iterdir():
            if not p.is_dir():
                continue
            manifest_file = p / "manifest.json"
            if manifest_file.exists():
                try:
                    manifest = json.loads(manifest_file.read_text())
                    plugin_id = manifest.get("id", p.name)
                    if plugin_id in seen:
                        continue
                    seen.add(plugin_id)

                    # State override if stored
                    enabled = states.get(plugin_id, manifest.get("enabled", True))

                    manifest["id"] = plugin_id
                    manifest["dirName"] = p.name
                    manifest["path"] = str(p.resolve())
                    manifest["enabled"] = enabled
                    manifest["settingsFile"] = manifest.get("entryPoints", {}).get("settings", "Settings.qml")
                    plugins.append(manifest)
                except Exception:
                    pass

    print(json.dumps(plugins, indent=2))

def toggle_plugin(plugin_id: str, enabled_str: str):
    enabled = enabled_str.lower() in ("true", "1", "yes")
    states = get_enabled_state()
    states[plugin_id] = enabled
    save_enabled_state(states)
    list_plugins()

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "toggle" and len(sys.argv) > 3:
        toggle_plugin(sys.argv[2], sys.argv[3])
    elif len(sys.argv) > 1 and sys.argv[1] == "open-dir":
        PLUGINS_DIR.mkdir(parents=True, exist_ok=True)
        os.system(f"xdg-open '{PLUGINS_DIR}' &")
    else:
        list_plugins()

if __name__ == "__main__":
    main()
