---
layout: post
title: Chapitre 4 - Renforcer votre installation PostgreSQL
date: 2025-06-16
---

Pour faire suite au chapitre 2 de cette série, qui traitait de l'initialisation d'un cluster de bases de données, nous allons voir aujourd'hui comment renforcer cette installation PostgreSQL initiale.

Bien évidemment, le renforcement d'un cluster PostgreSQL, notamment vis-à-vis de la sécurité des données, est un sujet vaste qui nécessiterait de plus longs développements que ce simple article. L'objectif ici n'est pas d'être exhaustif, mais simplement d'aborder quelques éléments de configuration de base permettant rapidement d'améliorer la robustesse d'un cluster. D'autres sujets comme le chiffrement des communications, la gestion des logs, ou encore la réplication des données seront mis à l'honneur dans de futures publications pour compléter celle-ci.

_Note : cet article constituait initialement le troisième chapitre de la série._

# Activation des sommes de contrôle

PostgreSQL stocke ses données par "blocs" dans les fichiers de données. Par défaut, un bloc fait 8Ko.
Lorsque l'option `checksums` est activée, chaque bloc de données contient une somme de contrôle qui est mise à jour à chaque modification du bloc et vérifiée à chaque lecture. Si la somme de contrôle ne correspond pas aux données du bloc, l'instance émet une erreur du type :

~~~text
WARNING:  page verification failed, calculated checksum 23263 but expected 58531
ERROR:  invalid page in block 0 of relation base/5/16396
~~~

L'activation des sommes de contrôle permet donc de détecter les cas de corruption de données.

