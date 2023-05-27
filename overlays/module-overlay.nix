final: prev:
let
  defaultModulesNixpkgs = attrNames:
    map
      (attrName: prev.callPackage ../modules {
        pkg = prev.${attrName};
        inherit attrName;
      })
      attrNames;
  
  defaultModules = attrNames:
    map
      (attrName: prev.callPackage ../modules {
        pkg = prev.nwm-pkgs.${attrName};
        attrName = "nwm-pkgs.${attrName}";
      })
      attrNames;

  namedModulesNixpkgs = name: attrNames:
    map
      (attrName: prev.callPackage ../modules/${name} {
        pkg = prev.${attrName};
        inherit attrName;
      })
      attrNames;

  namedModules = name: attrNames:
    map
      (attrName: prev.callPackage ../modules/${name} {
        pkg = prev.nwm-pkgs.${attrName};
        attrName = "nwm-pkgs.${attrName}";
      })
      attrNames;

  namedCCModules = name: compiler: compilerVer: attrNames:
    map
      (attrName: prev.callPackage ../modules/${name} {
        pkg = prev.nwm-pkgs.${attrName};
        attrName = "nwm-pkgs.${attrName}";
        inherit compiler compilerVer;
      })
      attrNames;
in
{
  nwm-mods = {
    # modules
    _modules-nixpkgs = prev.buildEnv {
      name = "modules-nixpkgs";
      paths = defaultModulesNixpkgs [
        "samtools"
        "ffmpeg"
        "git"
        "valgrind"
        "llvm"
      ]
      ++ namedModulesNixpkgs "gcc" [
        "gcc7"
        "gcc8"
        "gcc9"
        "gcc10"
        "gcc11"
        "gcc12"
      ]
      ++ namedModulesNixpkgs "ruby" [
        "ruby"
      ]
      ++ namedModulesNixpkgs "python" [
        "python2"
        "python37"
        "python39"
        "python311"
      ];
    };

    _modules = prev.buildEnv {
      name = "modules";
      paths = defaultModules [
        "nix-stdenv"
        "julia_1_9_0"
        "julia_1_8_5"
        "osu-micro-benchmarks_5_6_2"
        "osu-micro-benchmarks_6_1"
      ]
      ++ namedCCModules "openmpi" "gcc" 11 [
        "openmpi_4_1_4_gcc11"
        "openmpi_4_1_5_gcc11"
      ]
      ++ namedCCModules "fftw" "gcc" 11 [
        "fftw_3_3_10_gcc11_ompi_4_1_5"
      ]
      ++ namedCCModules "fftw" "gcc" 12 [
        "fftw_3_3_10_gcc12_ompi_4_1_5_openmp"
      ]
      ++ namedModules "intel/oneapi-compilers" [
        "intel-compilers_2022_1_0"
      ]
      ++ namedModules "intel/oneapi-tbb" [
        "intel-tbb_2021_6_0"
      ]
      ++ namedCCModules "intel/oneapi-mpi" "gcc" 12 [
        "intel-oneapi-mpi_2021_6_0_gcc11"
      ]
      ++ namedCCModules "intel/oneapi-mpi" "intel" 21 [
        "intel-oneapi-mpi_2021_6_0_intel21"
      ]
      ++ namedCCModules "fftw" "intel" 21 [
        "fftw_3_3_10_intel21"
      ];
    };

    lmod2flake = prev.callPackage ../lmod2flake { };
  };
}
