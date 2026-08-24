# Projet : test-walk-2

Jeu 2D top-down en **Godot 4 (GDScript)**, style visuel cartoon/BD (pas pixel art),
animation poussée, complexité de gameplay significative (objets interactifs, PNJ,
puzzles, combat). Références de style : Hollow Knight, Cuphead.

## Objectif architectural

Système modulaire et scalable pour les objets de jeu interactifs (`DynamicObject`),
basé sur la **composition** plutôt que sur des scripts monolithiques. La logique
d'UI d'éditeur doit rester isolée dans des plugins, jamais mélangée aux scripts
de gameplay.

## Maintenance de ce fichier

Ce fichier doit rester le reflet fidèle de l'état réel du projet, pas un
instantané figé. En conséquence :

- Si tu repères, au fil du code ou de la conversation, une **modification
  significative** de ce qui est décrit ici (changement d'architecture,
  correction d'un bug documenté, renommage, fonctionnalité terminée ou
  abandonnée), tu es libre de mettre à jour ce fichier directement, sans
  demander.
- En revanche, si tu t'apprêtes à **ajouter une information nouvelle qui
  n'a pas été explicitement discutée**, ou quelque chose de surprenant
  (une déduction, une supposition sur une intention non confirmée), demande
  d'abord avant de l'écrire dans le fichier.
- Objectif : corriger et synchroniser librement, mais ne jamais inventer ou
  extrapoler silencieusement le contenu de ce fichier.

## Convention de nommage

- **`DynamicObject*`** : classes de gameplay cœur
  (`DynamicObjectState`, `DynamicObjectTrigger`, `DynamicObjectAction`,
  `DynamicObjectStateMachine`).
- **`Dot*`** : outillage éditeur uniquement
  (`DotGroupToggle`, `DotExtractors`, `DotChildPropertiesDropdown`,
  `DotToggleableGroup`).
- Éviter les noms `Object*` bruts (collision avec la classe `Object` de Godot).
- ⚠️ Piège existant : le fichier `seen_unseen_behavior.gd` déclare
  `class_name SeenUnseen` (pas `SeenUnseenBehavior`). Le **node** dans la scène
  s'appelle `SeenUnseenBehavior`, mais la **classe** est `SeenUnseen`. Attention
  en cas de référence par nom de classe (`as SeenUnseen`) vs recherche de node
  par nom (`"SeenUnseenBehavior"`) — les deux coexistent dans le code actuel.

## État réel de l'architecture DynamicObject (vérifié sur le code)

### Structure de scène (`dynamic_object.tscn`)
`DynamicObject` (root, `Area2D`) a pour enfants directs, **côte à côte** :
- `DynamicObjectStateMachine` (`Node2D`)
- `AnimatedSprite2D`
- `CollisionShape2D`
- `SeenUnseenBehavior` (`Node2D`, classe `SeenUnseen`)
- `VisionDetector` (`Area2D`), qui a lui-même un `CollisionShape2D` enfant

Confirmé : `DynamicObjectStateMachine` et `SeenUnseenBehavior` sont bien des
frères, jamais l'un enfant de l'autre. Le lien entre eux passe uniquement par
signaux (`SeenUnseen.seen` / `SeenUnseen.unseen`).

### Détection de vision
- `VisionDetector` (`Area2D`) cherche `SeenUnseenBehavior` dans son parent au
  `_ready()`, se connecte à `area_entered`/`area_exited`.
- Sur une aire nommée `"VisionCone"` qui entre/sort, appelle
  `seen_unseen.set_seen()` / `set_unseen()`.
- `SeenUnseen` (classe, node `SeenUnseenBehavior`) : `is_seen: bool`, émet
  `seen` / `unseen` uniquement sur changement d'état réel (pas de spam si déjà
  dans le bon état).

### Deux systèmes cohabitent actuellement pour l'animation seen/unseen

**1. Système legacy, actif sur tous les objets existants** (`dynamic_object.gd`,
utilisé par `skeleton_plush.tscn` et `Bookholder.tscn`) :
- `@export` : `vision_behaviour_enabled`, `seen_animation`, `seen_animation_intro`,
  `unseen_animation`, `unseen_animation_intro`, `delay_animation_seen`,
  `delay_animation_unseen`, `activate_after_unseen`.
- Deux `Timer` créés en code (`Timer.new()` + `add_child()`) pour gérer les délais
  avant de jouer l'animation seen/unseen, avec logique d'intro optionnelle
  (`_on_animation_finished` enchaîne l'intro vers l'anim principale).
