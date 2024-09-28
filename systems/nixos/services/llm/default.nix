{ config, ... }:
{
  services.ollama = {
    enable = true;
    loadModels = [
      "gemma2:27b"
      "gemma2:2b"
      "gemma2:9b"
      "llama3.1:8b"
      "phi3.5:3.8b"
      "qwen2.5:14b"
    ];
  };

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    environment = {
      OLLAMA_API_BASE_URL = "http://${config.services.ollama.host}:${toString config.services.ollama.port}";
      WEBUI_AUTH = "False";
    };
  };
}
