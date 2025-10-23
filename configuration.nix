# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

let
  claude-code-flake = builtins.getFlake "github:sadjow/claude-code-nix";
  claude-code-latest = claude-code-flake.packages.${pkgs.system}.default;
in
{
  # ============================================================================
  # IMPORTS
  # ============================================================================

  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================================
  # BOOT CONFIGURATION
  # ============================================================================

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # ============================================================================
  # NETWORKING
  # ============================================================================

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";
    # firewall.allowedTCPPorts = [ ... ];
    # firewall.allowedUDPPorts = [ ... ];
    # firewall.enable = false;
  };

  # ============================================================================
  # LOCALIZATION
  # ============================================================================

  time.timeZone = "America/New_York";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  # ============================================================================
  # HARDWARE
  # ============================================================================

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  # ============================================================================
  # DISPLAY SERVER & DESKTOP ENVIRONMENT
  # ============================================================================

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.displayManager = {
    sddm = {
      enable = true;
      theme = "elarun";
    };
    autoLogin = {
      enable = false;
      user = "vincent";
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # ============================================================================
  # USER CONFIGURATION
  # ============================================================================

  users = {
    defaultUserShell = pkgs.zsh;
    users.vincent = {
      isNormalUser = true;
      description = "vincent";
      extraGroups = [ "networkmanager" "wheel" "docker" ];
      packages = with pkgs; [
        vim
        neovim
        firefox
        brave
      ];
    };
  };

  # ============================================================================
  # NIX CONFIGURATION
  # ============================================================================

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ============================================================================
  # THEMING
  # ============================================================================

  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "adwaita-dark";
  };

  environment.variables = {
    QT_STYLE_OVERRIDE = "adwaita-dark";
    GTK_THEME = "Adwaita:dark";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DECORATION = "adwaita";
  };

  # ============================================================================
  # VIRTUALIZATION
  # ============================================================================

  virtualisation.docker.enable = true;

  # ============================================================================
  # AUTO-BACKUP CONFIGURATION TO GITHUB
  # ============================================================================

  system.activationScripts.backup-nixos-config = {
    text = ''
      echo "Backing up NixOS configuration to ~/nixos-config..."

      # Copy configuration files
      ${pkgs.rsync}/bin/rsync -av /etc/nixos/*.nix /home/vincent/nixos-config/ || true

      # Change ownership to vincent
      ${pkgs.coreutils}/bin/chown -R vincent:users /home/vincent/nixos-config

      # Run git commands as vincent user
      ${pkgs.sudo}/bin/sudo -u vincent ${pkgs.bash}/bin/bash << EOSCRIPT
        cd /home/vincent/nixos-config

        # Check if there are any changes
        if ! ${pkgs.git}/bin/git diff --quiet || ! ${pkgs.git}/bin/git diff --cached --quiet; then
          ${pkgs.git}/bin/git add -A
          ${pkgs.git}/bin/git commit -m "Auto-backup after nixos-rebuild: \$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')"
          ${pkgs.git}/bin/git push origin master || echo "Failed to push to GitHub (check network/auth)"
        else
          echo "No changes to commit."
        fi
EOSCRIPT
    '';
    deps = [];
  };

  # ============================================================================
  # PROGRAMS
  # ============================================================================

  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    zsh = {
      enable = true;
      shellInit = ''
        eval "$(zoxide init zsh)"
      '';
    };

    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };
  };

  # ============================================================================
  # SERVICES
  # ============================================================================

  services = {
    openssh.enable = true;
    tailscale.enable = true;
  };

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # Development Tools
    vim
    neovim
    git
    lazygit
    cmake
    gcc
    gnumake
    gh
    pkg-config
    file
    claude-code-latest

    # System Utilities
    wget
    curl
    curl.dev
    unzip
    btop
    htop
    nvtopPackages.full
    nload
    zoxide
    fastfetch

    # Libraries
    asio
    gitea-actions-runner

    # Terminal & Shell
    kitty
    zsh
    tmux

    # Wayland/Hyprland
    wofi
    waybar
    hyprlock
    hypridle

    # File Manager
    xfce.thunar
    xfce.thunar-volman
    yazi

    # Theming
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugins
    adwaita-icon-theme
    adwaita-qt
    adwaita-qt6
    gnome-themes-extra

    # Communication
    thunderbird
    discord
    signal-desktop
    slack

    # Remote Access
    remmina

    # Entertainment
    steam
    spotify

    # Screenshot
    maim
  ];

  # ============================================================================
  # SYSTEM STATE VERSION
  # ============================================================================

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