- **C'est ce système, pas la state machine, qui pilote le comportement réel
  des objets existants dans les scènes actuelles.**

**2. State machine générique, présente mais pas encore branchée sur un objet réel**
(`DynamicObjectStateMachine` + `DynamicObjectState` + `DynamicObjectTrigger` +
`DynamicObjectAction`) — voir détail ci-dessous. Aucune scène n'utilise encore
ce système en pratique ; la migration objet par objet reste à faire.

### State machine générique — état réel de l'implémentation

- `DynamicObjectState` (`Resource`) : `name: String`, `triggers: Array[DynamicObjectTrigger]`,
  `actions: Array[DynamicObjectAction]`. **Aucun de ces champs n'est `@export`**
  actuellement → invisibles/non éditables dans l'inspecteur par défaut.
- `DynamicObjectTrigger` (`Resource`) : seulement `@export target_state: String`
  et `@export event_type: EventType` (enum `SEEN`, `UNSEEN`, `END_OF_ACTIONS`).
  **Pas de champ `source_state`** — le "source" est implicite : les triggers
  vivent dans la liste `triggers` de l'état source lui-même. Pas besoin de le
  stocker explicitement.
- `DynamicObjectStateMachine` : `states: Array[DynamicObjectState]`,
  `initial_state_name: String`, `prev_state`, `curr_state`, référence à
  `SeenUnseen` (récupérée via `get_parent().get_node("SeenUnseenBehavior")`).
  - `_ready()` : connecte `seen`/`unseen` du `SeenUnseen` parent, connecte
    `end_of_action` de **chaque action de chaque état** à `_on_end_of_action`,
    puis appelle `goto_state(initial_state_name)`.
  - `goto_state(name)` : recherche linéaire dans `states` par `.name`, appelle
    `_set_actions()` sur le nouvel état trouvé.
  - `_set_actions()` : relance toutes les actions de l'état courant en
    parallèle (pas de séquençage), reset les compteurs `n_actions`/`n_actions_ended`.
  - `_on_end_of_action()` : incrémente le compteur ; quand toutes les actions
    de l'état sont finies, émet `endofactions`.
  - `_check_trigger(event_type)` : **implémenté** (contrairement à ce qui était
    noté précédemment) — parcourt linéairement `curr_state.triggers`, si
    `event_type` correspond, appelle `goto_state(trigger.target_state)`.
    Pas d'index inversé construit au `_ready()` : c'est une recherche linéaire
    à chaque event, sur une petite liste (les triggers du seul état courant).
  - `_on_seen()` / `_on_unseen()` / `_on_endofactions()` appellent `_check_trigger`
    avec le bon `EventType`.
- `DynamicObjectAction` (`Node`, classe de base) : `signal end_of_action`,
  `play_action()` (stub vide, ne fait rien), `set_end_of_action()` (émet le signal).
- `ActionPlayAnimation extends DynamicObjectAction` : ajoute
  `@export var animation_name: String`, **mais ne override pas `play_action()`**
  → ne joue actuellement aucune animation et n'émet jamais `end_of_action`.
  C'est la prochaine étape évidente pour rendre la state machine fonctionnelle.

### Outillage éditeur (`addons/`)

- **`addons/dynamic_object_tools/`** : plugin principal.
  - `plugin.gd` (`EditorPlugin`) charge `inspector_plugin.gd` avec
    `ResourceLoader.CACHE_MODE_IGNORE` (contournement du cache de `class_name`).
  - `inspector_plugin.gd` (`EditorInspectorPlugin`, `_can_handle` → `DynamicObject`) :
    gère uniquement l'ancien système aujourd'hui — toggle "Vision Behaviour" via
    `DotGroupToggle`, dropdowns d'animation seen/unseen via `DotChildPropertiesDropdown`.
    **Rien encore pour `states`/`triggers`/`actions`** de la state machine générique.
    Contient un vieux brouillon `AnimationDropdown` commenté, candidat à suppression.
