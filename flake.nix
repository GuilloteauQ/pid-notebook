{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
    devShell.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = with import nixpkgs {
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
