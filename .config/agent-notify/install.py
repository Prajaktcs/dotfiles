#!/usr/bin/env python3
"""Build the macOS notifier locally; does not download code or modify Claude settings."""
import os
from pathlib import Path
import platform
import plistlib
import shutil
import subprocess

source = Path(__file__).resolve().parent
home = Path.home()
root = home / '.local/share/agent-notify'
app = root / 'Agent Notify.app'
contents = app / 'Contents'
binary = contents / 'MacOS/AgentNotify'
binary.parent.mkdir(parents=True, exist_ok=True)
sdk = subprocess.check_output(['xcrun', '--show-sdk-path'], text=True).strip()
subprocess.run(['xcrun', 'swiftc', '-sdk', sdk, '-target',
                f'{platform.machine()}-apple-macosx14.0', str(source / 'AgentNotify.swift'),
                '-o', str(binary), '-framework', 'AppKit', '-framework', 'UserNotifications'], check=True)
with (contents / 'Info.plist').open('wb') as output:
    plistlib.dump({
        'CFBundleIdentifier': 'local.dotfiles.agent-notify',
        'CFBundleName': 'Agent Notify', 'CFBundleExecutable': 'AgentNotify',
        'CFBundlePackageType': 'APPL', 'CFBundleVersion': '1', 'LSUIElement': True,
        'CFBundleURLTypes': [{'CFBundleURLName': 'Local agent notifications',
                             'CFBundleURLSchemes': ['local-agent-notify']}],
    }, output)
subprocess.run(['codesign', '--force', '--sign', '-', str(app)], check=True)
subprocess.run(['/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister', '-f', str(app)], check=True)
launcher = home / '.local/bin/agent-notify'
launcher.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(source / 'agent-notify', launcher)
launcher.chmod(0o755)
hook = home / '.omp/agent/hooks/post/agent-notify.js'
hook.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(source / 'omp-hook.js', hook)
print('Installed Agent Notify and the omp hook. Merge claude-hooks.json into Claude settings.')
print('Enable Agent Notify in System Settings > Notifications, then restart your agents.')
