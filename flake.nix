{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/22.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      startPluto = pkgs.writeText "start_pluto.jl" ''
        using Pkg;
        if isfile("Project.toml") && isfile("Manifest.toml")
            Pkg.activate(".")
        end;
        Pkg.instantiate()
        using Pluto;
        Pluto.run(notebook="/tmp/workdir/pid.jl")
      '';
    in
    {


      packages.${system}.pid-docker = pkgs.dockerTools.buildImage {
        name = "guilloteauq/pid-jl-docker";
        tag = "jan23";

        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = [ pkgs.julia-stable-bin ];
          pathsToLink = [ "/bin" ];
        };
        runAsRoot = ''
            #!${pkgs.runtimeShell}
          mkdir -p /tmp/workdir
          cd /tmp/workdir
          ln -s ${./Project.toml} /tmp/workdir/Project.toml
          ln -s ${./Manifest.toml} /tmp/workdir/Manifest.toml
          ln -s ${./pid.jl} /tmp/workdir/pid.jl
      
        '';
        config = {
          WorkingDir = "/tmp/workdir";
          Cmd = [
            "/bin/julia"
            startPluto
          ];
          ExposedPorts = {
            "1234/tcp" = { };
          };
        };
      };


      devShell.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        buildInputs = with import nixpkgs
          {
            system = "x86_64-linux";
          };
          [ julia-stable-bin ];
        shellHook = ''
          julia -e '
            using Pkg;
            if isfile("Project.toml") && isfile("Manifest.toml")
                Pkg.activate(".")
            end;
            using Pluto;
            Pluto.run(notebook=joinpath(pwd(), "pid.jl"))'
        '';
      };

    };
}
