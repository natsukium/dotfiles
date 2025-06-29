{ config, ... }:
{
  services.ollama = {
    enable = true;
    loadModels = [
      "deepseek-r1:14b"
      "deepseek-r1:32b"
      "deepseek-r1:7b"
      "gemma2:27b"
      "gemma2:2b"
      "gemma2:9b"
      "phi3.5:3.8b"
      "phi4" # 14B
      "qwen2.5:14b"
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
