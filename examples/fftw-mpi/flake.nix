{
  description = "Used by the lmod2flake program";

  inputs.lmix.url = github:kilzm/lmix;

  outputs = { self, lmix }:
    let
      system = "x86_64-linux";
      pkgs = lmix.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell.override { 
          stdenv = pkgs.lmix-pkgs.intel21Stdenv;
        }
        rec {
          buildInputs = with pkgs; [
            lmix-pkgs.fftw_3_3_10_intel21_impi_2019
            lmix-pkgs.intel-mpi_2019
          ];
          nativeBuildInputs = with pkgs; [
            pkgconfig
            autoreconfHook
            autoconf-archive
          ];
          I_MPI_ROOT="${pkgs.lmix-pkgs.intel-mpi_2019}";
        };

      packages.${system} = rec {
        fftw_mpi_intel21_impi = pkgs.callPackage ./. (with pkgs; {
          stdenv = lmix-pkgs.intel21Stdenv;
          mpi = lmix-pkgs.intel-mpi_2019;
          fftw = lmix-pkgs.fftw_3_3_10_intel21_impi_2019;
        });

        fftw_mpi_gcc11_ompi = pkgs.callPackage ./. (with pkgs; {
          stdenv = lmix-pkgs.gcc11Stdenv;
          mpi = lmix-pkgs.openmpi_4_1_5_gcc11;
          fftw = lmix-pkgs.fftw_3_3_10_gcc11_ompi_4_1_5;
        });

        default = fftw_mpi_intel21_impi;
      };
    };

  nixConfig = {
    bash-prompt-prefix = ''\033[0;36m\[(nix develop)\033[0m '';
  };
}
