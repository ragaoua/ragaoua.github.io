# Sources de configuration

Les sources de configuration, il y en a 8 en tout et on va les parcourir de la moins spécifique à la plus spécifique (on verra pourquoi juste après) :

## Sources globales

La 1ère source de configuration, c’est tout simplement le paramétrage par défaut inscrit dans le code de PostgreSQL. Par exemple, le paramètre "port" a une valeur par défaut, 5432, qui provient du code. Quelque part, il y a une constante, ou un équivalent, dont le nom doit ressembler à "DEFAULT_PORT" et qui a pour valeur 5432. Et on peut voir dans pg_settings que la source dont provient la valeur de "port" est bien "default" :
Note : certains paramètres n’ont pas de valeur par défaut à proprement parler mais on en parlera quand on traitera de ces paramètres.

La 2nde source de paramétrage, c’est le fichier de configuration du cluster, généralement nommé "postgresql.conf". Le fichier dispose d’une syntaxe qui permet d’inclure d’autres fichiers et même des répertoires. On peut donc distribuer notre configuration sur plusieurs fichiers.

Le 3e canal de configuration, c’est la commande "ALTER SYSTEM". C’est une commande interne à PostgreSQL qui permet, lorsqu’on est connecté à l’instance, de modifier son paramétrage, pour peu qu’on ai les bons droits. Par exemple :

 ALTER SYSTEM SET cluster_name=‘mon_cluster’;

Cette commande, en fait, gère un fichier de configuration qui se trouve dans le data directory et qui se nomme "postgresql.auto.conf". Ce fichier ne doit pas être modifié manuellement et sa gestion doit être exclusivement réservée à ALTER SYSTEM.
Lorsqu’un paramétrage provient de postgresql.conf ou d’ALTER SYSTEM, pg_settings affichera toujours comme "source" la valeur "configuration file", et indiquera l’emplacement du fichier comme on l’a dit tout à l’heure;

Le 4e moyen de configurer un paramètre, c’est en spécifiant sa valeur au démarrage de l’instance, avec l’option "--option" de pg_ctl par exemple ou "-c" de "postgres". Cette action aura pour effet de surcharger le paramétrage défini dans les fichiers de configuration. Et justement, dans pg_settings, les paramètres qui auront été définis de la sorte auront pour "source" la valeur "override".
Pour les paramètres définis via cette méthode, leur valeur est éphémère. Si l’instance est redémarrée et que le paramètre n’est pas de nouveau spécifié explicitement dans la commande de démarrage, il reprendra sa valeur initiale (celle par défaut ou celle définie dans postgresql.conf ou postgresql.auto.conf).

## Sources locales

Les 4 sources qu’on vient de citer ont en commun qu’elles affectent la configuration du cluster dans sa globalité. Les méthodes qui vont suivre permettent de modifier le paramétrage à un niveau local : pour une base de donnée, un rôle, une session ou une transaction :

ALTER DATABASE : cette commande permet de modifier une bdd. En ce qui nous concerne, elle permet en particulier de modifier le paramétrage d’une bdd. La nouvelle configuration s’appliquera pour les futures connexions à cette base de données
ALTER ROLE : tout comme ALTER DATABASE, cette commande permet de modifier les rôles et en particulier de modifier la configuration pour un rôle donné. La nouvelle configuration s’appliquera, comme pour ALTER DATABASE, uniquement pour les future connexions au cluster via ce rôle.
On peut être encore plus précis et spécifier ALTER ROLE … IN DATABASE pour n’impacter la configuration d’un rôle qu’à l’intérieur d’une bdd spécifique.
SET (SESSION) : cette commande permet de modifier un paramètre pour la session en cours. La modification s’applique immédiatement. Une autre façon de modifier le paramétrage d’une session est de spécifier sa valeur voulue dés la connexion. Par exemple, avec psql :

 psql "options='-c work_mem=64MB’"
 OU
 PGOPTIONS="-c work_mem=64MB" psql

SET LOCAL : idem que la commande précédente, mais uniquement pour la transaction en cours.

