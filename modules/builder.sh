source $stdenv/setup

shopt -s nullglob

modfile="$out/modules/$modName"
mkdir -p `dirname "$modfile"`

cat > $modfile << EOF
-- $modName
-- autogenerated by nix-with-modules

local pkgName = myModuleName(
local version = myModuleVersion()

EOF

addPaths () {
  # PATH
  if [[ -d $1/bin ]] ; then
    echo -e "prepend_path(\"PATH\", \"$1/bin\")" >> $modfile
  fi
  # MANPATH
  if [[ -d $1/share/man ]] ; then
    echo -e "prepend_path(\"MANPATH\", \"$1/share/man\")" >> $modfile
  fi
  # PKG_CONFIG_PATH
  if [[ -d $1/lib/pkgconfig ]] ; then
    echo -e "prepend_path(\"PKG_CONFIG_PATH\", \"$1/lib/pkgconfig\")" >> $modfile
  fi
  if [[ -d $1/share/pkgconfig ]] ; then
    echo -e "prepend_path(\"PKG_CONFIG_PATH\", \"$1/share/pkgconfig\")" >> $modfile
  fi
  # CMAKE_SYSTEM_PREFIX_PATH
  if [[ -f $1/lib/cmake ]] ; then
    echo -e "prepend_path(\"CMAKE_SYSTEM_PREFIX_PATH\", \"$1/lib/cmake\")" >> $modfile
  fi
  # PERL5LIB
  if [[ -d $1/lib/perl5/site_perl ]] ; then
    echo -e "prepend_path(\"PERL5LIB\", \"$1/lib/perl5/site_perl\")" >> $modfile
  fi
  # LD_LIBRARY_PATH
  libs=($1/lib/lib*.so)
  if [[ $addLDLibPath && -n $libs ]] ; then
    echo -e "prepend_path(\"LD_LIBRARY_PATH\", \"$1/lib\")" >> $modfile
  fi
}

for i in $buildInputs;
do
  addPaths $i
done

for vv in $setEnv ; do
  echo -e "setenv(\"${vv%%=*}\", \"vv#*=\")" >> $modfile
done
