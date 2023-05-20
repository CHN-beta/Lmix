source $stdenv/setup

shopt -s nullglob

modfile="$out/modules/$modName"
mkdir -p `dirname "$modfile"`

cat > $modfile << EOF
-- $modName
-- autogenerated by nix-with-modules

local pkgName = myModuleName()
local version = myModuleVersion()

depends_on("nix-stdenv")

EOF


modPrependPath () {
  echo -e "prepend_path(\"$1\", \"$2\")" >> $modfile
}

modPrependPathIfExists () {
  if [[ -d "$2" && " $excludes " != *" $1 "* ]] ; then
      modPrependPath $1 $2
  fi
}

modSetEnv () {
  echo -e "setenv(\"$1\", \"$2\")" >> $modfile
}

addPaths () {
  modPrependPathIfExists "PATH" "$1/bin"
  modPrependPathIfExists "MANPATH" "$1/share/man"
  modPrependPathIfExists "PKG_CONFIG_PATH" "$1/lib/pkgconfig"
  modPrependPathIfExists "PKG_CONFIG_PATH" "$1/share/pkgconfig"
  modPrependPathIfExists "CMAKE_SYSTEM_PREFIX_PATH" "$1/lib/cmake"
  modPrependPathIfExists "PERL5LIB" "$1/lib/perl5/site_perl"

  libs=($1/lib/lib*.so)
  if [[ $addLDLibPath && -n $libs ]] ; then
    modPrependPath "LD_LIBRARY_PATH" "$1/lib"
  fi

  keys=$(jq -r 'keys[]' <<< "$extraPaths")
  for key in $keys ; do
    val=$(jq --arg key "$key" --raw-output '.[$key]' <<< "$extraPaths")
    modPrependPath "$key" "$val"
  done
}

addPkgVariables () {
  modSetEnv "${pacName}_NIX_MODULES_ATTR" "${PAC_NIX_MODULES_ATTR}"
  # PAC_BASE - base nix store path
  modSetEnv "${pacName}_BASE" "${PAC_BASE}"
  if [[ -n "$PAC_BIN" ]] ; then
    # PAC_BIN - bin directory
    modSetEnv "${pacName}_BIN" "${PAC_BIN}"
  fi
  # PAC_LIBDIR - library directory
  if [[ -n "$PAC_LIBDIR" && " $excludes " != *" LIBDIR "* ]]; then
    modSetEnv "${pacName}_LIBDIR" "${PAC_LIBDIR}"
    # PAC_LIB - setting for static linking
    if [[ -n "$PAC_LIB" && " $excludes " != *" LIB "* ]] ; then
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
  if [[ -n "$PAC_INC" && " $excludes " != *" INC "* ]] ; then
    modSetEnv "${pacName}_INC" "${PAC_INC}"
  fi
  keys=$(jq -r 'keys[]' <<< "$extraPkgVariables")
  for key in $keys ; do
    val=$(jq --arg key "$key" --raw-output '.[$key]' <<< "$extraPkgVariables")
    modSetEnv "${pacName}_$key" "$val"
  done
}

if [[ -n "$customModfilePath" ]]; then
  moddir="$(dirname $customModfilePath)"
  modname="$(basename $customModfilePath)"
  modPrependPath "MODULEPATH" "$moddir"
  echo -e "load(\"$modname\")" >> $modfile
fi

if [[ -n "$customScriptPath" ]]; then
  echo -e "source_sh(\"bash\", \"$customScriptPath\")" >> $modfile
fi

if [[ -n "$dependencies" ]] ; then
  for module in $dependencies ; do
    echo -e "depends_on(\"$module\")" >> $modfile
  done
fi

for i in "$buildInputs" ; do
  addPaths $i
done


echo >> $modfile

addPkgVariables

echo >> $modfile

keys=$(jq -r 'keys[]' <<< "$extraEnvVariables")
for key in $keys ; do
  val=$(jq --arg key "$key" --raw-output '.[$key]' <<< "$extraEnvVariables")
  modSetEnv "$key" "$val"
done
