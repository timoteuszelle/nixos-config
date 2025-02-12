{...}: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      ollama = {
        image = "ollama/ollama:latest";
        volumes = [
          "/home/tim/ollama/data:/root/.ollama"
        ];
        environment = {
          TZ = "Europe/Amsterdam";
        };
        extraOptions = [
          "--network=host"
          "--memory=8g"
          "--memory-swap=16g"
          "--cpu-shares=1024"
          "--health-cmd=wget -q --spider http://localhost:11434/api/health || exit 1"
          "--health-interval=60s"
          "--health-retries=3"
          "--health-timeout=5s"
        ];
        ports = [
          #"11434:11434/tcp"
        ];
      };

      ollama-webui = {
        image = "ghcr.io/ollama-webui/ollama-webui:main";
        environment = {
          TZ = "Europe/Amsterdam";
          OLLAMA_API_BASE_URL = "http://localhost:11434/api";
          DISABLE_AUTH = "1";
          WEBUI_AUTH_ENABLED = "false";
          DEFAULT_USERNAME = "";
          DEFAULT_PASSWORD = "";
          PORT = "3001";
        };
        extraOptions = [
          "--network=host"
        ];
        dependsOn = [ "ollama" ];
      };
    };
  };
}
