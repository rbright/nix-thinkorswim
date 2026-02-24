#!/usr/bin/env bash
set -euo pipefail

installer="${THINKORSWIM_INSTALLER:?THINKORSWIM_INSTALLER is not set}"
java_home="${THINKORSWIM_JAVA_HOME:?THINKORSWIM_JAVA_HOME is not set}"
runtime_lib_path="${THINKORSWIM_RUNTIME_LIBRARY_PATH:-}"

xdg_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="${THINKORSWIM_HOME:-$xdg_data_home/thinkorswim}"
install_parent="$(dirname "$install_dir")"
default_install_dir="${install_parent}/thinkorswim"

pin_install4j_java() {
  local script="$1"
  [[ -f "$script" ]] || return 0

  if grep -q '^# INSTALL4J_JAVA_HOME_OVERRIDE=' "$script"; then
    sed -i "s|^# INSTALL4J_JAVA_HOME_OVERRIDE=.*$|INSTALL4J_JAVA_HOME_OVERRIDE=\"$java_home\"|" "$script"
  elif grep -q '^INSTALL4J_JAVA_HOME_OVERRIDE=' "$script"; then
    sed -i "s|^INSTALL4J_JAVA_HOME_OVERRIDE=.*$|INSTALL4J_JAVA_HOME_OVERRIDE=\"$java_home\"|" "$script"
  else
    local tmp
    tmp="$(mktemp)"
    {
      printf 'INSTALL4J_JAVA_HOME_OVERRIDE="%s"\n' "$java_home"
      cat "$script"
    } > "$tmp"
    chmod --reference="$script" "$tmp"
    mv "$tmp" "$script"
  fi

  if grep -q '^INSTALL4J_NO_PATH=' "$script"; then
    sed -i 's|^INSTALL4J_NO_PATH=.*$|INSTALL4J_NO_PATH=true|' "$script"
  else
    sed -i '/^INSTALL4J_JAVA_HOME_OVERRIDE=/a INSTALL4J_NO_PATH=true' "$script"
  fi

  if grep -q '^JAVA_HOME=' "$script"; then
    sed -i "s|^JAVA_HOME=.*$|JAVA_HOME=\"$java_home\"|" "$script"
  else
    sed -i "/^INSTALL4J_NO_PATH=true/a JAVA_HOME=\"$java_home\"" "$script"
  fi
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
pin_install4j_java "$launcher"

export INSTALL4J_JAVA_HOME_OVERRIDE="$java_home"
export INSTALL4J_NO_PATH=true
export JAVA_HOME="$java_home"

if [[ -n "$runtime_lib_path" ]]; then
  export LD_LIBRARY_PATH="${runtime_lib_path}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

exec "$launcher" "$@"
