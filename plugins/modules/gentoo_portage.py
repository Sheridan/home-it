#!/usr/bin/python
# -*- coding: utf-8 -*-

from ansible.module_utils.basic import AnsibleModule
import os
import subprocess


def write_line(filepath, line, regexp, owner="portage"):
    """
    Добавляем или заменяем строку в конфигурационном файле
    """
    changed = False
    if os.path.exists(filepath):
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()
    else:
        lines = []

    found = False
    for i, l in enumerate(lines):
        if regexp in l:
            found = True
            if l.strip() != line.strip():
                lines[i] = line + "\n"
                changed = True
            break

    if not found:
        lines.append(line + "\n")
        changed = True

    if changed:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, "w", encoding="utf-8") as f:
            f.writelines(lines)
        try:
            import pwd
            uid = pwd.getpwnam(owner).pw_uid
            gid = pwd.getpwnam(owner).pw_gid
            os.chown(filepath, uid, gid)
        except Exception:
            pass

    return changed


def remove_line(filepath, regexp):
    """
    Удаление строки по regexp
    """
    if not os.path.exists(filepath):
        return False
    changed = False
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()
    new_lines = []
    for l in lines:
        if regexp in l:
            changed = True
            continue
        new_lines.append(l)
    if changed:
        with open(filepath, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
    return changed


def run_emerge(package, state, newuse=True, update=True):
    """
    Установка/удаление пакета через emerge
    """
    if state == "present":
        cmd = ["emerge", "--quiet"]
        if newuse:
            cmd.append("--newuse")
        if update:
            cmd.append("--update")
        cmd.append(package)
    elif state == "absent":
        cmd = ["emerge", "--quiet", "--unmerge", package]
    else:
        return False, "Invalid state"

    result = subprocess.run(cmd, capture_output=True, text=True)
    return (result.returncode == 0), result.stdout + result.stderr


def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type="str", required=True),
            state=dict(type="str", default="present", choices=["present", "absent"]),
            unstable=dict(type="bool", default=False),
            x86_as_amd64=dict(type="bool", default=False),
            use=dict(type="dict", required=False, default={}),
        ),
        supports_check_mode=True
    )

    params = module.params
    name = params["name"]
    category = name.split("/")[0]
    state = params["state"]
    unstable = params["unstable"]
    x86_as_amd64 = params["x86_as_amd64"]
    use = params["use"] or {}

    arch = "amd64" if os.uname().machine == "x86_64" else "x86"
    changed = False
    msgs = []

    # --- USE FLAGS ---
    use_file = f"/etc/portage/package.use/{category}"
    disabled_flags = ["-" + f for f in use.get("disabled", [])]
    enabled_flags = use.get("enabled", [])
    all_flags = disabled_flags + enabled_flags

    if state == "present" and all_flags:
        line = "{} {}".format(name, " ".join(all_flags))
        changed |= write_line(use_file, line, name)
        msgs.append("USE flags updated")
    else:
        changed |= remove_line(use_file, name)
        msgs.append("USE flags removed")

    # --- KEYWORDS (unstable/arch override) ---
    kw_file = f"/etc/portage/package.accept_keywords/{category}"
    if state == "present" and (unstable or (x86_as_amd64 and arch == "x86")):
        line = "{} {}".format(name, ("~" if unstable else "") + ("amd64" if x86_as_amd64 and arch == "x86" else (arch if unstable else "")))
        changed |= write_line(kw_file, line, name)
        msgs.append("Keyword flags updated")
    else:
        changed |= remove_line(kw_file, name)
        msgs.append("Keyword flags removed")

    # --- EMERGE ---
    if not module.check_mode:
        ok, out = run_emerge(name, state)
        msgs.append(out)
        if not ok:
            module.fail_json(msg="Emerge failed", output=out)

    module.exit_json(changed=changed, msg="\n".join(msgs))


if __name__ == "__main__":
    main()
