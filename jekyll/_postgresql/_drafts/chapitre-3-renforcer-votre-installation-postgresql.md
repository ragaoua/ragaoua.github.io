---
layout: post
title: Chapitre 3 - Renforcer votre installation PostgreSQL
date: 
---

Pour faire suite à l'article précédent, qui traitait de l'initialisation d'un cluster de bases de données, nous allons voir aujourd'hui comment renforcer une installation PostgreSQL.  
La plupart des mesures que nous allons mentionner dans cette article concerne des options qui peuvent être fourni à la création d'un cluster.

# Activation des sommes de contrôle

PostgreSQL stocke ses données par "blocs" dans les fichiers de données. Par défaut, un bloc fait 8Ko.
Lorsque l'options `checksums` est activée, chaque bloc de données contient une somme de contrôle qui est mise à jour à chaque modification des données du bloc et vérifiée à chaque lecture. Si la somme de contrôle ne correspond pas aux données du bloc, le cluster émet une erreur du type :

~~~text
WARNING:  page verification failed, calculated checksum 23263 but expected 58531
ERROR:  invalid page in block 0 of relation base/5/16396
~~~

L'activation des sommes de contrôles permet donc de détecter les cas de corruption des données.

En contrepartie, l'activation de cette fonctionalité impacte négativement les performances du cluster. Il est difficile de s'aventurer à estimer cet impact, car celui-ci dépend sensiblement du type de workload pris en charge par le cluster et peut donc significativement varier. Pour donner un ordre d'idée, l'impact peut aller de 1 ou 2% (pour les cas d'usage "traditionnels") jusqu'à possiblement plus de 10% (pour des cas d'usage impliquant des écritures massives).  
Je recommande tout de même d'activer par défaut les _checksums_ et, seulement si des problèmes de performances sur les IO disque et le CPU apparaissent, d'étudier la possibilité de les désactiver.

On notera également que la taille de journaux de transaction est plus importante lorsque l'option est activée, ce qui nécessite donc davantage d'espace disque, mais rien de suffisamment conséquent pour mériter plus qu'une simple mention dans cette article (l'ordre de grandeur est de 2-3%).

Les sommes de contrôles pourraient faire l'objet d'un article à part entière. Nous ne nous étalerons donc pas davantage sur ce sujet aujourd'hui. On précisera simplement que CrunchyData et AWS, entre autres providers de services _Cloud_, activent les sommes de contrôle sans qu'il ne soit possible de les désactiver. D'ailleurs, les _checksums_ seront activé par défaut dans la prochaine version majeure de PostgreSQL, la version 18.

En attendant, il est nécessaire d'utiliser l'option `--data-checksums`/`-k` pour activer cette fonctionnalité avec `initdb`/`pg_ctl initdb. Par exemple :

~~~bash
/usr/pgsql-17/bin/initdb --data-checksums
~~~

A partir de PostgreSQL 18, l'option `--no-data-checksums` permet de désactiver la fonctionnalité.

# Mot de passe du super-utilisateur

Lorsqu'un cluster PostgreSQL est initialisé, un super-utilisateur est créé.
Celui-ci porte, par défaut, le nom de l'utilisateur système qui a exécuté `initdb`/`pg_ctl initdb`.
Il est possible de changer ce nom avec l'option `--username`/`-U`.
Dans notre cas, il s'agissait de l'utilisateur `postgres`.
Cet utilisateur (on parle de "rôle") est l'équivalent de `root` pour ce qui est
du cluster PostgreSQL et dispose donc de tous les droits à l'intérieur de celui-ci.

Il est donc recommandé de sécuriser les accès à ce rôle. Pour ce faire, il est d'abord nécessaire de

- pg_hba : no trust
- superuser password
- logging
- ssl
- password encryption