## Note sur les paramètres "par défaut" mais "dynamiques"
Pour revenir à ce que j’ai dit tout à l’heure, certains paramètres n’ont pas, à proprement parler, de valeur par défaut. C’est le cas, par exemple, de config_file. Ce paramètre ne peut pas avoir de valeur par défaut inscrite en dur dans le code car, s’il n’est pas explicitement donné, il prendra systématiquement la valeur qui correspond au fichier postgresql.conf situé dans le PGDATA. Le PGDATA pouvant se trouver n’importe où, la valeur "par défaut" de config_file est toujours "dynamique" : c’est toujours le fichier postgresql.conf dans PGDATA. Dans PostgreSQL, ce comportement est implémenté dans les binaires pg_ctl, initdb et postgres qui, à la création ou au démarrage d’une instance, si config_file n’est pas explicitement donné, ajoute

## Prévalence du paramétrage
Il existe donc bien des façons de modifier la configuration et on peut être très précis dans la façon de définir ce paramétrage.

Si un paramètre est défini à plusieurs niveaux, c’est le niveau le plus spécifique, le plus bas, qui est prioritaire. Par exemple, si un paramètre a une valeur dans le postgresql.conf mais aussi au niveau de la base de données (ALTER DATABASE), alors c’est la valeur défini au niveau de la base de données qui sera appliquée, si il se trouve qu’on est connecté à la bonne base de données.

# Contexte
Si on compte le nombre de paramètres de l’instance dans pg_settings, on va en trouver plus que les 359 que j’ai mentionnés dans le chapitre "4.Configuration".

	SELECT count(*) FROM pg_settings;

On trouve 378 paramètres. C’est que, parmi ces paramètres, un certain nombre sont en read-only. Ce nombre, c’est 19 dans PostgreSQL 17, et il s’agit des paramètres qui ont pour "context" la valeur "internal" :

	SELECT name FROM pg_settings WHERE context = 'internal';

Ces paramètres existent pour nous renseigner sur l’état interne du cluster mais on n’a pas la main pour les modifier directement, comme c’est le cas avec les autres paramètres. C’est le cas du paramètre `server_version` qui nous renseigne sur la version du cluster.

	SHOW server_version;

On notera que ces paramètres PEUVENT tout de même changer mais que ça ne se fait pas en modifier directement la valeur du paramètre dans un fichier de configuration par exemple. En l’occurrence, `server_version` changera si on réalise une mise à jour de la version du cluster. Pour donner un autre exemple, le paramètre `data_checksums` peut changer après création du cluster mais uniquement via l’utilitaire `pg_checksums`.

En savoir plus : https://www.postgresql.org/docs/current/runtime-config-preset.html

Mais finalement, hormis les 19 exceptions dont on vient de citer 2 exemples, le reste des paramètres peuvent être modifiés directement.

La colonne "context" nous informe donc sur les contraintes et les règles de modification des paramètres. "Internal", on vient de le voir, signifie qu’on ne peut pas modifier le paramètre, du moins par directement. Voici les autres valeurs possibles de "context" :

- "postmaster" correspond aux paramètres qui ne peuvent être appliqués qu’au démarrage de l’instance. Pour appliquer un changement à ces paramètres, il faut donc redémarrer l’instance.
- "sighup" : paramètres qui nécessitent un simple rechargement de la configuration, qui correspond à l’envoie d’un message SIHUP au serveur. On peut demander à l’instance de recharger sa configuration en exécutant "pg_ctl reload" ou, en étant connecté au cluster, en exécutant la fonction "pg_reload_conf()"
- "superuser-backend" : idem que "sighup", à part que ces paramètres peuvent être modifiés localement pour une session à son initialisation par un super utilisateur ou un role ayant les privilèges idoines sur la commande "SET".
- "backend" : idem que superuser-backend, hormis qu’il n’est pas nécessaire d’être super utilisateur pour pouvoir modifier ces paramètres
- "superuser" : idem que "superuser-backend", hormis que ces paramètres peuvent être modifié pour une transaction ou après la création de la session (alors que les paramètres tangué avec le contexte "superuser-backend" ne peuvent être surchargés qu’à la création de la session, mais pas après)
- "user" : idem que "superuser", hormis qu’il n’est pas nécessaire d’être super utilisateur pour modifier ces paramètres
