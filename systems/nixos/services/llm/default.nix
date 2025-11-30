{ config, ... }:
{
  services.ollama = {
    enable = true;
    loadModels = [
      "gemma3:12b"
      "gemma3:27b"
      "gemma3:4b"
      "gpt-oss:20b"
      "qwen3:14b"
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
