---
layout: post
title: Chapitre 5 - Configuration
date: 2025-06-16
---

On dénombre pas moins de 378 paramètres de configuration dans PostgreSQL 17, et ce nombre continue de croître à chaque nouvelle version.  
Nous aurons l'occasion d'examiner une grande partie de ces paramètres tout au long de cette série d'articles. Aujourd'hui, nous allons aborder quelques généralités concernant la configuration de PostgreSQL.

Nous nous concentrerons ici sur les paramètres de configuration internes du serveur PostgreSQL, en excluant le paramétrage lié au contrôle d'accès et à l'authentification des utilisateurs, qui fera l'objet d'un article distinct.

# Prologue : pg_settings

Tout cluster PostgreSQL possède un ensemble de "vues système" fournissant des informations sur le cluster, l'instance et leur état. Ces vues sont disponibles via le schéma `pg_catalog` présent dans chaque base de données du cluster.

Avant d'entrer dans le vif du sujet, nous allons nous intéresser à une vue système qui nous accompagnera tout au long de cet article. Cette vue, nommée `pg_settings`, fournit des informations relatives à la configuration du cluster :

~~~sql
SELECT *
FROM pg_catalog.pg_setting
WHERE name='port';
~~~

~~~text
-[ RECORD 1 ]---+-----------------------------------------------------
name            | port
setting         | 5432
unit            |
category        | Connections and Authentication / Connection Settings
short_desc      | Sets the TCP port the server listens on.
extra_desc      |
context         | postmaster
vartype         | integer
source          | default
min_val         | 1
max_val         | 65535
enumvals        |
boot_val        | 5432
reset_val       | 5432
sourcefile      |
sourceline      |
pending_restart | f
~~~

La vue nous renseigne sur la valeur actuelle du paramètre (`setting`), mais aussi sa valeur minimale et maximale lorsqu’il s’agit d’un nombre (`min_val`, `max_val`), ou les valeurs possibles lorsque celles-ci sont strictement limitées (`enumvals`). On dispose également de la valeur par défaut de chaque paramètre (`boot_val`), et de la valeur qu’il prendra s’il est réinitialisé (`reset_val`).

# Sources de configuration

La configuration d'un cluster PostgreSQL peut provenir de différentes sources, avec une hiérarchie entre celles-ci. Si un paramètre est défini à plusieurs endroits, c’est le niveau de configuration le plus spécifique qui prévaut.  
Notons que `pg_settings` présente le champ `source` qui indique la provenance d'un paramétrage.

Nous allons aborder ces canaux de configuration dans l'ordre croissant de leur spécificité, et donc de leur prévalence.

## La configuration par défaut

Le paramétrage par défaut constitue bien évidemment la première source de configuration. À quelques exceptions près, tous les paramètres disposent d'une valeur par défaut. Par exemple, le paramètre `port`, s'il n'est spécifié nulle part, prend la valeur "5432". Dans ce cas, le champ `source` de `pg_settings` affichera "default".

## Le fichier de configuration de l'instance

Un cluster PostgreSQL possède nécessairement un fichier de configuration. Le nom et l'emplacement de ce fichier ne peuvent être définis qu'au démarrage d'une instance, avec l'option `--config-file` des commandes `postgres` et `pg_ctl`. Traditionnellement, ce fichier est nommé `postgresql.conf` et placé à la racine du répertoire des données (`PGDATA`), ce qui correspond à la valeur par défaut du paramètre `config_file`.

Le fichier utilise un format "clé = valeur" pour définir la valeur de chaque paramètre. Il dispose d’une syntaxe permettant d'inclure d’autres fichiers et même des répertoires, ce qui permet de répartir la configuration sur plusieurs fichiers, mais le point d'entrée sera toujours le fichier pointé par `config_file`.

Ci-dessous, un exemple de fichier de configuration :

~~~text
port = 5432
data_directory = '/var/lib/pgsql/data'
cluster_name = 'pg101'
config_file = '/var/lib/pgsql/data/postgresql.conf'
log_directory = '/var/log/postgresql'
log_filename = 'postgresql.log'

include './memoire.conf'
include_dir 'conf.d'
~~~

Attention : l'ordre d'inclusion des fichiers est important, car si un paramètre est défini à plusieurs endroits, seule la dernière valeur configurée est appliquée.

Au niveau de `pg_settings`, le champ `source` indiquera "configuration file", et les champs `sourcefile` et `sourceline` seront renseignés pour identifier le fichier ainsi que la ligne configurant ce paramètre. Par exemple, si le `port` est défini dans le fichier de configuration :

