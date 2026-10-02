# Schéma d'architecture multi-environnement — NeoCargo TrackFleet

Les deux environnements sont **deux instances des mêmes trois modules Terraform**
(`network`, `compute`, `data`), chacune dans son propre VPC, avec son propre
state local. Seules les valeurs de `terraform.tfvars` diffèrent.

> Le diagramme ci-dessous est rendu automatiquement par GitHub (Mermaid).
> Pour le rapport PDF / la soutenance, on peut l'exporter en PNG depuis
> <https://mermaid.live> (copier-coller le bloc).

## 1. Vue d'ensemble

```mermaid
flowchart TB
    user(["👤 Utilisateurs<br/>Internet"])
    admin(["🛠️ Équipe infra<br/>Terraform + Ansible"])

    subgraph CODE["Dépôt Git (GitHub) — main protégée, PR + revue obligatoires"]
        direction LR
        mods["terraform/modules/<br/>network · compute · data<br/>(code UNIQUE)"]
        tfs["environments/staging/terraform.tfvars"]
        tfp["environments/prod/terraform.tfvars"]
        roles["ansible/roles/<br/>common · webserver · monitoring"]
        gvs["group_vars/staging.yml"]
        gvp["group_vars/prod.yml"]
    end

    subgraph STG["🟧 STAGING — VPC 10.10.0.0/16 — state : environments/staging/terraform.tfstate"]
        direction TB
        subgraph STG_PUB["Public 10.10.1.0/24 · 10.10.2.0/24"]
            s_alb["ALB<br/>neocargo-staging-alb"]
            s_bas["Bastion SSH"]
            s_nat["NAT Gateway"]
        end
        subgraph STG_APP["App privé 10.10.11.0/24 · 10.10.12.0/24"]
            s_asg["ASG t3.micro<br/>min 1 / max 2<br/>nginx + node_exporter"]
        end
        subgraph STG_DATA["Data isolé 10.10.21.0/24 · 10.10.22.0/24"]
            s_rds[("RDS PostgreSQL<br/>db.t3.micro<br/>backup 0 j")]
        end
        s_s3[("S3 assets<br/>force_destroy = true")]
    end

    subgraph PRD["🟥 PROD — VPC 10.20.0.0/16 — state : environments/prod/terraform.tfstate"]
        direction TB
        subgraph PRD_PUB["Public 10.20.1.0/24 · 10.20.2.0/24"]
            p_alb["ALB<br/>neocargo-prod-alb"]
            p_bas["Bastion SSH"]
            p_nat["NAT Gateway"]
        end
        subgraph PRD_APP["App privé 10.20.11.0/24 · 10.20.12.0/24"]
            p_asg["ASG t3.small<br/>min 2 / max 4<br/>nginx + node_exporter"]
        end
        subgraph PRD_DATA["Data isolé 10.20.21.0/24 · 10.20.22.0/24"]
            p_rds[("RDS PostgreSQL<br/>db.t3.micro<br/>backup 1 j")]
        end
        p_s3[("S3 assets<br/>force_destroy = false")]
    end

    mods --> tfs & tfp
    tfs -. "terraform apply<br/>(dossier staging)" .-> STG
    tfp -. "terraform apply<br/>(dossier prod)" .-> PRD
    roles --> gvs & gvp

    user -- "HTTP :80" --> s_alb
    user -- "HTTP :80" --> p_alb
    s_alb -- ":80" --> s_asg
    p_alb -- ":80" --> p_asg
    s_asg -- ":5432" --> s_rds
    p_asg -- ":5432" --> p_rds
    s_asg -- "apt (sortant)" --> s_nat
    p_asg -- "apt (sortant)" --> p_nat

    admin -- "SSH :22" --> s_bas
    admin -- "SSH :22" --> p_bas
    s_bas -- "Ansible SSH :22<br/>node_exporter :9100" --> s_asg
    p_bas -- "Ansible SSH :22<br/>node_exporter :9100" --> p_asg
    gvs -. "ansible-playbook<br/>-e target_env=staging" .-> s_bas
    gvp -. "ansible-playbook<br/>-e target_env=prod" .-> p_bas

    classDef stg fill:#fdebd0,stroke:#e67e22,color:#000
    classDef prd fill:#fadbd8,stroke:#c0392b,color:#000
    classDef code fill:#d6eaf8,stroke:#2874a6,color:#000
    class STG,STG_PUB,STG_APP,STG_DATA stg
    class PRD,PRD_PUB,PRD_APP,PRD_DATA prd
    class CODE code
```

## 2. Légende

| Élément | Signification |
|---|---|
| 🟦 Bloc bleu | Code versionné (un seul exemplaire des modules et des rôles) |
| 🟧 Bloc orange | Environnement **staging** (VPC, state et ressources propres) |
| 🟥 Bloc rouge | Environnement **prod** (VPC, state et ressources propres) |
| Flèche pleine | Flux réseau autorisé par un security group (port indiqué) |
| Flèche pointillée | Action de déploiement (Terraform / Ansible) lancée par l'équipe |
| Cylindre | Stockage de données (RDS, S3) |
| Public / App privé / Data isolé | Les 3 niveaux réseau. *App* sort sur Internet via la NAT uniquement ; *Data* n'a aucune route sortante |

Chaîne des security groups (identique dans les deux environnements) :
`Internet → ALB (80) → app (80) → RDS (5432)` et `admin → bastion (22) → app (22, 9100)`.

## 3. Ce qui différencie staging et prod

| Paramètre | Staging | Prod | Où c'est défini |
|---|---|---|---|
| CIDR VPC | 10.10.0.0/16 | 10.20.0.0/16 | `terraform.tfvars` |
| Type d'instance app | t3.micro | t3.small | `terraform.tfvars` |
| ASG min / desired / max | 1 / 1 / 2 | 2 / 2 / 4 | `terraform.tfvars` |
| Classe RDS | db.t3.micro | db.t3.micro (quota Academy) | `terraform.tfvars` |
| Sauvegardes RDS | 0 jour (jetable) | 1 jour | `terraform.tfvars` |
| S3 `force_destroy` | true (détruit/recréé souvent) | false (protège les objets) | `terraform.tfvars` |
| Niveau de log nginx | info | warn | `group_vars/*.yml` |
| Page de debug | affichée | masquée | `group_vars/*.yml` |
| Log node_exporter | debug | info | `group_vars/*.yml` |
| Contrôle de santé (cron) | toutes les 1 min, logue aussi les succès | toutes les 5 min, erreurs seulement | `group_vars/*.yml` |
| Seuil d'alerte disque | 90 % | 80 % | `group_vars/*.yml` |
| Tag `Environment` | staging | prod | `locals` de `main.tf` (depuis `var.environment`) |
| Fichier de state | `environments/staging/terraform.tfstate` | `environments/prod/terraform.tfstate` | backend local |