- **`addons/tools/`** :
  - `DotGroupToggle` (`EditorProperty`) : checkbox qui active/désactive
    l'affichage d'un groupe entier de propriétés (lit `PROPERTY_USAGE_GROUP`).
  - `DotChildPropertiesDropdown` (`EditorProperty`) : dropdown générique —
    trouve un enfant d'un type donné, appelle un `Callable` extracteur pour
    peupler la liste. Gère la sentinelle `"[Aucune]"` → stocke `""`.
  - `DotExtractors` : fonctions d'extraction statiques
    (`extract_animations(node)` pour l'instant, lit `AnimatedSprite2D.sprite_frames`).
- **`addons/editor_utils/dot_toggleable_group.gd`** : `DotToggleableGroupUtil
  .validate_group_header()` — logique statique prête pour masquer un header de
  groupe selon un toggle, mais **pas encore appelée** : `dynamic_object.gd` n'a
  pas de `_validate_property()` qui l'invoquerait.
- **`addons/collapse_children/`** : plugin indépendant, sans rapport avec
  `DynamicObject` (raccourci Alt+clic / Ctrl+Alt+C pour replier les enfants
  dans le dock Scene).

## Décisions de design (intention, pas toutes implémentées)

- **Rangement visuel à grande échelle** : pour trier une vingtaine de nodes
  enfants, utiliser les **dossiers virtuels de l'éditeur** (clic droit dans le
  dock Scene → "Add Folder", Godot 4.4+). Aucun effet sur les chemins runtime
  (`$NomDuNode` inchangé), aucun impact perf. Ne pas confondre avec un vrai
  Node parent intermédiaire (qui change les chemins et ajoute un niveau de
  transform).
- **NPC devenant hostile** : ne jamais détruire/recréer le node (perte de
  références, d'état, de signaux). Composants présents dès le départ dans la
  scène mais **désactivés** par défaut (ex: `CombatComponent`), activés via
  une action dédiée (`SetComponentActiveAction`, à créer) déclenchée par un
  changement d'état.
- **Héritage** : script (`NPC.gd extends DynamicObject`) + scène ("New
  Inherited Scene"), cascade possible sur plusieurs niveaux. Garder la scène
  de base **minimale** (socle strict : vision, state machine, sprite) ; les
  composants spécifiques s'ajoutent dans les scènes héritées, pas dans la base.
- **Une seule state machine par objet par défaut** ; n'en envisager plusieurs
  que si des familles d'états varient sur des axes réellement indépendants
  (ex: attitude IA vs dialogue) — ne pas segmenter préventivement, seulement
  sur besoin concret.
- **Inspecteur unifié malgré la séparation en nodes** : même si les données
  `states` vivent sur `DynamicObjectStateMachine`, l'inspecteur custom devra
  rester affiché sur `DynamicObject` (lecture/écriture des `@export` du node
  enfant via `get_node`). Limite connue : nécessite un chemin prévisible vers
  le node tant qu'on reste sur une seule state machine par objet.

## Maquette cible de l'inspecteur `DynamicObject` (pas encore construite)

Format visuel attendu pour éditer `DynamicObjectStateMachine.states` depuis
l'inspecteur de `DynamicObject` :

```
== State N : <name> ==

Triggered by :
- <event_type dropdown: Seen/Unseen/EndOf> on <source_state dropdown: liste des states>
- ...
[Add trigger]

Action :
- <label du type d'action> : <valeur principale>
- ...
[Add action]
```
`[Add State]` en bas de la liste pour ajouter un état.

Implications relevées :
- `EndOf` n'est pas un état séparé : c'est une valeur du dropdown `event_type`
  (`END_OF_ACTIONS`), appliquée conceptuellement au state courant.
- Chaque ligne de trigger affiche `event_type` + `source_state` sur une seule
  ligne → nécessite un `EditorProperty` custom avec deux dropdowns côte à côte,
  pas le rendu Resource par défaut de Godot. Note : le "source_state" affiché
  dans la maquette est en fait l'état courant lui-même (voir plus haut, pas un
  champ stocké séparément) — la maquette reste utile pour la lisibilité même
  si techniquement redondante avec le regroupement par état.
- Chaque ligne d'action affiche un label de type + sa valeur clé (ex:
  `"Animation : idle"`) → chaque sous-classe de `DynamicObjectAction` devra
  fournir ce label (convention à définir : méthode override, ou mapping dans
  le plugin).
- Tout le CRUD (`Add trigger`/`Add action`/`Add State`, suppression) devra
  être géré par le plugin custom, pas par le "+" par défaut de l'inspecteur
  pour `Array[Resource]`.
- `DynamicObjectState.name`, `triggers`, `actions` doivent passer en `@export`
  pour être visibles/éditables (actuellement de simples `var`).

Reste à construire pour atteindre cette maquette : un `EditorProperty` pour
une ligne de trigger, un `EditorProperty` pour une ligne d'action, un
composant englobant pour un bloc State (header + triggers + actions + boutons
Add), et le branchement dans `inspector_plugin.gd` pour intercepter la
propriété `states` de `DynamicObjectStateMachine` (lu via `get_node` depuis
`DynamicObject`).

