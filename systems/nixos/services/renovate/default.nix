{ config, ... }:
{
  # I self-host Renovate rather than staying on the Mend-hosted app for the one
  # thing the hosted version cannot offer: postUpgradeTasks. A regex manager can
  # bump a hardcoded `version` in a Nix expression, but nothing in Renovate can
  # recompute the `hash` that goes with it, and the hosted app refuses to run
  # commands. Self-hosted, update-nix-hash runs right after the bump and the
  # pull request arrives buildable.
  #
  # Bootstrap, once, by hand:
  #
  # 1. Create a GitHub App of its own -- not the one the workflows use, whose
  #    key any workflow run can reach -- with repository permissions Contents
  #    RW, Pull requests RW, Issues RW, Workflows RW, Metadata R. Install it on
  #    the repositories listed below, note its App ID for `appId`, and generate
  #    a private key.
  # 2. Put a password for the Forgejo bot in ../forgejo/secrets.yaml as
  #    forgejo-renovate-password; the next forgejo start creates the account.
  #    Mint its token over the API -- the CLI would print it to the journal:
  #
  #      curl -u renovate:PASSWORD https://git.natsukium.com/api/v1/users/renovate/tokens \
  #        -H 'content-type: application/json' \
  #        -d '{"name":"renovate","scopes":["write:repository","read:user","write:issue","read:organization"]}'
  #
  #    Each Forgejo repository listed below also needs renovate as a
  #    collaborator with write access.
  # 3. Mint a fine-grained github.com token with no permissions.
  # 4. sops modules/features/renovate/secrets.yaml and fill in
  #    renovate-github-app-key, renovate-forgejo-token and
  #    renovate-github-com-token.
  # 5. Remove each migrated repository from the hosted app's installation, or
  #    both bots will open the same pull request.
  my.services.renovate = {
    enable = true;

    instances.github = {
      schedule = "hourly";

      githubApp = {
        appId = 4535054;
        privateKeyFile = config.sops.secrets.renovate-github-app-key.path;
      };

      settings = {
        platform = "github";
        # I list repositories rather than autodiscover so the move off the
        # hosted app happens one repository at a time.
        repositories = [ "natsukium/dotfiles" ];
        # Every repository here already carries its own config; an onboarding
        # pull request would only be noise.
        onboarding = false;
        # Commits go through the API, so GitHub signs them and attributes them
        # to the App instead of to an unverified local git author.
        platformCommit = "enabled";
        # postUpgradeTasks runs nothing unless the command matches; I allow only
        # update-nix-hash so a repository config cannot turn a dependency bump
        # into arbitrary code execution on this host.
        allowedCommands = [ "^update-nix-hash .+$" ];
      };
    };

    instances.forgejo = {
      # I offset this from the GitHub run so the two do not build Nix
      # expressions at the same time.
      schedule = "*:30";

      credentials = {
        RENOVATE_TOKEN = config.sops.secrets.renovate-forgejo-token.path;
        # Lifts the anonymous 60 requests/hour ceiling this run hits fetching
        # changelogs from github.com; no permissions are needed on it.
        GITHUB_COM_TOKEN = config.sops.secrets.renovate-github-com-token.path;
      };

      settings = {
        platform = "forgejo";
        endpoint = "https://${config.services.forgejo.settings.server.DOMAIN}/";
        repositories = [ "natsukium/felis" ];
        onboarding = false;
      };
    };
  };
}
