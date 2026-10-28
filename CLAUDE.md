# docmail

## Règles inconditionnelles
- Dépôt public MIT : tout ce qui est commité se lit dans le monde entier, historique compris ; aucun chemin personnel, hôte, mail ni jeton, ni dans les fichiers ni dans les messages de commit ; les vraies valeurs vivent dans `~/docmail.conf` (ignoré) et les fichiers `*.local.*`.
- Aucun envoi réel pendant une vérification : un 2xx du webhook prouve seulement que le POST est arrivé, pas que le mail est parti ; le contrôle de bout en bout (`/docmail now …`) envoie un vrai mail et demande l'accord écrit du propriétaire du dépôt.
- `skill/scripts/scan-secrets.sh` est la frontière de sécurité avant tout envoi : on y étend les motifs, pas dans la prose du skill ; un marqueur `.sent` ne se crée jamais à la main.
- Docs en anglais ; une clé de config ou un code de sortie qui change met à jour `README.md` (tableau Configuration, arborescence, FAQ) et `docmail.conf.example` dans la même PR.
- Architecture, commandes, flux d'exécution, déploiement du récepteur n8n et conventions : `docs/architecture.md`.

<!-- gen:debut -->
Dépôt `Moodtuner997/docmail` (projet `docmail`, docmail, statut actif). Déploiement : aucun (pas de déploiement).
Avant toute action : `gh issue list --label etat` (l'issue État, vérité opérationnelle), `git fetch --prune`, `just --list` (points d'entrée uniformes : test, lint, dev, build, deploy-staging).
Tâches = issues GitHub ; état du dépôt = issue épinglée État ; mémoire longue = nœud `02-projets/docmail.md` du second cerveau. Rien d'autre ne fait foi.
Enveloppe : PR vers `dev`, fusion si CI verte ; `staging` et `main` n'avancent que par tag (release.yml, release.sh). Secrets jamais lus. Généré par scripts/claude-md-gen.py : ne pas éditer ce bloc.
<!-- gen:fin -->

## Pièges
- `$json` après un nœud `emailSend` contient la réponse SMTP : rien n'était archivé et le récap renvoyait les mêmes documents chaque matin ; lire le producteur par `$('List Files').first().json` (c89a9be, 2026-05-23), garde-fou en 6ea48d3.
- Les chaînes littérales `/home/node/docmail`, `YOUR_SMTP_CREDENTIAL_ID`, `"SMTP account"`, `Europe/Paris`, `"triggerAtHour": 8` des workflows doivent rester intactes, sinon le `sed` de `install.sh` ne les remplace plus sans erreur (6 lignes concernées par workflow, comptées le 2026-10-28).
- `send-webhook.sh` sans 2ᵉ argument retombe sur `batch` (avertissement sur stderr seulement, ligne 20) : le mail ne part qu'au récap du lendemain ; toujours passer `instant`, et le nom de fichier seul, pas un chemin.
- Un envoi raté reste dans `queue/` et rien ne le relance (aucun workflow n'appelle `send-webhook.sh`, `install.sh` ne planifie rien) ; README et `SKILL.md` disent encore « le cron du matin relance » : périmé (README ligne 124, SKILL.md lignes 159-160).
- Aucun workflow à jeton (revue automatique) sur ce dépôt public, runner GitHub seulement (86f65fd, 2026-10-02).
- `IDEES.md` reste ignoré, aucune idée privée dans un fichier suivi (5cdbc7b, 2026-10-12) ; `*.html` est ignoré hors `examples/`, donc un document généré ne se commite pas.
- Le public v2 a dû être rendu neutre pour l'utilisateur après des valeurs réelles commitées (3ffb5a4, 2026-07-22) ; un chemin absolu de lecteur Windows ou du profil utilisateur dans un fichier suivi bloque aussi le push (gitleaks).
- Messages de commit au format conventionnel, sinon ils disparaissent des releases ; `docs`, `ci`, `chore`, `test`, `style` sont masqués du changelog (`release-please-config.json`).
