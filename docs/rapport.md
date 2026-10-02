# Rapport d'équipe — Plateforme multi-environnements NeoCargo TrackFleet

> **Mastère Cybersécurité 4A — Gestion des configurations & IaC — IPSSI**
> Équipe : _[Prénom NOM]_, _[Prénom NOM]_, _[Prénom NOM]_, _[Prénom NOM]_
> Dépôt : <https://github.com/Lirys1/tp_group_aws_adv>

> ⚠️ Les passages entre `[crochets]` / marqués **À COMPLÉTER** doivent être
> remplis par l'équipe avec ce qui s'est **réellement** passé (le barème évalue
> la collaboration réelle, pas une reconstitution).

---

## 1. Contexte et objectifs

NeoCargo Analytics doit fournir à deux clients grands comptes un environnement
de **préproduction (staging) représentatif de la production** et une
**traçabilité complète** des changements d'infrastructure. Notre mission :

1. réorganiser le code existant (fichiers `.tf` à plat + playbook monolithique)
   en **modules Terraform** et **rôles Ansible** réutilisables ;
2. dupliquer la prod en staging **en ne changeant que des variables** ;
3. mettre en place un **processus Git d'équipe** (main protégée, PR, revue croisée).

Les briques AWS (VPC 3 niveaux, ALB, ASG, RDS, S3) sont reprises du TP individuel
et ne sont pas ré-expliquées ici.

---

## 2. Répartition des rôles réellement appliquée — **À COMPLÉTER**