~~~sql
SELECT name, setting, source, sourcefile, sourceline
FROM pg_settings
WHERE name='port';
~~~

~~~text
-[ RECORD 1 ]--------------------------------------
name       | port
setting    | 5433
source     | configuration file
sourcefile | /var/lib/pgsql/17/data/postgresql.conf
sourceline | 64
~~~

## La commande ALTER SYSTEM

La commande `ALTER SYSTEM` est une commande interne à PostgreSQL qui permet de modifier le paramétrage d'un cluster. Elle nécessite une connexion à l'instance. Par exemple :

~~~sql
ALTER SYSTEM SET cluster_name='postgresql101';
~~~

En interne, la commande manipule un fichier de configuration un peu particulier placé au niveau du `PGDATA` : `postgresql.auto.conf`. Ce fichier ne doit pas être modifié manuellement et sa gestion doit être exclusivement réservée à `ALTER SYSTEM`.

Du point de vue de `pg_settings`, `postgresql.auto.conf` est un simple fichier de configuration. La vue nous renverra donc des informations similaires pour les champs `source`, `sourcefile` et `sourceline` :

~~~sql
SELECT name, setting, source, sourcefile, sourceline
FROM pg_settings
WHERE name='cluster_name';
~~~

~~~text
-[ RECORD 1 ]-------------------------------------------
name       | cluster_name
setting    | postgresql101
source     | configuration file
sourcefile | /var/lib/pgsql/17/data/postgresql.auto.conf
sourceline | 4
~~~

## Les options de démarrage

Lors du démarrage d'une instance, il est possible de surcharger la configuration via l'option `--option` de `pg_ctl` ou l'option `-c` de `postgres`. Dans `pg_settings`, les paramètres ainsi définis auront pour `source` la valeur "command line".

Par exemple, l'instance peut être démarrée avec l'une ou l'autre de ces deux commandes :

~~~bash
pg_ctl start --option='-c port=5555'
# Ou
postgres -c port=5555
~~~

Dans ce cas, si on interroge `pg_settings` :

~~~sql
SELECT name, setting, source
FROM pg_settings
WHERE name='port';
~~~

~~~text
-[ RECORD 1 ]---------
name    | port
setting | 5555
source  | command line
~~~

La valeur des paramètres définis par cette méthode est éphémère. Si l’instance est arrêtée et que le paramètre n’est pas de nouveau explicitement fourni dans la prochaine commande de démarrage, il reprendra sa valeur initiale (celle par défaut ou celle définie dans les fichiers de configuration). Notons que lors d'un redémarrage avec `pg_ctl restart`, les options de démarrage sont conservées.

## La configuration par base de données avec ALTER DATABASE

La commande `ALTER DATABASE` permet de modifier une base de données au sein d'un cluster. Il est par exemple possible de modifier le nom d'une base de données à l'aide de cette commande. En ce qui nous concerne, elle permet en particulier de modifier la valeur des paramètres de configuration pour une base de données spécifique. La nouvelle configuration s’applique aux futures connexions à celle-ci.

Par exemple :

~~~sql
ALTER DATABASE mydb SET work_mem='64MB';
~~~

La `source` dans `pg_settings` est alors naturellement "database" :

~~~sql
SELECT name, setting, source
FROM pg_settings
WHERE name='work_mem';
~~~

~~~text
-[ RECORD 1 ]-----
name    | work_mem
setting | 65536
source  | database
~~~

## La configuration par rôle avec ALTER ROLE

Nous n'avons pas encore évoqué la notion de "rôle" dans PostgreSQL. Pour l'heure, nous allons simplement considérer qu'un rôle est un utilisateur du cluster.

Dans ce cadre, `ALTER ROLE` permet de modifier un rôle (son nom, son mot de passe ou ses droits par exemple) et en particulier la valeur des paramètres qui lui sont appliqués. La nouvelle configuration s’applique, comme pour `ALTER DATABASE`, uniquement aux futures connexions au cluster via ce rôle.

Par exemple :

~~~sql
ALTER ROLE myrole SET work_mem='128MB';
~~~

~~~sql
SELECT name, setting, source
FROM pg_settings
WHERE name='work_mem';
~~~

~~~text
-[ RECORD 1 ]-----
name    | work_mem
setting | 131072
source  | user
~~~

