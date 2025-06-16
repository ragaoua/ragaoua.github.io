---
layout: post
title: Chapitre 3 - Connexion à une instance PostgreSQL
date:
---

Dans le chapitre précédent, nous avons créé un cluster et démarré son instance.
Nous avons ensuite tenté d'accéder à l'instance avec `psql` afin de vérifier qu'elle était bien démarrée et accessible.

Dans cet article, nous allons détailler les modalités d'accès à une instance PostgreSQL afin d'introduire de nouveaux concepts autour du SGBD.

# Port d'écoute de l'instance

Lorsqu'une instance PostgreSQL est démarrée, elle se lie à un port spécifique pour écouter les connexions entrantes. Par défaut, il s'agit du port "5432", mais cette valeur est configurable via le paramètre `port`.

De même, la plupart des clients (comme `psql`) ciblent par défaut le port "5432", mais permettent également de se connecter à un port différent. Par exemple, pour une instance démarrée sur le port 5454 :

~~~bash
/usr/pgsql-17/bin/psql --port=5454
~~~

# Accès local à l'instance

Au démarrage d'une instance PostgreSQL, un ou plusieurs [sockets Unix](https://fr.wikipedia.org/wiki/Berkeley_sockets#Socket_unix) sont créés dans des emplacements définis par la configuration du cluster.
Ces sockets peuvent ensuite être utilisés par des processus locaux à la machine hébergeant le serveur PostgreSQL pour communiquer avec celui-ci, et notamment pour se connecter à l'instance et accéder aux bases de données du cluster.

Ce comportement est contrôlé par le paramètre `unix_socket_directories`. Si sa valeur est vide, aucun socket n'est créé, rendant impossible la connexion locale à l'instance.
La valeur par défaut du paramètre est **"/run/postgresql, /tmp"**. Un socket sera donc créé sous le répertoire `/run/postgresql`, et un autre sous `/tmp`. Le nom d'un socket PostgreSQL est de la forme ".s.PGSQL.\<port\>". Il s'agit d'un fichier caché :

~~~bash
ls -al /run/postgresql/
~~~

~~~text
total 4
drwxrwxrwt. 1 root     root     53 Jun 11 19:58 .
dr-xr-xr-x. 1 root     root     73 Dec 24 19:49 ..
srwxrwxrwx. 1 postgres postgres  0 Jun 11 19:58 .s.PGSQL.5432
-rw-------. 1 postgres postgres 50 Jun 11 19:58 .s.PGSQL.5432.lock
~~~

Pour ce qui est de `psql`, le binaire recherche par défaut la présence d'un socket dans le répertoire `/run/postgresql`. L'option `--hostname`/`-h` permet de modifier ce comportement. Par exemple :

~~~bash
/usr/pgsql-17/bin/psql --hostname=/tmp
~~~

C'est ce mécanisme qui a été utilisé dans l'article précédent. L'accès à l'instance s'est donc fait via le socket Unix et le port 5432.

# Accès TCP/IP

L'accès à une instance n'est bien évidemment pas réservé aux processus locaux. Il est possible de se connecter aux bases de données d'un cluster à distance, depuis un serveur applicatif ou un poste de travail par exemple.

À cet effet, le paramètre `listen_addresses` contrôle la liste des interfaces IP sur lesquelles l'instance se lie et écoute les connexions clientes.  
À l'instar de `unix_socket_directories`, `listen_addresses` peut être vide, ce qui interdit les accès TCP/IP. La valeur par défaut est **"localhost"**, ce qui n'autorise les accès TCP/IP que par le biais de la [loopback](https://fr.wikipedia.org/wiki/Loopback).

Concernant `psql`, l'option `--hostname`/`-h` est de nouveau utilisée pour se connecter à une instance en TCP/IP :

~~~bash
/usr/pgsql-17/bin/psql --hostname=127.0.0.1
# Ou encore
/usr/pgsql-17/bin/psql --hostname=192.168.52.135 # Exemple d'adresse IP sur laquelle un serveur PostgreSQL serait démarré
~~~

# Utilisateur et base de données de connexion

La connexion à une instance PostgreSQL doit se faire avec un utilisateur spécifique. Il s'agit ici d'un utilisateur de base de données, un objet du cluster PostgreSQL auquel sont associés des droits ainsi qu'une configuration d'authentification.

De plus, à la connexion, il est nécessaire de spécifier une base de données du cluster à laquelle on souhaite se connecter. Ce sont les objets de cette base de données qui seront accessibles par la session ouverte (en plus des objets globaux du cluster, comme les utilisateurs).

Par défaut, `psql` tente de se connecter avec l'utilisateur portant le même nom que l'utilisateur système et d'accéder à la base de données portant le même nom que l'utilisateur de connexion.  
Dans l'article précédent, nous disposions d'un utilisateur système nommé `postgres`, ce qui correspond au nom du super-utilisateur par défaut et de la première base de données créés par le cluster lors de son initialisation.

`psql` fournit les options `--username`/`-U` et `--dbname`/`-d` pour définir respectivement l'utilisateur et la base de données de connexion :

~~~bash
/usr/pgsql-17/bin/psql --username=myuser --dbname=mydb
~~~

# La chaîne de connexion

Plutôt que de spécifier les paramètres de connexion via des options (`--hostname`, `--port`, ...), certains utilitaires, comme `psql`, acceptent également une "chaîne de connexion" qui peut prendre deux formats :

~~~text
psql "host=localhost port=5432 username=myrole dbname=mydb connect_timeout=10"
~~~

~~~text
psql "postgresql://myrole@localhost/mydb?connect_timeout=10"
~~~

Pour `psql`, cette chaîne de connexion permet de définir des paramètres supplémentaires pour la connexion à établir. L'exemple ci-dessus utilise le paramètre `connect_timeout`, qui définit un délai d'attente pour la connexion. `psql` ne fournit pas d'autres moyens de définir ces paramètres, contrairement aux options `--host` ou `--dbname`.

L'ensemble des paramètres de connexion sont décrits dans la [section 32.1.2 de la documentation PostgreSQL](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PARAMKEYWORDS).

# Un mot sur l'authentification

Pour sécuriser l'accès aux données, il est bien évidemment nécessaire de mettre en place un mécanisme d'authentification des connexions et de gestion des habilitations.

Je n'aborderai pas ces aspects en détail ici, car ils feront l'objet d'un article dédié.

# Ressources

[unix_socket_directories](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-UNIX-SOCKET-DIRECTORIES) (voir également [unix_socket_group](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-UNIX-SOCKET-GROUP) et [unix_socket_permissions](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-UNIX-SOCKET-PERMISSIONS))  
[listen_addresses](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-LISTEN-ADDRESSES)  
[port](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-PORT)  
[psql](https://www.postgresql.org/docs/current/app-psql.html)
[Chaîne de connexion](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)