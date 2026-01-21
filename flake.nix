{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager }:
  let
    configuration = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        android-studio-tools
        claude-code
        devcontainer
        docker-credential-helpers
        git-credential-manager
        gh
        git
        go
        golangci-lint
        google-cloud-sdk
        graphviz
        hexedit
        hyperfine
        home-manager
        immich-go
        jq
        llama-cpp
        mosh
        mpv
        ncdu
        nodejs_20
        ollama
        poppler-utils # For pdftotext
        pprof
        protobuf
        pv
        ripgrep
        watchexec
        wget
        unixtools.watch
        zstd
        zulu21
      ];

      homebrew = {
        enable = true;
        onActivation = {
          cleanup = "zap";
          autoUpdate = true;
          upgrade = true;
        };

        brews = [
          "xz"
        ];

        casks = [
          "alacritty"
          "balenaetcher"
          "cursor"
          "google-chrome"
          "google-drive"
          "jordanbaird-ice"
          "jellyfin-media-player"
          "luniistore"
          "raspberry-pi-imager"
          "raycast"
          "slack"
          "spotify"
          "stats"
          "sweet-home3d"
          "tailscale-app"
          "telegram"
          "whatsapp"
          "zoom"
          "nikitabobko/tap/aerospace"
        ];

        taps = [
          "nikitabobko/tap"
        ];
      };

      nix.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      system.primaryUser = "anupc";

      networking.hostName = "watchtower";

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      nixpkgs.config.allowUnfreePredicate = (pkg: true);

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.anupc = { pkgs, config, ... }: {
        home.stateVersion = "23.05";
        programs.tmux = {
          enable = true;
          newSession = true;
          terminal = "screen-256color";
          keyMode = "vi";
          shortcut = "a";
          plugins = with pkgs.tmuxPlugins; [
            cpu
            nord
          ];
        };

        programs.htop = {
          enable = true;
        };

        programs.neovim = {
          enable = true;
          defaultEditor = true;
          extraPackages = with pkgs; [
            gopls
            gotools # goimports, ...
            lua-language-server
            nil
            nodePackages.typescript-language-server
            python312Packages.python-lsp-server
            rust-analyzer
            shellcheck
            shfmt
          ];
        };

        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;

        xdg.configFile."nvim" = {
          source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/nvim";
        };

        programs.zsh = {
          enable = true;
          oh-my-zsh = {
            enable = true;
            theme = "aussiegeek";
            plugins = [
              "git"
              "golang"
              "ssh-agent"
            ];
          };
        };

        programs.vscode = {
          enable = true;
          profiles.default = {
            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
            extensions = [
              pkgs.vscode-extensions.github.copilot
              pkgs.vscode-extensions.github.copilot-chat
              pkgs.vscode-extensions.vscodevim.vim
            ];
            userSettings = {
              "continue.telemetryEnabled" = false;
              "editor.lineNumbers" = "relative";
            };
          };
        };
      };

      users.users.anupc.home = "/Users/anupc";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#watchtower
    darwinConfigurations."watchtower" = nix-darwin.lib.darwinSystem {
      modules = [ home-manager.darwinModules.home-manager configuration ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."watchtower".pkgs;
  };
}
