#!/usr/bin/env bash
set -euo pipefail

installer="${THINKORSWIM_INSTALLER:?THINKORSWIM_INSTALLER is not set}"
java_home="${THINKORSWIM_JAVA_HOME:?THINKORSWIM_JAVA_HOME is not set}"
runtime_lib_path="${THINKORSWIM_RUNTIME_LIBRARY_PATH:-}"

xdg_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="${THINKORSWIM_HOME:-$xdg_data_home/thinkorswim}"
install_parent="$(dirname "$install_dir")"
default_install_dir="${install_parent}/thinkorswim"

upsert_launcher_assignment() {
  local script="$1"
  local key="$2"
  local assignment="$3"
  local match_commented="${4:-0}"

  local tmp
  local found=0
  tmp="$(mktemp)"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$match_commented" == "1" && "$line" =~ ^[[:space:]]*#[[:space:]]*${key}= ]]; then
      printf '%s\n' "$assignment" >> "$tmp"
      found=1
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*${key}= ]]; then
      printf '%s\n' "$assignment" >> "$tmp"
      found=1
      continue
    fi

    printf '%s\n' "$line" >> "$tmp"
  done < "$script"

  if [[ "$found" -eq 0 ]]; then
    local injected
    injected="$(mktemp)"
    {
      IFS= read -r first || true
      if [[ "${first:-}" == '#!'* ]]; then
        printf '%s\n' "$first"
        printf '%s\n' "$assignment"
        cat
      else
        printf '%s\n' "$assignment"
        [[ -n "${first:-}" ]] && printf '%s\n' "$first"
        cat
      fi
    } < "$tmp" > "$injected"
    mv "$injected" "$tmp"
  fi

  chmod --reference="$script" "$tmp"
  mv "$tmp" "$script"
}

pin_install4j_java() {
  local script="$1"
  [[ -f "$script" ]] || return 0

  upsert_launcher_assignment "$script" "INSTALL4J_JAVA_HOME_OVERRIDE" "INSTALL4J_JAVA_HOME_OVERRIDE=\"$java_home\"" 1
  upsert_launcher_assignment "$script" "INSTALL4J_NO_PATH" "INSTALL4J_NO_PATH=true"
  upsert_launcher_assignment "$script" "JAVA_HOME" "JAVA_HOME=\"$java_home\""
}

if [[ "${THINKORSWIM_FORCE_REINSTALL:-0}" == "1" ]]; then
  rm -rf "$install_dir"
fi

if [[ ! -x "$install_dir/thinkorswim" ]]; then
  mkdir -p "$install_parent"

  varfile="$(mktemp)"
  cleanup() {
    rm -f "$varfile"
  }
  trap cleanup EXIT

  cat >"$varfile" <<'EOF'
ackLicenseValue=true
create_icon$Boolean=false
executeLauncherAction$Boolean=false
installFor=me
sys.adminRights$Boolean=false
sys.languageId=en
userDomain=schwab
EOF

  "$installer" -q -varfile "$varfile" -J-Duser.home="$install_parent"

  if [[ "$default_install_dir" != "$install_dir" && -d "$default_install_dir" && ! -e "$install_dir" ]]; then
    mv "$default_install_dir" "$install_dir"
  fi
fi

launcher="$install_dir/thinkorswim"
if [[ ! -x "$launcher" ]]; then
  echo "thinkorswim installation failed: launcher not found at $launcher" >&2
  exit 1
fi

# thinkorswim sometimes self-restarts via the installed launcher script.
# Pin Java in that script so restarts do not fall back to an older system JVM.
# Set THINKORSWIM_PATCH_LAUNCHER_JAVA=0 to disable this patching behavior.
if [[ "${THINKORSWIM_PATCH_LAUNCHER_JAVA:-1}" == "1" ]]; then
  pin_install4j_java "$launcher"
fi

export INSTALL4J_JAVA_HOME_OVERRIDE="$java_home"
export INSTALL4J_NO_PATH=true
export JAVA_HOME="$java_home"

if [[ -n "$runtime_lib_path" ]]; then
  export LD_LIBRARY_PATH="${runtime_lib_path}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

exec "$launcher" "$@"