En contrepartie, cette fonctionnalité impacte négativement les performances du cluster. Il est difficile de s'aventurer à estimer cet impact, car celui-ci dépend sensiblement du type de _workload_ pris en charge par l'instance et peut donc significativement varier. Pour donner un ordre d'idée, l'impact peut aller de 1 ou 2% (pour les cas d'usage "traditionnels") jusqu'à plus de 10% (pour des cas d'usage impliquant des écritures massives).  
Je recommande tout de même d'activer par défaut les _checksums_ et, seulement si des problèmes de performances sur les IO disque ou le CPU apparaissent, d'étudier la possibilité de les désactiver.

On notera également que la taille des journaux de transaction est plus importante lorsque l'option est activée, ce qui nécessite donc davantage d'espace disque, mais l'impact est négligeable à mon avis (2 à 3%).

Les sommes de contrôle pourraient faire l'objet d'un article à part entière. Nous ne nous étalerons donc pas davantage sur ce sujet aujourd'hui. On précisera simplement que certains providers de services _Cloud_, CrunchyData et AWS notamment, activent les sommes de contrôle par défaut sans qu'il ne soit possible pour leurs clients de les désactiver. D'ailleurs, les _checksums_ seront activés par défaut dans la prochaine version majeure de PostgreSQL, la version 18.

En attendant, il est nécessaire d'utiliser l'option `--data-checksums`/`-k` pour activer cette fonctionnalité avec `initdb`. Par exemple :

~~~bash
initdb --data-checksums
~~~

À partir de PostgreSQL 18, l'option `--no-data-checksums` permet de désactiver la fonctionnalité.

Enfin, dans les versions antérieures à PostgreSQL 12, il n'était pas possible d'activer/désactiver les _checksums_ au niveau bloc sur un cluster existant. Depuis la version 12, c'est possible via l'utilitaire `pg_checksums`.  
Attention, l'activation des _checksums_ sur un cluster existant nécessite un arrêt complet de l'instance et procède d'une réécriture de chaque bloc de données du cluster. Sur un cluster à forte volumétrie, cette opération peut donc prendre un temps conséquent.

Pour plus d'information, consulter la documentation PostgreSQL en rapport avec les [Data Checksums](https://www.postgresql.org/docs/current/checksums.html)

# Configuration de l'authentification

Par défaut, l'instance d'un cluster nouvellement créé ne requiert aucune authentification pour se connecter à ses bases de données depuis la machine locale (celle hébergeant le cluster).
Cela permet de mettre en place un environnement de test rapidement, mais c'est bien évidemment un comportement qu'il est recommandé de modifier si l'on veut sécuriser ses données en production.

Pour ce faire, `initdb` présente plusieurs options :

- `--auth-host` : définit la méthode d'authentification pour les connexions TCP/IP locales, passant donc par la loopback (localhost/127.0.0.1).
- `--auth-local` : cette option indique la méthode d'authentification pour les connexions locales passant par la socket unix créée par PostgreSQL au démarrage d'une instance.
- `--auth`/`-A` : enfin, cette option applique un paramétrage commun aux deux précédents types de connexions, c'est-à-dire à toutes les connexions locales à l'instance.

Il existe plusieurs méthodes d'authentification, qui feront l'objet d'un article à part entière. Pour l'heure, nous allons uniquement nous intéresser aux trois suivantes :

- `trust` : c'est la méthode par défaut, qui indique qu'aucune authentification n'est requise.
- `scram-sha-256` : cette méthode configure une authentification par mot de passe. Celui-ci doit être chiffré avec _scram-sha-256_ avant d'être envoyé à l'instance.
- `peer` : cette méthode n'est valide que pour les connexions locales par socket. Lorsqu'elle est spécifiée, la connexion n'est acceptée que si le nom du rôle base de données de connexion correspond au nom de l'utilisateur système qui initie la connexion. En somme, il s'agit d'une délégation de l'authentification au système sous-jacent.

Pour concilier sécurité et praticité, il est possible de configurer les connexions TCP/IP locales à `scram-sha-256`, et les connexions locales via la socket à `peer`. Cette dernière configuration permet de se connecter à l'instance depuis l'utilisateur système `postgres` à l'utilisateur base de données du même nom (par convention, `postgres` est le nom du super-utilisateur par défaut), sans avoir à fournir le mot de passe à chaque connexion, afin de fluidifier les gestes d'administration.

En pratique, la commande à exécuter pour initialiser le cluster ressemble donc à la suivante :

~~~bash
initdb --auth-local=peer --auth-host=scram-sha-256 [...] # Ne pas oublier d'intégrer d'autres options discutées précédemment, comme --data-checksums
~~~

Les méthodes d'authentification peuvent ensuite être modifiées dans le fichier `pg_hba.conf` présent à la racine du répertoire de données du cluster. De nouveau, ce fichier sera traité dans un futur article.

Il est bien évidemment possible de requérir une authentification par mot de passe pour toutes les connexions, auquel cas l'option `--auth=scram-sha-256` peut être fournie en lieu et place des options mentionnées ci-dessus. Attention, cela nécessite que le super-utilisateur dispose d'un mot de passe, ce que nous allons traiter dans la suite de cet article.

# Mot de passe du super-utilisateur

Un cluster PostgreSQL doit disposer d'au moins un super-utilisateur.
À la création d'un cluster, un tel utilisateur est donc créé, portant le nom de l'utilisateur système qui a exécuté `initdb`, sauf si l'option `--username`/`-U` est spécifiée. Par convention, il s'agit souvent d'un utilisateur nommé `postgres`.  
Au sein du cluster PostgreSQL, cet utilisateur (on parle de "rôle") est l'équivalent de `root` et dispose alors de tous les droits.

Il est donc recommandé de sécuriser les accès à ce rôle en particulier. Par défaut, il ne dispose d'aucun mot de passe, ce qui interdit l'accès à l'instance via ce rôle, sauf si des méthodes d'authentification comme `trust` ou `peer` sont configurées. `trust` étant à proscrire pour des raisons évidentes, et `peer` ne pouvant être utilisée que pour les connexions locales, il faut donc configurer un mot de passe pour le super-utilisateur de sorte à pouvoir y accéder depuis l'extérieur de la machine hébergeant le cluster.  

Pour cela, nous pouvons de nouveau faire appel aux options d'`initdb` :

- `--pwfile` : cette option permet de définir le chemin vers un fichier contenant le mot de passe du rôle (attention à sécuriser l'accès ou à supprimer ce fichier après initialisation du cluster).
- `--pwprompt` : lorsque cette option est utilisée, `initdb` affichera un message demandant de saisir le mot de passe.

Par exemple :

~~~bash
cat >bootstrap-superuser-pw <<EOF
<MOT_DE_PASSE>
EOF
initdb --pwfile="./bootstrap-superuser-pw" [...] # Autres options...
~~~

Ou encore :

~~~bash
initdb --pwprompt [...] # Autres options...
~~~

~~~text
[...]
Enter new superuser password: <MOT_DE_PASSE>
Enter it again: <MOT_DE_PASSE>
[...]
~~~
