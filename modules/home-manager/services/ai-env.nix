{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dev-config.ai-env = {
    enable =
      lib.mkEnableOption "AI environment variables system-wide loader"
      // {
        default = true;
      };
  };

  config = lib.mkIf config.dev-config.ai-env.enable {
    # macOS: LaunchAgent
    launchd.agents.ai-env = lib.mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          ''
                        # User-visible log location (better for debugging)
                        LOG_DIR="$HOME/Library/Logs"
                        mkdir -p "$LOG_DIR"
                        LOG_FILE="$LOG_DIR/ai-env.log"

                        # Run sync-secrets to fetch AI credentials and SSH key from 1Password
                        "$HOME/Projects/dev-config/scripts/sync-secrets.sh" >> "$LOG_FILE" 2>&1 || true

                        SECRETS_DIR="$HOME/.config/dev-config/secrets"

                        # Load AI environment variables
                        for key in ANTHROPIC_API_KEY OPENAI_API_KEY LITELLM_MASTER_KEY GOOGLE_AI_API_KEY; do
                          secret_file="$SECRETS_DIR/$key"
                          if [ -f "$secret_file" ]; then
                            value=$(cat "$secret_file")
                            /bin/launchctl setenv "$key" "$value"
                            echo "$(date): ✅ Loaded $key" >> "$LOG_FILE"
                          else
                            echo "$(date): ⚠️  WARNING - $key file not found" >> "$LOG_FILE"
                          fi
                        done

                        # Add SSH key to ssh-agent with passphrase from 1Password
                        if [ -f "$HOME/.ssh/personal" ] && [ -f "$SECRETS_DIR/SSH_PASSPHRASE" ]; then
                          # Start ssh-agent if not running
                          if ! pgrep -u "$USER" ssh-agent > /dev/null; then
                            eval "$(ssh-agent -s)" >> "$LOG_FILE" 2>&1
                          fi

                          # Load passphrase from 1Password cache
                          PASSPHRASE=$(cat "$SECRETS_DIR/SSH_PASSPHRASE" 2>/dev/null || echo "")

                          if [ -n "$PASSPHRASE" ]; then
                            # Use expect to provide passphrase to ssh-add
                            expect <<EOF >> "$LOG_FILE" 2>&1 || true
                              spawn ssh-add "$HOME/.ssh/personal"
                              expect "Enter passphrase"
                              send "$PASSPHRASE\r"
                              expect eof
            EOF
                            echo "$(date): ✅ SSH key loaded to agent with passphrase" >> "$LOG_FILE"
                          else
                            echo "$(date): ⚠️  WARNING - SSH passphrase not found" >> "$LOG_FILE"
                          fi
                        fi

                        echo "$(date): ✅ AI environment setup complete" >> "$LOG_FILE"
          ''
        ];
        RunAtLoad = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/ai-env-stdout.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/ai-env-stderr.log";
      };
    };

    # Linux/NixOS: systemd user service
    systemd.user.services.ai-env = lib.mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Load AI environment variables from cache";
        After = ["default.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "load-ai-env" ''
          SECRETS_DIR="$HOME/.config/dev-config/secrets"

          for key in ANTHROPIC_API_KEY OPENAI_API_KEY LITELLM_MASTER_KEY GOOGLE_AI_API_KEY; do
            secret_file="$SECRETS_DIR/$key"
            if [ -f "$secret_file" ]; then
              value=$(cat "$secret_file")
              ${pkgs.systemd}/bin/systemctl --user set-environment "$key=$value"
              logger "ai-env: ✅ Loaded $key"
            else
              logger "ai-env: ⚠️  WARNING - $key file not found"
            fi
          done

          logger "ai-env: ✅ AI environment setup complete"
        ''}";
        RemainAfterExit = true;
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    # Note: Shell fallback moved to programs/zsh.nix initExtra
    # This prevents Nix module conflict (multiple definitions of programs.zsh.initExtra)
  };
}
