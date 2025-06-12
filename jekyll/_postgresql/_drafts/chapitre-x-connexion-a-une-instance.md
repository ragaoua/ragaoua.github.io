---
layout: post
title: Chapitre 3 - Connexion à une instance PostgreSQL
date:
---

Dans le chapitre précédent, nous avons créé un cluster et démarré son instance.
Nous avons ensuite tenté d'accéder à l'instance avec `psql` afin de vérifier que celle-ci était bien démarrée et accessible.

Mais comment l'accès à l'instance est-il possible ? Quelles en sont les modalités ? Dans cette article, nous allons répondre à ces questions.

# Port d'écoute de l'instance

Lorsqu'une instance PostgreSQL est démarrée, elle se lie à un port spécifique pour écouter les connexions entrantes. Par défaut, il s'agit du port "5432" mais cette valeur est configurable via le paramètre `port`.

De même, par défaut, la plupart des clients (comme `psql`) ciblent par défaut le port "5432" mais permettent également de se connecter à un port différent. Par exemple, dans le précédent article, si l'instance avait été démarrée sur le port 5454, il aurait fallu s'y connecter de la façon suivante :

~~~bash
/usr/pgsql-17/bin/psql --port=5454
~~~

# Accès local à l'instance

Au démarrage d'une instance PostgreSQL, celle-ci crée un ou plusieurs [sockets Unix](https://fr.wikipedia.org/wiki/Berkeley_sockets#Socket_unix) à des emplacements définis par la configuration du cluster.  
Ces sockets peuvent ensuite être utilisés par d'autres processus locaux à la machine hébergeant le serveur PostgreSQL pour communiquer avec celui-ci, et notamment pour se connecter à l'instance et accéder aux bases de données du cluster.

Ce comportement est contrôlé par le paramètre `unix_socket_directories`. La valeur de celui-ci peut-être vide, auquel cas aucun socket n'est créé. La connexion locale à l'instance ne sera donc pas possible.  
La valeur par défaut du paramètre est "/run/postgresql, /tmp". Un socket sera donc créé sous le répertoire `/run/postgresql` et un autre sous `/tmp`. Le nom d'un socket PostgreSQL est de la forme ".s.PGSQL.\<port\>" (il s'agit donc d'un fichier caché) :

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

Pour ce qui est de `psql`, le binaire cherche, par défaut, la présence d'un socket dans le répertoire `/run/postgresql`. L'option `--hostname`/`-h` permet de surcharger ce comportement. Par exemple :

~~~bash
/usr/pgsql-17/bin/psql --hostname=/tmp
~~~

C'est ce mécanisme qui a été utilisé dans l'article précédent. L'accès à l'instance s'est donc fait via le socket unix et le port 5432.

# Accès TCP/IP

L'accès à une instance n'est bien évidemment pas limité aux processus locaux. Il est possible de se connecter aux bases de données d'un cluster à distance, depuis un serveur applicatif ou un poste de travail par exemple.

A cet effet, le paramètre `listen_addresses` contrôle la liste des interfaces IP sur lesquels l'instance se lie et écoute les connexions clientes.  
A l'instar de `unix_socket_directories`, `listen_addresses` peut être vide, ce qui interdit les accès TCP/IP. La valeur par défaut est "localhost", ce qui n'ouvre l'accès TCP/IP que par le biais de la [loopback](https://fr.wikipedia.org/wiki/Loopback).

Concernant `psql`, c'est de nouveau l'option `--hostname`/`-h` qui peut être utilisée pour se connecter à une instance en TCP/IP :

~~~bash
/usr/pgsql-17/bin/psql --hostname=127.0.01
# Ou encore
/usr/pgsql-17/bin/psql --hostname=192.168.52.135 # Exemple d'IP sur laquelle un serveur PostgreSQL serait démarré
~~~

# Utilisateur et base de données de connexion

La connexion à une instance PostgreSQL doit se faire à travers un utilisateur spécifique. On parle ici d'utilisateur base de données, un objet du cluster PostgreSQL à qui sont associés des droits et, éventuellement, une configuration d'authentification.

De plus, à la connexion, il est nécessaire de spécifier une base de données du cluster. Ce sont les objets de cette base de données qui seront accessibles par la session alors ouverte (en plus des objets globaux du cluster, comme les utilisateurs).

Par défaut, `psql` tente de se connecter à l'utilisateur portant le même nom que l'utilisateur système, et accède à la base données portant le même nom que l'utilisateur de connexion.  
Dans l'article précédent, nous disposions d'un utilisateur système nommé `postgres`, ce qui correspond en effet au nom du super-utilisateur par défaut et de la première base de données créés par le cluster à son initialisation.

`psql` fournit les options `--username`/`-U` et `--dbname`/`-d` pour définir respectivement l'utilisateur et la base de données de connexion :

~~~bash
/usr/pgsql-17/bin/psql --username=myuser --dbname=mydb
~~~

# Paramètres de connexions

sslmode, connect_timeout etc

# La chaîne de connexion

Plutôt que de spécifier les paramètres de connexion via des options (`--hostname`, `--port`, ...), certains utilitaires, comme `psql` accepte également une "chaîne de connexion" qui peut prendre 2 formats :

~~~text
psql "host=localhost port=5432 username=myrole dbname=mydb connect_timeout=10"
~~~

~~~text
psql "postgresql://myrole@localhost/mydb?connect_timeout=10"
~~~

...

# Authentification

Pour l'instant, nous avons supposé que l'accès à l'instance n'était pas authentifié...

# Ressources

[unix_socket_directories](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-UNIX-SOCKET-DIRECTORIES) (voir également [unix_socket_group](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-UNIX-SOCKET-GROUP) et [unix_socket_permissions](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-UNIX-SOCKET-PERMISSIONS))  
[listen_addresses](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-LISTEN-ADDRESSES)  
[port](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-PORT)  
[psql](https://www.postgresql.org/docs/current/app-psql.html)
[Chaîne de connexion](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)