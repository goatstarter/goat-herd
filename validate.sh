#!/usr/bin/env bash
# Goat Pack Standard v1 validator.
#
# Structural check for a goat-* pack. No network, no dependencies beyond bash and
# python3. Writes nothing. Exits 0 when the pack is publishable.
#
# Usage:
#   ./validate.sh              # validate the pack this script sits in
#   ./validate.sh /path/to/pack
#   ./validate.sh --quiet      # errors only, no warnings
set -uo pipefail

PACK_DIR="$(cd "$(dirname "$0")" && pwd)"
QUIET=0
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=1 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) PACK_DIR="$(cd "$arg" 2>/dev/null && pwd)" || { echo "no such directory: $arg" >&2; exit 2; } ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 2; }

PACK_DIR="$PACK_DIR" QUIET="$QUIET" python3 - <<'PY'
import json, os, re, sys

try:
    import yaml  # optional: enables a real YAML parse of the frontmatter
except ImportError:
    yaml = None

pack_dir = os.environ["PACK_DIR"]
quiet = os.environ["QUIET"] == "1"
pack_name = os.path.basename(pack_dir)

errors, warnings = [], []
def err(m): errors.append(m)
def warn(m): warnings.append(m)

def read(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except OSError:
        return None

# ---------------------------------------------------------------- required files
REQUIRED = [
    ".claude-plugin/plugin.json",
    ".claude-plugin/marketplace.json",
    "AGENTS.md",
    "README.md",
    "VERSIONS.md",
    "LICENSE",
    "install.sh",
]
for rel in REQUIRED:
    if not os.path.exists(os.path.join(pack_dir, rel)):
        err(f"missing required file: {rel}")

# Every pack ships both languages. English-first packs pair README.md with README.tr.md;
# Turkish-first packs (goat-quill, goat-kid) pair a Turkish README.md with README.en.md.
readmes = [f for f in ("README.md", "README.tr.md", "README.en.md")
           if os.path.exists(os.path.join(pack_dir, f))]
if "README.tr.md" not in readmes and "README.en.md" not in readmes:
    err("missing the second-language README: add README.tr.md, or README.en.md for a Turkish-first pack")

skills_dir = os.path.join(pack_dir, "skills")
if not os.path.isdir(skills_dir):
    err("missing required directory: skills/ (skills.sh cannot index a pack without it)")
    skill_names = []
else:
    skill_names = sorted(
        d for d in os.listdir(skills_dir)
        if os.path.isdir(os.path.join(skills_dir, d)) and not d.startswith(".")
    )
    if not skill_names:
        err("skills/ contains no skill directories")

# ------------------------------------------------------------------- frontmatter
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

def parse_frontmatter(text, label):
    """Minimal YAML reader for the flat shape the standard mandates."""
    if not text.startswith("---\n"):
        err(f"{label}: does not open with a --- frontmatter fence")
        return None
    end = text.find("\n---", 4)
    if end == -1:
        err(f"{label}: frontmatter fence is never closed")
        return None
    data, current = {}, None
    for raw in text[4:end].split("\n"):
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indented = raw[:1] in (" ", "\t")
        if ":" not in raw:
            err(f"{label}: frontmatter line is not key: value -> {raw.strip()[:60]}")
            continue
        key, _, value = raw.partition(":")
        key, value = key.strip(), value.strip()
        if value in (">", "|", ">-", "|-"):
            err(f"{label}: '{key}' uses a YAML block scalar. Keep it on one line.")
            continue
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            quote = value[0]
            value = value[1:-1]
            if quote == '"':
                value = value.replace('\\"', '"').replace("\\\\", "\\")
        if indented and current:
            data[current][key] = value
        elif value == "":
            data[key] = {}
            current = key
        else:
            data[key] = value
            current = None
    return data

skill_versions = {}

for name in skill_names:
    sdir = os.path.join(skills_dir, name)
    label = f"skills/{name}"
    body = read(os.path.join(sdir, "SKILL.md"))
    if body is None:
        err(f"{label}: SKILL.md is missing")
        continue

    # A plain YAML scalar cannot contain ": ". Our descriptions carry a "Türkçe:" trigger
    # segment, so an unquoted description is invalid YAML and the skill becomes invisible to
    # strict parsers, including the one skills.sh uses. Quoting is not a style choice here.
    desc_line = re.search(r"^description: (.*)$", body, re.M)
    if desc_line and not desc_line.group(1).strip().startswith('"'):
        err(f"{label}: description must be a double-quoted YAML string. "
            f'Unquoted values break on ": " and the skill will not be indexed.')
    if yaml is not None:
        try:
            fm_text = body.split("---", 2)[1]
            yaml.safe_load(fm_text)
        except IndexError:
            pass
        except Exception as exc:
            err(f"{label}: frontmatter is not valid YAML ({type(exc).__name__}: "
                f"{str(exc).splitlines()[0][:90]})")

    fm = parse_frontmatter(body, f"{label}/SKILL.md")
    if fm is not None:
        got = fm.get("name")
        if got != name:
            err(f"{label}: frontmatter name '{got}' does not match the directory name")
        if got and not NAME_RE.match(got):
            err(f"{label}: name '{got}' must be lowercase a-z, digits, single hyphens")

        desc = fm.get("description", "")
        if not desc:
            err(f"{label}: description is missing")
        else:
            if len(desc) > 1024:
                err(f"{label}: description is {len(desc)} chars, the limit is 1024")
            if len(desc) < 80:
                warn(f"{label}: description is only {len(desc)} chars, it will under-trigger")
            if "Türkçe:" not in desc:
                err(f"{label}: description has no 'Türkçe:' trigger segment")
            elif len(re.findall(r'"[^"]+"', desc.split("Türkçe:", 1)[1])) < 2:
                warn(f"{label}: fewer than 2 quoted Turkish trigger phrases")

        if fm.get("license") != "MIT":
            warn(f"{label}: license should be MIT, found {fm.get('license')!r}")

        meta = fm.get("metadata")
        if not isinstance(meta, dict):
            err(f"{label}: metadata block is missing")
        else:
            version = meta.get("version", "")
            if not re.match(r"^\d+\.\d+\.\d+$", version):
                err(f"{label}: metadata.version '{version}' is not semver")
            else:
                skill_versions[name] = version
            if meta.get("pack") != pack_name:
                err(f"{label}: metadata.pack '{meta.get('pack')}' should be '{pack_name}'")

    lines = body.count("\n") + 1
    if lines > 500:
        err(f"{label}: SKILL.md is {lines} lines, the limit is 500. Move detail to references/")
    elif lines > 450:
        warn(f"{label}: SKILL.md is {lines} lines, approaching the 500 line limit")

    if not re.search(r"^##+\s+Definition of done", body, re.M | re.I):
        err(f"{label}: no 'Definition of done' section")
    if not re.search(r"^##+\s+Output format", body, re.M | re.I):
        warn(f"{label}: no 'Output format' section")
    if "—" in body:
        warn(f"{label}: contains an em dash. House style is a plain sentence instead.")

    # referenced files must exist
    for target in re.findall(r"\]\((references/[^)#]+|scripts/[^)#]+|assets/[^)#]+)\)", body):
        if not os.path.exists(os.path.join(sdir, target)):
            err(f"{label}: SKILL.md links {target} which does not exist")

    # ------------------------------------------------------------------- evals
    evals_path = os.path.join(sdir, "evals", "evals.json")
    raw = read(evals_path)
    if raw is None:
        err(f"{label}: evals/evals.json is missing")
    else:
        try:
            ev = json.loads(raw)
        except json.JSONDecodeError as exc:
            err(f"{label}: evals.json is not valid JSON ({exc})")
        else:
            if ev.get("skill_name") != name:
                err(f"{label}: evals.json skill_name '{ev.get('skill_name')}' does not match")
            if ev.get("pack") != pack_name:
                warn(f"{label}: evals.json pack field should be '{pack_name}'")
            cases = ev.get("evals") or []
            if len(cases) < 3:
                err(f"{label}: {len(cases)} eval cases, the standard requires 3 (explicit, implicit, boundary)")
            for case in cases:
                cid = case.get("id", "?")
                for field in ("prompt", "expected_output", "assertions"):
                    if not case.get(field):
                        err(f"{label}: eval {cid} has no {field}")
                if len(case.get("assertions") or []) < 3:
                    warn(f"{label}: eval {cid} has fewer than 3 assertions")

# ---------------------------------------------------------------------- manifests
def load_json(rel):
    raw = read(os.path.join(pack_dir, rel))
    if raw is None:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        err(f"{rel}: not valid JSON ({exc})")
        return None

plugin = load_json(".claude-plugin/plugin.json")
market = load_json(".claude-plugin/marketplace.json")
pack_version = None

if plugin:
    if plugin.get("name") != pack_name:
        err(f"plugin.json: name '{plugin.get('name')}' should be '{pack_name}'")
    if plugin.get("skills") != "./skills":
        err("plugin.json: skills field should be './skills'")
    if plugin.get("license") != "MIT":
        warn("plugin.json: license should be MIT")
    expected_repo = f"https://github.com/goatstarter/{pack_name}"
    if plugin.get("repository") != expected_repo:
        err(f"plugin.json: repository should be {expected_repo}")
    pack_version = plugin.get("version")
    if not re.match(r"^\d+\.\d+\.\d+$", pack_version or ""):
        err(f"plugin.json: version '{pack_version}' is not semver")
    if len(plugin.get("description") or "") > 120:
        warn("plugin.json: description is over 120 chars")

if market:
    if market.get("name") != pack_name:
        err(f"marketplace.json: name '{market.get('name')}' should be '{pack_name}'")
    mv = (market.get("metadata") or {}).get("version")
    if pack_version and mv != pack_version:
        err(f"marketplace.json version '{mv}' does not match plugin.json '{pack_version}'")
    plugins = market.get("plugins") or []
    if len(plugins) != 1 or plugins[0].get("source") != "./":
        err("marketplace.json: expected exactly one plugin entry with source './'")

# ----------------------------------------------------------------- VERSIONS.md
versions_md = read(os.path.join(pack_dir, "VERSIONS.md")) or ""
if versions_md:
    if pack_version and pack_version not in versions_md:
        err(f"VERSIONS.md: no entry for pack version {pack_version}")
    for name, version in skill_versions.items():
        row = re.search(rf"^\|\s*`?{re.escape(name)}`?\s*\|\s*`?([0-9.]+)`?", versions_md, re.M)
        if not row:
            err(f"VERSIONS.md: no table row for skill '{name}'")
        elif row.group(1) != version:
            err(f"VERSIONS.md: '{name}' listed as {row.group(1)} but SKILL.md says {version}")

# -------------------------------------------------------------------- READMEs
for readme in readmes:
    text = read(os.path.join(pack_dir, readme)) or ""
    for name in skill_names:
        if name not in text:
            warn(f"{readme}: does not mention skill '{name}'")

# --------------------------------------------------------------------- install
install = read(os.path.join(pack_dir, "install.sh")) or ""
if install:
    if "set -euo pipefail" not in install:
        warn("install.sh: missing 'set -euo pipefail'")
    for danger in ("sudo", "rm -rf /", "$HOME/.claude", "~/.claude"):
        if danger in install:
            err(f"install.sh: contains '{danger}'. Installers only write inside the named target project.")

# ---------------------------------------------------------------------- report
print(f"pack: {pack_name}   skills: {len(skill_names)}   version: {pack_version or '?'}")
if warnings and not quiet:
    print(f"\n{len(warnings)} warning(s):")
    for m in warnings:
        print(f"  warn  {m}")
if errors:
    print(f"\n{len(errors)} error(s):")
    for m in errors:
        print(f"  FAIL  {m}")
    print("\nnot publishable")
    sys.exit(1)
print("\nvalidate: OK" + (f" ({len(warnings)} warning(s))" if warnings else ""))
PY
