---
layout: post
title: Chapitre 4 - Configuration
date: 
---

Dans PostgreSQL 17, il existe 359 paramètres de configuration. Nous aurons l'occasion de couvrir une grande partie de ceux-ci tout au long de cette série d'articles. Pour lors, nous allons aborder quelques généralités autour du paramétrage de PostgreSQL, et nous en profiterons pour introduire les paramètres de bases (ceux qui ne nécessitent pas de connaître de concepts complexes en amont ou d’avoir des prérequis particuliers).


# postgresql.conf

La configuration d'un cluster PostgreSQL peut provenir de diverses sources, la principale étant le fichier de configuration du cluster, traditionnellement nommé `postgresql.conf` et placé à la racine du répertoire des données (`PGDATA`). Le nom et la localisation de ce fichier ne peuvent être définis qu'au démarrage d'une instance, via l'option `--config-file` des commandes `postgres` ou `pg_ctl start`. Ce paramètre est généralement laissé à sa valeur par défaut, à savoir `<PGDATA>/postgresql.conf`.

# pg_settings

Tout cluster PostgreSQL possède un ensemble de "vues système", qui fournissent des informations sur le cluster et son état. Ces vues sont mises à disposition à travers le schéma `pg_catalog` disponible dans chaque base de données du cluster.

La vue qui nous intéresse ici se nomme `pg_settings`. Elle contient des informations en rapport avec le paramétrage du cluster. Par exemple :

~~~sql
SELECT * FROM pg_catalog.pg_settings WHERE name='port';
~~~

~~~
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

La vue nous renseigne sur la valeur actuelle du paramètre (`setting`), mais aussi sa valeur minimale et maximale (`min_val`, `max_val`) lorsqu’il s’agit d’un nombre, ou les valeurs possibles (`enumvals`) lorsque celles-ci sont strictement restreintes. On dispose aussi de sa valeur par défaut (`boot_val`), et de la valeur qu’il prendra s’il est réinitialisé (`reset_val`).


# Paramètres de configuration basiques

Maintenant, parlons des paramètres de bases de PostgreSQL. Ces paramètres, ce ne sont pas nécessairement les premiers paramètres qu’on considère lorsqu’on configure un cluster, mais ce sont des paramètres assez simples à appréhender. Ils ne nécessitent pas de connaître plus de choses que ce qu’on a déjà vu jusqu’ici, donc allons-y :

- cluster_name
- listen_addresses
    Liste des IP/hostnames du serveur sur lesquelles l’instance écoutera pour recevoir des connexions
    Possibilité d’utiliser une wildcard : *
    Peut être vide, auquel cas l’instance ne sera pas accessible à travers TCP/IP
    Défaut : localhost
- port
    Port TCP sur lequel l’instance écoute pour recevoir des connexions
    Défaut : 5432
- unix_socket_directories
    Liste de répertoires dans lesquelles l’instance créera, au démarrage, un socket Unix pour permettre les connexions locales.
    Peut être vide, auquel cas il ne sera pas possible de se connecter en "local" à l’instance
- unix_socket_group
- unix_socket_permissions
- config_file
- data_directory
- data_directory_mode
- hba_file
- ident_file
- external_pid_file
- max_connections
- superuser_reserved_connections
- data_checksums
- full_page_writes
- search_path


# Ressources

[Paramètres de configuration](https://www.postgresql.org/docs/17/config-setting.html)
[pg_settings](https://www.postgresql.org/docs/17/view-pg-settings.html)






----------------------------------------------------------