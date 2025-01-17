{ stdenv, writeScript, coreutils, glibc, git, openssh, gnused, mkdocs }:

with stdenv.lib;

let
  repo = "git@github.com:input-output-hk/haskell.nix.git";
  sshKey = "/run/keys/buildkite-haskell-dot-nix-ssh-private";
in
  writeScript "update-docs.sh" ''
    #!${stdenv.shell}

    set -euo pipefail

    export PATH="${makeBinPath [ coreutils glibc git openssh gnused mkdocs ]}"

    source ${./git.env}

    echo "Building..."
    rm -rf site
    mkdocs build
    touch site/.nojekyll
    sed -i -e '/Build Date/d' site/index.html
    sed -i -e '/lastmod/d' site/sitemap.xml
    rm -f site/sitemap.xml.gz
    rev=$(git rev-parse --short HEAD)

    echo "Updating git index..."
    git fetch origin
    git checkout gh-pages
    git reset --hard origin/gh-pages
    GIT_WORK_TREE=$(pwd)/site git add -A
    check_staged
    echo "Committing changes..."
    git commit --no-gpg-sign --message "Update gh-pages for $rev"

    use_ssh_key ${sshKey}

    if [ "''${BUILDKITE_BRANCH:-}" = master ]; then
      git push ${repo} HEAD:gh-pages
    fi
  ''
