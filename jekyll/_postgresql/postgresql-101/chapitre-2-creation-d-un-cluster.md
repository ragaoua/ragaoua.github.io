---
layout: post
title: Chapitre 2 - Création d'un cluster PostgreSQL
date: 2025-04-19
---

Un _cluster_ PostgreSQL est un regroupement de plusieurs bases de données partageant, entre autres, des ressources mémoire et CPU, du stockage et des éléments de configuration.
L'accès à un cluster nécessite le démarrage préalable d'une "instance", qui est un ensemble de processus permettant de gérer l'accès au fichiers de données et autres ressources du cluster.

# Initialisation d'un cluster

L'initialisation d'un cluster se fait à l'aide du binaire `initdb`, qui doit être exécuté par un utilisateur non privilégié (autre que `root` donc).
Fort heureusement, l’installation de PostgreSQL réalisée dans l'article précédent a eu pour effet de créer un utilisateur "postgres" :

~~~bash
sudo su - postgres
~~~

Pour pouvoir créer le cluster au bon endroit, `initdb` a besoin de connaître le chemin vers le répertoire qui hébergera le cluster.
Ce répertoire peut être défini par l’option `--pgdata`/`-D`.
Si l’option n’est pas présente, `initdb` utilisera la variable d’environnement `PGDATA`.
Nous allons privilégier cette seconde alternative :

~~~bash
export PGDATA="/var/lib/pgsql/data"
mkdir -p "$PGDATA"
/usr/pgsql-17/bin/initdb
~~~

~~~text
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "C.utf8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

creating directory /var/lib/pgsql/data ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

initdb: warning: enabling "trust" authentication for local connections
initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    /usr/pgsql-17/bin/pg_ctl -D /var/lib/pgsql/data -l logfile start
~~~

Pour consulter les fichiers générés :

~~~bash
ls -l "$PGDATA"
~~~

~~~text
total 56
-rw-------. 1 postgres postgres     3 Apr 19 13:05 PG_VERSION
drwx------. 5 postgres postgres    33 Apr 19 13:05 base
drwx------. 2 postgres postgres  4096 Apr 19 13:05 global
drwx------. 2 postgres postgres     6 Apr 19 13:05 pg_commit_ts
drwx------. 2 postgres postgres     6 Apr 19 13:05 pg_dynshmem
-rw-------. 1 postgres postgres  5711 Apr 19 13:05 pg_hba.conf
-rw-------. 1 postgres postgres  2640 Apr 19 13:05 pg_ident.conf
drwx------. 4 postgres postgres    68 Apr 19 13:05 pg_logical
drwx------. 4 postgres postgres    36 Apr 19 13:05 pg_multixact
drwx------. 2 postgres postgres     6 Apr 19 13:05 pg_notify
drwx------. 2 postgres postgres     6 Apr 19 13:05 pg_replslot
drwx------. 2 postgres postgres     6 Apr 19 13:05 pg_serial
drwx------. 2 postgres postgres     6 Apr 19 13:05 pg_snapshots
drwx------. 2 postgres postgres    25 Apr 19 13:05 pg_stat
drwx------. 2 postgres postgres     6 Apr 19 13:05 pg_stat_tmp
drwx------. 2 postgres postgres    18 Apr 19 13:05 pg_subtrans
drwx------. 2 postgres postgres     6 Apr 19 13:05 pg_tblspc
drwx------. 2 postgres postgres     6 Apr 19 13:05 pg_twophase
drwx------. 3 postgres postgres    60 Apr 19 13:05 pg_wal
drwx------. 2 postgres postgres    18 Apr 19 13:05 pg_xact
-rw-------. 1 postgres postgres    88 Apr 19 13:05 postgresql.auto.conf
-rw-------. 1 postgres postgres 29646 Apr 19 13:05 postgresql.conf
~~~

# Démarrage d'une instance et accès au cluster

Cela étant fait, il n'est pas encore possible d'accéder au cluster tant que instance n'est pas démarrée.
Pour ce faire, nous allons utiliser un second utilitaire, `postgres`.
De nouveau, l'emplacement du cluster pour l'instance à démarrer doit être donné par l'option `--pgdata`/`-D` ou la variable d'environnement `PGDATA`.
Cette dernière étant déjà définie :

~~~bash
/usr/pgsql-17/bin/postgres
~~~

~~~text
2025-04-19 13:08:06.683 UTC [79] LOG:  redirecting log output to logging collector process
2025-04-19 13:08:06.683 UTC [79] HINT:  Future log output will appear in directory "log".
~~~

Il est désormais possible de se connecter à l'instance et d'accéder au cluster.
Par exemple, en utilisant l'utilitaire `psql` depuis le même serveur en ouvrant un nouveau terminal :

~~~bash
/usr/pgsql-17/bin/psql
~~~

~~~text
psql (17.5)
Type "help" for help.

postgres=# 
~~~

Notons qu'il a été nécessaire d'ouvrir un nouveau terminal car l'exécution de la commande `postgres` ne rend pas la main.
En effet, le serveur (ou l'instance) démarré(e) par la commande s'exécute au premier plan.
Pour pouvoir exécuter l'instance en arrière plan et permettre que celle-ci continue de s'exécuter même après la déconnexion de la session, il est préférable d'utiliser `pg_ctl`.

# pg_ctl

`pg_ctl` est un utilitaire servant à administrer un serveur PostgreSQL.
Il permet donc, entre autres, de démarrer une instance avec l'option `start`.
L'intérêt de `pg_ctl start` en comparaison avec `postgres` est que l'instance est exécutée en arrière plan (en réalité, `pg_ctl` appelle lui-même la commande `postgres`).
Le démarrage d'une instance est donc généralement fait par la commande :

~~~bash
/usr/pgsql-17/bin/pg_ctl start
~~~

~~~text
waiting for server to start....2025-04-19 19:40:03.378 UTC [829] LOG:  redirecting log output to logging collector process
2025-04-19 19:40:03.378 UTC [829] HINT:  Future log output will appear in directory "log".
 done
server started
~~~

`pg_ctl` fournit également des options pour arrêter et redémarrer une instance (`pg_ctl stop` et `pg_ctl restart`), recharger sa configuration (`pg_ctl reload`), vérifier son statut (`pg_ctl status`) et même pour initialiser un cluster (`pg_ctl initdb`).

Le répertoire hébergeant le cluster doit être fournit à `pg_ctl` de la même manière qu'avec `initdb` ou `postgres`.

# Pour aller plus loin...

[Initialisation d'un cluster](https://www.postgresql.org/docs/current/creating-cluster.html)  
[initdb](https://www.postgresql.org/docs/current/app-initdb.html)  
[pg_ctl](https://www.postgresql.org/docs/current/app-pg-ctl.html)