Il est possible de spécifier `ALTER ROLE [...] IN DATABASE [...]` pour n’impacter la configuration d’un rôle que dans une base de données spécifique :

~~~sql
ALTER ROLE myrole IN DATABASE mydb SET work_mem='128MB';
~~~

~~~sql
SELECT name, setting, source
FROM pg_settings
WHERE name='work_mem';
~~~

~~~text
-[ RECORD 1 ]-----
name    | work_mem
setting | 131072
source  | database user
~~~

## La configuration d'une session avec SET SESSION

La commande `SET SESSION`, ou simplement `SET`, affecte le paramétrage pour la session en cours. La nouvelle valeur s'applique immédiatement. Par exemple :

~~~sql
SET work_mem='32MB';
~~~

~~~sql
SELECT name, setting, source
FROM pg_settings
WHERE name='work_mem';
~~~

~~~text
-[ RECORD 1 ]-----
name    | work_mem
setting | 32768
source  | session
~~~

Il est également possible de définir le paramétrage d’une session en fournissant des options dès la connexion. Par exemple, avec `psql` :

~~~bash
psql "options='-c work_mem=64MB'"
~~~

ou encore :

~~~bash
export PGOPTIONS="-c work_mem=64MB"
psql
~~~

## La configuration d'une transaction

En dernier lieu, la commande `SET LOCAL` peut être utilisée pour modifier la configuration au niveau de la transaction en cours. Le paramétrage disparaît dès que la transaction se termine.

Par exemple :

~~~sql
BEGIN; -- Début d'une transaction

SELECT name, setting, source
FROM pg_settings
WHERE name='work_mem';
~~~

~~~text
-[ RECORD 1 ]-----
name    | work_mem
setting | 4096
source  | session
~~~

~~~sql
SET LOCAL work_mem='32MB';

SELECT name, setting, source
FROM pg_settings
WHERE name='work_mem';
~~~

~~~text
-[ RECORD 1 ]-----
name    | work_mem
setting | 32768
source  | session
~~~

~~~sql
END; -- Fin de la transaction, le paramètre revient à sa valeur initiale

SELECT name, setting, source
FROM pg_settings
WHERE name='work_mem';
~~~

~~~text
-[ RECORD 1 ]-----
name    | work_mem
setting | 4096
source  | default
~~~

# Contexte de modification du paramétrage

Bien qu'il soit possible de modifier la configuration de PostgreSQL par plusieurs biais, il faut noter que tous les paramètres ne peuvent pas être modifiés à tous les niveaux.

Par exemple, le paramètre `port` ne peut être défini qu'au démarrage d'une instance, et ne peut donc pas être modifié via des commandes comme `SET DATABASE` ou `SET LOCAL`. Ce comportement s'explique naturellement par le fait que le `port` est spécifique à une instance, et non pas à une session ou une base de données.

De plus, concernant les paramètres modifiables au niveau d'une base de données, d'un rôle, d'une session ou d'une transaction, certains ne peuvent l'être que si le rôle effectuant la modification dispose de droits suffisants.

Dans ce cadre, `pg_settings` présente un champ `context` qui renseigne sur les contraintes et les règles de modification de chaque paramètre. Les valeurs possibles de ce champ sont : "**internal**", "**postmaster**", "**sighup**", "**superuser-backend**", "**backend**", "**superuser**", "**user**". La signification de ces valeurs est détaillée dans la section "[52.24. pg_settings](https://www.postgresql.org/docs/current/view-pg-settings.html)" de la documentation.

Pour compléter la documentation sur deux types de contexte :

- "**internal**" : les paramètres de ce type, nommés "**Preset Options**", ne peuvent pas apparaître directement dans les fichiers de configuration ou être modifiés avec les méthodes listées plus haut. `server_version` est un exemple de ce type de paramètres. D'autres paramètres peuvent être modifiés indirectement, comme `data_checksums` avec l'utilitaire `pg_checksums`.
- "**sighup**" : l'envoi du message `SIGHUP` à l'instance peut se faire avec `pg_ctl reload` ou en exécutant la fonction SQL `pg_reload_conf()` :

  ~~~sql
  SELECT pg_reload_conf();
  ~~~

# Ressources supplémentaires

[Paramètres de configuration](https://www.postgresql.org/docs/current/config-setting.html)  
[pg_settings](https://www.postgresql.org/docs/current/view-pg-settings.html)  
[Preset Options](https://www.postgresql.org/docs/current/runtime-config-preset.html)
