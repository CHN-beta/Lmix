source $stdenv/setup

shopt -s nullglob

modfile="$out/modules/$modName"
mkdir -p `dirname "$modfile"`

cat > $modfile << EOF
-- $modName
-- autogenerated by nix-with-modules

local pkgName = myModuleName()
local version = myModuleVersion()

EOF

modPrependPath () {
  echo -e "prepend_path(\"$1\", \"$2\")" >> $modfile
}

modSetEnv () {
  echo -e "setenv(\"$1\", \"$2\")" >> $modfile
}

addPaths () {
  # PATH
  if [[ -d $1/bin ]] ; then
    modPrependPath "PATH" "$1/bin"
  fi
  # MANPATH
  if [[ -d $1/share/man ]] ; then
    modPrependPath "MANPATH" "$1/share/man"
  fi
  # PKG_CONFIG_PATH
  if [[ -d $1/lib/pkgconfig ]] ; then
    modPrependPath "PKG_CONFIG_PATH" "$1/lib/pkgconfig"
  fi
  if [[ -d $1/share/pkgconfig ]] ; then
    modPrependPath "PKG_CONFIG_PATH" "$1/share/pkgconfig"
  fi
  # CMAKE_SYSTEM_PREFIX_PATH
  if [[ -d $1/lib/cmake ]] ; then
    modPrependPath "CMAKE_SYSTEM_PREFIX_PATH" "$1/lib/cmake"
  fi
  # PERL5LIB
  if [[ -d $1/lib/perl5/site_perl ]] ; then
    modPrependPath "PERL5LIB" "$1/lib/perl5/site_perl"
  fi
  # LD_LIBRARY_PATH
  libs=($1/lib/lib*.so)
  if [[ $addLDLibPath && -n $libs ]] ; then
    modPrependPath "LD_LIBRARY_PATH" "$1/lib"
  fi
}

addPkgVariables () {
  # PAC_BASE - base nix store path
  modSetEnv "${pacName}_BASE" "${PAC_BASE}"
  if [[ -n "$PAC_BIN" ]] ; then
    # PAC_BIN - bin directory
    modSetEnv "${pacName}_BIN" "${PAC_BIN}"
  fi
  # PAC_LIBDIR - library directory
  if [[ -n "$PAC_LIBDIR" ]] ; then
    modSetEnv "${pacName}_LIBDIR" "${PAC_LIBDIR}"
    # PAC_LIB - setting for static linking
    if [[ -n "$PAC_LIB" ]] ; then
      modSetEnv "${pacName}_LIB" "${PAC_LIB}"
    fi
    # PAC_SHLIB - setting for dynamic linking
    if [[ -n "$PAC_SHLIB" ]] ; then
      modSetEnv "${pacName}_SHLIB" "${PAC_SHLIB}"
    fi
    if [[ -n "$PAC_PTHREADS_LIB" ]] ; then
      modSetEnv "${pacName}_PTHREADS_LIB" "${PAC_PTHREADS_LIB}"
    fi
    if [[ -n "$PAC_PTHREADS_SHLIB" ]] ; then
      modSetEnv "${pacName}_PTHREADS_SHLIB" "${PAC_PTHREADS_SHLIB}"
    fi
    if [[ -n "$PAC_MPI_LIB" ]] ; then
      modSetEnv "${pacName}_MPI_LIB" "${PAC_MPI_LIB}"
    fi
    if [[ -n "$PAC_MPI_SHLIB" ]] ; then
      modSetEnv "${pacName}_MPI_SHLIB" "${PAC_MPI_SHLIB}"
    fi
  fi
  # PAC_INC - include directory
  if [[ -n "$PAC_INC" ]] ; then
    modSetEnv "${pacName}_INC" "${PAC_INC}"
  fi
  keys=$(jq -r 'keys[]' <<< "$extraPkgVariables")
  for key in $keys ; do
    val=$(jq --arg key "$key" --raw-output '.[$key]' <<< "$extraPkgVariables")
    modSetEnv "${pacName}_$key" "$val"
  done
}

addPaths "$PAC_BASE"

echo >> $modfile

addPkgVariables

echo >> $modfile

keys=$(jq -r 'keys[]' <<< "$extraEnvVariables")
for key in $keys ; do
  val=$(jq --arg key "$key" --raw-output '.[$key]' <<< "$extraEnvVariables")
  modSetEnv "$key" "$val"
done
