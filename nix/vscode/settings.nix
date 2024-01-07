{ lib, ... }:
let
  flattenAttrsNames = (import ../lib/attrsets.nix { inherit lib; }).flattenAttrsNames;
in
(flattenAttrsNames rec {
  # common
  editor = {
    fontFamily = "'Liga HackGen35Nerd Console', Hack, Menlo, Monaco, 'Courier New', monospace";
    fontLigatures = "zero";
    fontSize = 12;
    renderWhitespace = "boundary";
    acceptSuggestionOnEnter = "off";
    suggestSelection = "first";
    tabSize = 2;
    minimap = {
      enabled = false;
      renderCharacters = false;
    };
    cursorStyle = "line";
    insertSpaces = true;
    lineNumbers = "on";
    wordSeparators = ''/\()"':,.;<>~!@#$%^&*|+=[]{}`?-'';
    wordWrap = "on";
    bracketPairColorization.enabled = true;
    formatOnSave = true;
    multiCursorModifier = "alt";
  };
  workbench = {
    colorTheme = "Nord";
    iconTheme = "material-icon-theme";
    startupEditor = "newUntitledFile";
    sideBar.location = "left";
  };
  git = {
    autofetch = true;
    confirmSync = false;
    ignoreMissingGitWarning = true;
  };
  window.title = "\${activeEditorMedium}\${separator}\${rootPath}";
  explorer = {
    confirmDelete = false;
    confirmDragAndDrop = false;
  };
  files = {
    insertFinalNewline = true;
    autoSave = "onFocusChange";
    trimFinalNewlines = true;
    trimTrailingWhitespace = true;
    eol = "\n";
  };
  debug = {
    showInStatusBar = "never";
    onTaskErrors = "debugAnyway";
  };
  terminal.integrated = {
    macOptionIsMeta = true;
    defaultLocation = "editor";
    fontFamily = editor.fontFamily;
    gpuAcceleration = "canvas";
  };
  remote.SSH.connectTimeout = 60;
  diffEditor.ignoreTrimWhitespace = false;
  notebook.output.textLineLimit = 0;
  security.workspace.trust.untrustedFiles = "open";
  dotfiles = {
    installCommand = "~/.dotfiles/bin/install.sh";
    targetPath = "~/.dotfiles";
    repository = "natsukium/dotfiles";
  };

  # extension
  vim = {
    showmodename = true;
    leader = "<space>";
    easymotion = true;
    easymotionKeys = "hklyuiopnm,qwertzxcvbasdgjf";
    easymotionMarkerBackgroundColor = "#E5E9F0";
    easymotionMarkerForegroundColorOneChar = "#5E81AC";
    easymotionMarkerForegroundColorTwoCharFirst = "#8FBCBB";
    easymotionMarkerForegroundColorTwoCharSecond = "#88C0D0";
    easymotionMarkerFontWeight = "bold";
    hlsearch = true;
    useSystemClipboard = true;
    visualstar = true;
    vimrc = {
      enable = true;
      path = "~/.config/vim/vimrc";
    };
    normalModeKeyBindings = [
      {
        before = [
          "Z"
          "Z"
        ];
        commands = [ ":wq" ];
      }
      {
        before = [
          "<leader>"
          "'"
        ];
        commands = [ "workbench.action.terminal.new" ];
      }
      {
        before = [
          "<leader>"
          "h"
        ];
        after = [ "^" ];
      }
      {
        before = [
          "<leader>"
          "l"
        ];
        after = [ "$" ];
      }
      {
        before = [
          "<leader>"
          "p"
        ];
        commands = [
          {
            command = "workbench.action.tasks.runTask";
            args = "file preview";
          }
        ];
      }
      {
        before = [
          "<leader>"
          "b"
        ];
        commands = [
          {
            command = "workbench.action.tasks.runTask";
            args = "open active tab";
          }
        ];
      }
      {
        before = [
          "<leader>"
          "f"
        ];
        commands = [
          {
            command = "workbench.action.tasks.runTask";
            args = "fuzzy search";
          }
        ];
      }
    ];
    insertModeKeyBindings = [
      {
        before = [
          "j"
          "j"
        ];
        after = [ "<Esc>" ];
      }
    ];
  };
  vsintellicode.modify.editor.suggestSelection = "automaticallyOverrodeDefaultValue";
  tabnine.experimentalAutoImports = true;
  liveServer.settings.donotShowInfoMsg = true;
  cSpell.userWords = [
    "astype"
    "bokeh"
    "gbdt"
    "iloc"
    "isdigit"
    "jsons"
    "lgbm"
    "lgbm regressor"
    "lightgbm"
    "mlflow"
    "ndarray"
    "numpy"
    "pandas"
    "plotly"
    "rdkit"
    "regressor"
    "sklearn"
    "tanimoto"
    "tqdm"
    "xaxis"
    "xlsx"
    "yaxis"
  ];
  vscode-edge-devtools = {
    headless = true;
    defaultUrl = "localhost:3000";
    welcome = false;
    mirrorEdits = true;
  };
  githubPullRequests = {
    queries = [
      {
        label = "Waiting For My Review";
        query = "is:open review-requested:\${user}";
      }
      {
        label = "Assigned To Me";
        query = "is:open assignee:\${user}";
      }
      {
        label = "Created By Me";
        query = "is:open author:\${user}";
      }
    ];
    createOnPublishBranch = "never";
  };
  githubIssues = {
    queries = [
      {
        label = "My Issues";
        query = "default";
      }
      {
        label = "Created Issues";
        query = "author:\${user} state:open repo:\${owner}/\${repository} sort:created-desc";
      }
    ];
  };
  generic-input-methods.input-methods = [
    {
      name = "Unicode Math";
      commandName = "text.math";
      languages = [
        "markdown"
        "F#"
      ];
      triggers = [ "\\" ];
      dictionary = [ "defaults/math.json" ];
    }
  ];

  # languages
  python = {
    linting.flake8Enabled = true;
    condaPath = "~/.local/share/miniconda3/bin/conda";
    formatting.provider = "black";
    languageServer = "Pylance";
    analysis = {
      typeCheckingMode = "strict";
      autoImportCompletions = false;
    };
    linting.flake8Args = [
      "--max-line-length=88"
      "--ignore=E203, W503, W504"
    ];
  };
  jupyter = {
    askForKernelRestart = false;
    sendSelectionToInteractiveWindow = true;
    alwaysTrustNotebooks = true;
    allowUnauthorizedRemoteConnection = true;
  };
  autoDocstring.docstringFormat = "google";
  go.formatTool = "gofmt";
  nix.enableLanguageServer = true;
  shellformat.flag = "-i=2";
  markdown.marp.enableHtml = true;
  textlint = {
    autoFixOnSave = true;
    run = "onType";
  };
  FSharp = {
    useSdkScripts = true;
    suggestGitignore = false;
    smartIndent = true;
    dotNetRoot = "dotnet";
    addFsiWatcher = true;
    inlayHints = {
      enabled = false;
      parameterNames = false;
      typeAnnotations = false;
    };
  };
  grunt.autoDetect = "on";
  latex-workshop = {
    message.update.show = false;
    view.pdf.viewer = "tab";
    latex = {
      autoClean.run = "onBuilt";
      recipes = [
        {
          name = "latexmk (latexmkrc)";
          tools = [ "latexmk_rconly" ];
        }
        {
          name = "latexmk 🔃";
          tools = [ "latexmk" ];
        }
        {
          name = "latexmk (lualatex)";
          tools = [ "lualatexmk" ];
        }
        {
          name = "pdflatex ➞ bibtex ➞ pdflatex × 2";
          tools = [
            "pdflatex"
            "bibtex"
            "pdflatex"
            "pdflatex"
          ];
        }
        {
          name = "Compile Rnw files";
          tools = [
            "rnw2tex"
            "latexmk"
          ];
        }
      ];
    };
  };
})
// {
  # nested config
  "[json]" = {
    "editor.quickSuggestions" = {
      strings = true;
    };
    "editor.suggest.insertMode" = "replace";
    "editor.tabSize" = 2;
  };
  "[jsonc]" = {
    "editor.defaultFormatter" = "vscode.json-language-features";
  };
  "[typescriptreact]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };
  "[fsharp]" = {
    "editor.tabSize" = 4;
  };
  "[python]" = {
    "editor.tabSize" = 4;
    "editor.codeActionsOnSave" = {
      "source.organizeImports" = true;
    };
  };
  "editor.tokenColorCustomizations" = {
    comments = {
      fontStyle = "bold";
    };
    strings = {
      fontStyle = "bold";
    };
  };
  "workbench.colorCustomizations" = {
    "[Nord]" = {
      "editor.findMatchHighlightBackground" = "#88C0D090";
      "editorBracketHighlight.foreground1" = "#eceff4";
      "editorBracketHighlight.foreground2" = "#d08770";
      "editorBracketHighlight.foreground3" = "#b48ead";
    };
  };
  "workbench.editorAssociations" = {
    "*.ipynb" = "jupyter-notebook";
    "*.pdf" = "default";
  };
  "notebook.cellToolbarLocation" = {
    default = "right";
    jupyter-notebook = "left";
  };
  "files.watcherExclude" = {
    "**/.bloop" = true;
    "**/.metals" = true;
    "**/.ammonite" = true;
  };
}
