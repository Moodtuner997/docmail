# Points d'entrée du dépôt (règle commune : `just --list` avant d'agir). Outil shell sans build ni serveur ; gabarit : scripts/gabarits/justfile.node, adapté.
set windows-shell := ["bash", "-c"]
set shell := ["bash", "-c"]

# Teste scan-secrets.sh sans réseau ni envoi : exemple propre (code 0), faux secret fabriqué à l'exécution (code 1), fichier absent (code 2)
test:
    bash skill/scripts/scan-secrets.sh examples/example-docmail.html >/dev/null; [ $? -eq 0 ] || { echo "ECHEC: l'exemple propre est bloqué"; exit 1; }; f=$(mktemp); printf 'cle sk-ant-%s\n' "$(printf 'a%.0s' $(seq 1 30))" > "$f"; bash skill/scripts/scan-secrets.sh "$f" >/dev/null 2>&1; code=$?; rm -f "$f"; [ $code -eq 1 ] || { echo "ECHEC: faux secret non bloqué (code $code)"; exit 1; }; bash skill/scripts/scan-secrets.sh /absent.html >/dev/null 2>&1; [ $? -eq 2 ] || { echo "ECHEC: fichier absent sans code 2"; exit 1; }; echo "scan-secrets: 0/1/2 conformes"

# Syntaxe bash des scripts, JSON des workflows n8n valides, shellcheck s'il est installé
lint:
    for f in install.sh skill/scripts/*.sh; do bash -n "$f" || exit 1; done; for f in workflows/*.json; do jq empty "$f" || exit 1; done; if command -v shellcheck >/dev/null 2>&1; then shellcheck install.sh skill/scripts/*.sh; else echo "shellcheck absent : ignoré"; fi

# Pas de serveur : outil local, se lance par /docmail dans Claude Code après `bash install.sh`
dev:
    echo "outil local sans serveur : voir docs/architecture.md"

# Rien à construire
build:
    echo "rien à construire"

# Pas de staging : branche unique master, PR + fusion squash, tag par release-please
deploy-staging:
    echo "pas de staging : PR vers master, fusion squash, release-please tague"
