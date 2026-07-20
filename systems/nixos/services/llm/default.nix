{ config, ... }:
{
  services.ollama = {
    enable = true;
    syncModels = true;
    loadModels = [
      "gemma4:12b"
      "gemma4:31b"
      "gemma4:e4b"
      "qwen3.5:9b"
      "qwen3.6:27b"
    ];
  };

  services.open-webui = {
    enable = false;
    host = "0.0.0.0";
    environment = {
      OLLAMA_API_BASE_URL = "http://${config.services.ollama.host}:${toString config.services.ollama.port}";
      WEBUI_AUTH = "False";
    };
  };
}