## Prochaines étapes concrètes (dans l'ordre logique)

1. Passer `DynamicObjectState.name`/`triggers`/`actions` et
   `DynamicObjectTrigger` en `@export` pour qu'ils soient visibles dans
   l'inspecteur par défaut (même moche), histoire de pouvoir tester la state
   machine de bout en bout sans attendre l'inspecteur custom.
2. Implémenter `ActionPlayAnimation.play_action()` : jouer l'animation sur
   l'`AnimatedSprite2D` de l'objet parent, appeler `set_end_of_action()`
   (probablement connecté à `animation_finished` du sprite).
3. Tester la state machine générique sur un objet simple avant de commencer
   la migration des objets legacy (`skeleton_plush`, `Bookholder`).
4. Construire l'inspecteur custom `states`/`triggers`/`actions` une fois la
   state machine validée fonctionnellement.

## À venir (hors state machine)

- Système d'animation du joueur : animation squelette 2D (Spine2D ou
  `Skeleton2D` natif Godot) pressenti, pour l'animation en couches/blending.
  `AnimationTree` + `AnimationNodeStateMachine` réservé au joueur ; le FSM
  custom gère les autres objets.
- Nouvelles sous-classes `DynamicObjectAction` et composants
  (`DialogueComponent`, `CombatComponent`).
- Workflow d'animation iPad : Procreate (dessin) → ToonSquid / Procreate Dreams
  (symboles/instances) en cours d'évaluation.

## Apprentissages techniques (Godot)

- **Composition over monoliths** : `DynamicObject` reste un orchestrateur
  léger, le comportement vit dans des nœuds enfants typés communiquant par
  signaux.
- **`@onready` + `_get_property_list()`** : les `@onready var` ne sont pas
  encore assignées quand l'éditeur appelle `_get_property_list()`. Fix :
  `notify_property_list_changed()` dans `_ready()`, protégé par
  `Engine.is_editor_hint()`.
- **`_process()` + `clear()`** : appeler `dropdown.clear()` à chaque frame
  réinitialise silencieusement `auto_translate_mode` à `INHERIT`. Refixer le
  mode après chaque `clear()`.
- **Sentinelle `"[Aucune]"`** : stocker `""` (pas la chaîne d'affichage) quand
  l'item "aucun" est sélectionné ; restaurer la sélection en testant `""`
  explicitement.
- **`_parse_group` vs `_parse_property`** : les en-têtes de groupe passent par
  `_parse_group` (pas de valeur de retour) — impossible de les supprimer
  depuis le plugin seul sans `@tool` sur l'objet.
- **Cache global des `class_name`** : erreurs parser "not declared in current
  scope" sur des références `class_name` indiquent souvent un cache obsolète ;
  redémarrer Godot ou supprimer `.godot/` pour forcer un re-scan.
- **Scene Reload > Soft Reload** : "Scene > Reload Saved Scene" est fiable
  pour rafraîchir l'inspecteur après un changement de script ; "Soft Reload"
  (clic droit sur le script) ne l'est pas.
- **Plancher `wait_time = 0`** : Godot impose un minimum ; utiliser
  `max(delay, 0.001)` en contournement.
- **Pas d'abstraction prématurée** : différer les migrations architecturales
  jusqu'à un besoin concret.

## Préférences de travail

- Toujours répondre en français, quel que soit le contenu du code, des
  commentaires ou des messages de diagnostic (qui peuvent rester en anglais).
- Comprendre l'architecture conceptuellement avant d'implémenter ;
  privilégier les explications sans code lors de l'exploration du design.
- Solutions pragmatiques et simples ; pousser back contre l'over-engineering
  et les API suggérées qui n'existent pas sur la classe concernée.
- Code concis quand une implémentation est nécessaire.
- Aller droit au but, pas de préambule type "Bien sûr, je vais t'aider".
- En cas d'ambiguïté, choisir l'hypothèse la plus raisonnable et l'annoncer
  en une phrase plutôt que de multiplier les questions.
- Signaler explicitement si une API/méthode/classe proposée n'est pas certaine
  d'exister sur la version Godot utilisée, plutôt que de l'affirmer par défaut.

## Outils

- Moteur : Godot 4 (GDScript)
- Animation (iPad) : Procreate (dessin) ; ToonSquid et/ou Procreate Dreams
  à l'étude.