| Membre | Rôle principal | Périmètre piloté | Revues effectuées | PR ouvertes |
|---|---|---|---|---|
| [Nom] | Responsable réseau | `terraform/modules/network` | [PR #…] | [PR #…] |
| [Nom] | Responsable compute | `terraform/modules/compute` | [PR #…] | [PR #…] |
| [Nom] | Responsable données + environnements | `terraform/modules/data`, `terraform/environments/` | [PR #…] | [PR #…] |
| [Nom] | Responsable Ansible | `ansible/` (rôles, inventaire, group_vars) | [PR #…] | [PR #…] |

**Pourquoi cette répartition :** [à compléter — ex : affinités, TP individuel de chacun, disponibilités…]

**Qui a provisionné quoi :** pour éviter deux `apply` simultanés sur le même
state, [Nom] a été seul responsable de l'apply **staging** (sur son Learner Lab)
et [Nom] de l'apply **prod**. [à confirmer / adapter]

---

## 3. Workflow Git (Partie A)

### 3.1 Stratégie de branches

Nous avons retenu **une branche par fonctionnalité** (feature branches), nommée
`type/description-courte`, plutôt qu'une branche par membre :

| Préfixe | Usage | Exemple |
|---|---|---|
| `feat/` | nouvelle fonctionnalité | `feat/module-network` |
| `fix/` | correction | `fix/nat-gateway-app-subnets` |
| `docs/` | documentation | `docs/rapport-equipe` |
| `ci/` | pipeline | `ci/github-actions` |
| `chore/` | maintenance | `chore/gitignore` |

**Justification :** une branche par fonctionnalité donne des PR petites, centrées
sur un seul sujet, donc faciles à relire ; une branche « par membre » vit
longtemps, accumule des changements sans rapport et produit des PR énormes
difficiles à revoir. Les branches ne sont **jamais supprimées** après merge
(exigence du TP : historique consultable).

### 3.2 Protection de `main`

Configurée dans *Settings → Branches → Branch protection rules* sur `main` :

- ✅ *Require a pull request before merging*
- ✅ *Require approvals* : **1** approbation minimum
- ✅ *Dismiss stale pull request approvals when new commits are pushed*
- ✅ *Require status checks to pass* (jobs de la CI, si bonus actif)
- ✅ *Do not allow bypassing the above settings*

> 📸 **Capture à insérer :** écran de la règle de protection.

### 3.3 Convention de commits

Format *Conventional Commits* : `type(scope): description` — ex.
`feat(network): ajoute les sous-réseaux data isolés`,
`fix(ansible): renomme tasks/main.tf en main.yml`.
Scopes utilisés : `network`, `compute`, `data`, `env`, `ansible`, `ci`, `docs`, `security`.

### 3.4 Processus de Pull Request

1. Branche créée depuis `main` à jour ;
2. commits atomiques ;
3. PR avec le modèle `.github/pull_request_template.md` (quoi / pourquoi / comment tester) ;
4. CI verte (fmt, validate, plan, ansible-lint) ;
5. **revue par un autre membre** avec au moins un commentaire substantiel ;
6. merge par l'auteur une fois approuvée.

> 📸 **Captures à insérer (au moins 3 PR) :** liste des PR fermées, une PR avec
> sa description, une revue avec commentaires et demande de modification, la CI.

### 3.5 Incident de sécurité traité

Le premier import du code contenait le fichier `terraform.tfstate` (mot de passe
RDS en clair), la clé privée `ipssi-tp.pem` et un `vault.yml` non chiffré. Ils ont
été retirés du suivi Git et le `.gitignore` a été complété. Comme ils restent
dans l'historique, la paire de clés a été [supprimée/recréée dans AWS — à confirmer]
et le mot de passe RDS est désormais généré par Terraform (plus aucun secret saisi
à la main). [Si l'historique a été réécrit avec `git filter-repo`, le préciser.]

---

## 4. Terraform industrialisé (Partie B)

### 4.1 Découpage en modules

```
terraform/
├── modules/
│   ├── network/   VPC, 6 sous-réseaux (public/app/data × 2 AZ), IGW, NAT, 3 tables de routage, 4 SG
│   ├── compute/   AMI, Launch Template, ALB, Target Group, Listener, ASG + scaling CPU, bastion
│   └── data/      mot de passe aléatoire, DB subnet group, RDS PostgreSQL, bucket S3 chiffré/versionné
└── environments/
    ├── staging/   main.tf (appel des 3 modules) + terraform.tfvars + state local
    └── prod/      idem, seules les valeurs de terraform.tfvars changent
```

**Interfaces entre modules** — les modules ne se connaissent pas entre eux ;
c'est `environments/<env>/main.tf` qui branche les outputs de l'un sur les
entrées de l'autre :

| Output de `network` | consommé par |
|---|---|
| `vpc_id`, `public_subnet_ids`, `app_subnet_ids` | `compute` |
| `alb_security_group_id`, `app_security_group_id`, `bastion_security_group_id` | `compute` |
| `data_subnet_ids`, `rds_security_group_id` | `data` |

**Aucune valeur d'environnement en dur dans les modules :** noms
(`name_prefix`), CIDR, types d'instance, tailles d'ASG, classe RDS, rétention,
`force_destroy` sont tous des variables. Les seules valeurs par défaut
conservées sont des constantes techniques identiques partout (port 5432,
AMI Ubuntu 22.04 Canonical, chemin `/health`). Des blocs `validation` protègent
les entrées (CIDR valide, ≥ 2 sous-réseaux, nom en minuscules, longueur max).

### 4.2 Workspaces vs dossiers séparés — choix : **dossiers séparés**

| Critère | Workspaces (`terraform workspace`) | Dossiers séparés (`environments/<env>/`) |
|---|---|---|
| Isolation du state | States distincts mais dans le **même dossier/backend** (`terraform.tfstate.d/<ws>/`) | Un state par dossier, totalement indépendant |
| Risque d'appliquer sur le mauvais env | **Élevé** : le workspace courant est un état invisible ; oublier `terraform workspace select prod` suffit | **Faible** : l'environnement = le dossier où l'on se trouve (`cd environments/prod`), visible dans le chemin |
| Lisibilité | Différences cachées dans des `lookup(var.x, terraform.workspace)` ou des tfvars choisis à la main | Chaque env a son `terraform.tfvars` lisible et versionné |
| Duplication | Aucune (un seul `main.tf`) | Petit « code de colle » dupliqué (`main.tf`, `variables.tf`) — mais les **modules** ne sont jamais dupliqués |
| Divergence possible | Impossible : même code pour tous | Possible (ex : ajouter un module seulement en staging pour le tester) |
| Backend différent par env | Non (même backend) | Oui (chaque dossier peut avoir son backend) |

**Pourquoi les dossiers séparés dans notre contexte :**

- **Pas de backend distant partagé** (pas de S3+DynamoDB, comptes Academy
  individuels) : le state est local. Avec des dossiers, le state de staging et
  celui de prod sont des fichiers physiquement séparés ; un `destroy` dans
  `environments/staging/` ne peut techniquement pas toucher la prod.
- **Comptes AWS différents par personne** : staging et prod peuvent même être
  appliqués depuis deux Learner Labs différents, chacun par son responsable.
- **Sécurité opérationnelle** : l'environnement visé se lit dans le chemin du
  terminal, pas dans un état caché ; c'est la recommandation HashiCorp pour des
  environnements qui doivent rester strictement isolés.
- **Coût accepté** : `main.tf` et `variables.tf` sont recopiés à l'identique
  (≈ 60 lignes de câblage). Tout le code métier reste dans les modules.

### 4.3 Gestion des secrets

- Le mot de passe RDS est généré par `random_password` dans le module `data`,
  exposé uniquement via un output `sensitive` ; aucun humain ne le choisit ni ne
  l'écrit dans un fichier.
- Les `terraform.tfvars` versionnés ne contiennent **aucun secret** (CIDR,
  tailles…). Les éventuelles valeurs personnelles vont dans `secrets.auto.tfvars`
  (ignoré par Git).
- Limite connue : le mot de passe reste lisible dans le `terraform.tfstate` local
  (jamais commité). En entreprise, on utiliserait un backend chiffré à accès
  restreint ou `manage_master_user_password` (Secrets Manager).

### 4.4 Contraintes AWS Academy respectées

- Aucune ressource `aws_iam_role` / `aws_iam_instance_profile` : le Launch
  Template réutilise `LabInstanceProfile` (variable `instance_profile_name`).
- Classe RDS `db.t3.micro` dans les deux environnements (quota).
- Identifiants temporaires (`ASIA…`) propres à chaque membre, jamais commités.

### 4.5 Corrections apportées au code d'origine

- **NAT Gateway ajoutée** : les sous-réseaux app n'avaient aucune route vers
  Internet, donc le `apt install nginx` du user_data échouait et les health
  checks de l'ALB ne pouvaient pas passer.
- Sous-réseaux data rattachés à une table de routage isolée explicite.
- IMDSv2 obligatoire sur les instances, chiffrement du stockage RDS.
- `instance_refresh` sur l'ASG : un changement de Launch Template remplace les
  instances progressivement.

---

## 5. Ansible en rôles (Partie C)

### 5.1 Rôles

| Rôle | Contenu | Structure |
|---|---|---|
| `common` | cache apt, paquets de base, fuseau horaire, durcissement SSH | tasks, handlers, defaults |
| `webserver` | nginx, vhost TrackFleet, page d'accueil, `/health`, test de connexion RDS | tasks, handlers, templates, defaults |
| `monitoring` | `prometheus-node-exporter` (port 9100) + script de contrôle (nginx, `/health`, disque) lancé par cron, résultats dans syslog | tasks, handlers, templates, defaults |

Toutes les variables d'un rôle sont préfixées par son nom (`webserver_*`,
`monitoring_*`) et documentées dans `defaults/main.yml`. Le handler nginx valide
la configuration (`nginx -t`) **avant** de recharger le service.

### 5.2 Inventaire dynamique

Plugin `amazon.aws.aws_ec2` (`ansible/inventory/aws_ec2.yml`) :
- filtre `tag:Project = neocargo` et instances `running` ;
- groupes construits depuis les tags posés par Terraform : `staging` / `prod`
  (tag `Environment`) et `app` / `bastion` (tag `Role`) ;
- `site.yml` cible `"{{ target_env }}:&app"` (intersection) : **un seul
  environnement à la fois**. Sans `-e target_env=…`, aucun hôte n'est ciblé.
- Garde-fou : une assertion vérifie que les variables chargées
  (`scripts/tf_env.sh <env>`) correspondent bien à `target_env`.

Connexion : les instances app sont privées ; Ansible passe par le **bastion du
même environnement** (ProxyCommand calculé dynamiquement depuis l'inventaire,
`group_vars/app.yml`). Nous avons écarté la connexion SSM (configurée à l'origine
mais jamais fonctionnelle : ni plugin session-manager, ni bucket de transfert).

### 5.3 Variables différenciées par environnement

`group_vars/staging.yml` vs `group_vars/prod.yml` : niveau de log nginx
(info / warn), page de debug (affichée / masquée), log node_exporter
(debug / info), fréquence et verbosité du contrôle de santé (1 min + succès /
5 min erreurs seules), seuil disque (90 % / 80 %).

### 5.4 Vérification de l'idempotence — **À COMPLÉTER avec captures**

```bash
source scripts/tf_env.sh staging
ansible-playbook site.yml -e target_env=staging   # 1er passage : changed > 0
ansible-playbook site.yml -e target_env=staging   # 2e passage : changed=0
```

> 📸 **Capture à insérer :** le `PLAY RECAP` du 2e passage avec `changed=0`.

Choix qui garantissent l'idempotence : modules déclaratifs (`apt`, `template`,
`file`, `lineinfile`, `cron`) ; le test de connexion RDS est en lecture seule
(`changed_when: false`) ; `apt update` n'est relancé que si le cache a plus d'1 h.

---

## 6. Pipeline CI (BONUS)

`.github/workflows/ci.yml`, déclenché sur chaque PR vers `main` :
`terraform fmt -check` → `terraform init` + `validate` (staging et prod) →
`terraform plan` (si les secrets AWS du dépôt sont renseignés) → `ansible-lint`
(profil *production*). **Aucun `terraform apply`** : la CI informe les relecteurs,
elle ne déploie pas.

Limite : les identifiants AWS Academy expirent toutes les ~4 h ; il faut mettre à
jour les secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`
avant une session de travail, sinon l'étape `plan` est sautée (fmt/validate/lint
tournent toujours). Le plan en CI part d'un state vide (state local) : il montre
donc la création complète, utile pour valider la cohérence mais pas le diff réel.

---

## 7. Schéma d'architecture

Voir [`docs/architecture.md`](architecture.md) (diagramme, légende, tableau des
différences staging/prod).

---

## 8. Retour d'expérience d'équipe — **À COMPLÉTER honnêtement**

Questions pour guider la rédaction (sur la **collaboration**, pas seulement le code) :

- **Ce qui a bien fonctionné :** [ex : les revues ont détecté … ; la répartition par module a permis …]
- **Ce qui a mal fonctionné :** [ex : conflits de merge sur … ; un premier import sans PR ; secrets commités au départ ; attente des revues…]
- **Ce qu'on a corrigé en cours de route :** [ex : protection de main activée après … ; convention de commits adoptée à partir de …]
- **Difficultés liées à l'environnement :** identifiants Academy expirant toutes les 4 h ;
  registre Terraform inaccessible depuis [pays] (contourné avec OpenTofu, compatible) ;
  impossibilité de créer des rôles IAM (comportement attendu) ; [autres]
- **Ce qu'on ferait autrement :** [ex : protéger main dès la 1re minute ; backend distant partagé en contexte réel…]

---

## 9. Nettoyage

```bash
cd terraform/environments/staging && terraform destroy
cd ../prod && terraform destroy
```

Puis vérification dans la console AWS (eu-west-3) de chaque membre ayant fait
un apply : aucune instance EC2, aucune instance RDS, aucun ALB, aucune NAT
Gateway / Elastic IP restante. > 📸 **Capture à insérer.**
