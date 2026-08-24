# Projet : test-walk-2

Jeu 2D top-down en **Godot 4 (GDScript)**, style visuel cartoon/BD (pas pixel art),
animation poussée, complexité de gameplay significative (objets interactifs, PNJ,
puzzles, combat). Références de style : Hollow Knight, Cuphead.

## Objectif architectural

Système modulaire et scalable pour les objets de jeu interactifs (`DynamicObject`),
basé sur la **composition** plutôt que sur des scripts monolithiques. La logique
d'UI d'éditeur doit rester isolée dans des plugins, jamais mélangée aux scripts
de gameplay.

## Convention de nommage

- **`DynamicObject*`** : classes de gameplay cœur
  (`DynamicObjectState`, `DynamicObjectTrigger`, `DynamicObjectAction`,
  `DynamicObjectStateMachine`).
- **`Dot*`** : outillage éditeur uniquement
  (`DotGroupToggle`, `DotExtractors`, `DotChildPropertiesDropdown`,
  `DotToggleableGroup`).
- Éviter les noms `Object*` bruts (collision avec la classe `Object` de Godot).

## État actuel de l'architecture DynamicObject

- `DynamicObject` étend `Area2D` : orchestrateur léger, la logique est déléguée
  à des nœuds enfants spécialisés qui communiquent par signaux.
- Couche de données du state machine :
  - `DynamicObjectTrigger` (Resource : `source_state` + `event_type`)
  - `DynamicObjectState` (Resource : `id`, tableau de `triggers`, tableau
    polymorphe de `DynamicObjectAction`)
  - Stockage au format "triggered by" pour la lisibilité en éditeur ;
    `DynamicObjectStateMachine` construit un index inversé à `_ready()`
    pour une recherche O(1) à l'exécution.
- `DynamicObjectAction` utilise le **sous-classement** (`PlayAnimationAction`,
  `PlaySoundAction`, `PlayDialogueAction`, `SetOtherObjectStateAction`, etc.)
  plutôt qu'un enum de type, pour que chaque action n'expose que ses propres
  champs `@export` dans l'inspecteur.
- `SeenUnseenBehavior` : nœud enfant gérant la logique de réaction à la vision,
  émet les signaux `seen`/`unseen`. Délai géré via `Timer.new()` + `add_child()`.
- Système `EditorInspectorPlugin` custom : `DotGroupToggle`,
  `DotChildPropertiesDropdown` (extends `EditorProperty`), `DotExtractors`
  (expose les noms d'animation d'`AnimatedSprite2D` comme dropdowns).
- Approche hybride `@tool` : `EditorInspectorPlugin` gère l'affichage,
  `DotToggleableGroup` (`@tool` de base) gère la structure de la property list
  via `_validate_property`. `DotGroupToggle` cohabite avec cette couche.
- Tous les `DynamicObject` utilisent `AnimatedSprite2D` (même les objets
  statiques) pour simplifier le pipeline de prefabs.
- L'héritage de scène (`.tscn`) reflète l'héritage de script (`extends`) pour
  les hiérarchies PNJ/Ennemi/Marchand.

## Décisions d'architecture détaillées (state machine)

- **Composition stricte via position, pas hiérarchie logique** : `DynamicObjectStateMachine`
  et `SeenUnseenBehavior` sont **côte à côte**, enfants directs de `DynamicObject` — jamais
  l'un enfant de l'autre. Le lien entre eux passe uniquement par des signaux, jamais par la
  hiérarchie de scène.
- **Rangement visuel à grande échelle** : pour trier une vingtaine de nodes enfants, utiliser
  les **dossiers virtuels de l'éditeur** (clic droit dans le dock Scene → "Add Folder", Godot
  4.4+). Aucun effet sur les chemins runtime (`$NomDuNode` inchangé), aucun impact perf. Ne
  pas confondre avec un vrai Node parent intermédiaire (qui change les chemins et ajoute un
  niveau de transform).
- **Deux couches de données du state machine** :
  - Couche éditeur ("triggered by") : chaque `DynamicObjectState` porte ses `triggers`
    (chacun avec `source_state` + `event_type`), organisée **par état cible** — lisible,
    gère bien la convergence (plusieurs origines → même état cible).
  - Couche interne ("interrupt", index inversé) : construite une seule fois au `_ready()`
    de `DynamicObjectStateMachine`, classée **par état source**, pour lookup direct
    "je suis dans tel état + tel event arrive → je vais où". Jamais réexposée dans
    l'inspecteur.
- **`DynamicObjectAction`** : classe de base + sous-classes par type (pattern Strategy),
  chaque sous-classe expose ses propres `@export`. Un état peut porter **plusieurs actions**,
  exécutées en parallèle par défaut à l'entrée dans l'état (pas de séquençage temporel
  prévu pour l'instant).
- **`DynamicObjectStateMachine`** porte `states` et **son propre** `initial_state_id`
  (pas `DynamicObject`) — principe d'autonomie du composant, même logique que
  `SeenUnseenBehavior`. Reçoit des events génériques (`trigger("seen")`, etc.) sans
  distinction de traitement selon la source de l'event (vision, collision future,
  interaction future...).
- **Inspecteur unifié malgré la séparation en nodes** : même si les données vivent sur
  `DynamicObjectStateMachine`, l'inspecteur custom peut rester affiché uniquement sur
  `DynamicObject` (un `EditorInspectorPlugin` lit/écrit les `@export` du node enfant via
  `get_node`). Limite connue : nécessite un chemin prévisible vers le node tant qu'on
  reste sur une seule state machine par objet.
- **Dropdown dynamique pour `source_state`** : doit lister les `id` des states existants,
  même mécanisme que `DotChildPropertiesDropdown`/`DotExtractors`, mais alimenté par le
  tableau `states` du parent plutôt que par les enfants du node — nécessite un
  `EditorProperty` custom avec accès à l'ensemble du tableau `states`.
- **NPC devenant hostile** : ne jamais détruire/recréer le node (perte de références,
  d'état, de signaux). Composants présents dès le départ dans la scène mais **désactivés**
  par défaut (ex: `CombatComponent`), activés via une action dédiée
  (`SetComponentActiveAction`) déclenchée par un changement d'état.
- **Héritage** : script (`NPC.gd extends DynamicObject`) + scène ("New Inherited Scene"),
  cascade possible sur plusieurs niveaux. Garder la scène de base **minimale** (socle
  strict : vision, state machine, sprite) ; les composants spécifiques s'ajoutent dans
  les scènes héritées, pas dans la base.
- **Une seule state machine par objet par défaut** ; n'en envisager plusieurs que si des
  familles d'états varient sur des axes réellement indépendants (ex: attitude IA vs
  dialogue) — ne pas segmenter préventivement, seulement sur besoin concret.

## Maquette cible de l'inspecteur `DynamicObject` (états/triggers/actions)

Format visuel attendu pour éditer `DynamicObjectStateMachine.states` depuis l'inspecteur
de `DynamicObject` :

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

Implications :
- `EndOf` n'est pas un état séparé : c'est une valeur du dropdown `event_type`
  (`seen` / `unseen` / `endofaction`), appliquée conceptuellement au state courant
  ("l'action de ce state vient de se terminer").
- Chaque ligne de trigger affiche `event_type` + `source_state` sur une seule ligne →
  nécessite un `EditorProperty` custom par trigger avec deux dropdowns côte à côte,
  pas le rendu Resource par défaut de Godot.
- Chaque ligne d'action affiche un label de type + sa valeur clé (ex: `"Animation : idle"`)
  → chaque sous-classe de `DynamicObjectAction` doit pouvoir fournir ce label
  (convention à définir : méthode override, ou mapping dans le plugin).
- Tout le CRUD (`Add trigger`/`Add action`/`Add State`, suppression) est géré par le
  plugin custom, pas par le "+" par défaut de l'inspecteur pour `Array[Resource]`.
- `DynamicObjectState.name` doit passer en `@export` pour être affichable/éditable
  (actuellement non exporté).
- Le tableau `states` complet doit être piloté par un seul gros
  `EditorProperty`/`EditorInspectorPlugin` sur `DynamicObjectStateMachine`, affiché
  via `DynamicObject` — pas par l'inspecteur par défaut de chaque sous-Resource.

## À venir

- Système d'animation du joueur : animation squelette 2D (Spine2D ou
  `Skeleton2D` natif Godot) pressenti, pour l'animation en couches/blending.
  `AnimationTree` + `AnimationNodeStateMachine` réservé au joueur ; le FSM
  custom gère les autres objets.
- Nouvelles sous-classes `DynamicObjectAction` et composants
  (`DialogueComponent`, `CombatComponent`).
- Workflow d'animation iPad : Procreate (dessin) → ToonSquid / Procreate Dreams
  (symboles/instances) en cours d'évaluation.

## Apprentissages techniques (Godot)

- **Composition over monoliths** : `DynamicObject` reste un orchestrateur léger,
  le comportement vit dans des nœuds enfants typés communiquant par signaux.
- **Format données vs runtime** : stocker le state machine en format
  "triggered by" pour la clarté en éditeur ; inverser en format indexé par
  source à l'exécution pour la performance.
- **`@onready` + `_get_property_list()`** : les `@onready var` ne sont pas
  encore assignées quand l'éditeur appelle `_get_property_list()`. Fix :
  `notify_property_list_changed()` dans `_ready()`, protégé par
  `Engine.is_editor_hint()`.
- **`_process()` + `clear()`** : appeler `dropdown.clear()` à chaque frame
  réinitialise silencieusement `auto_translate_mode` à `INHERIT`. Refixer le
  mode après chaque `clear()`, ou reconstruire conditionnellement via un
  tableau `_last_items` mis en cache et comparé élément par élément.
- **Sentinelle `[Aucune]`** : stocker `""` (pas la chaîne d'affichage) quand
  l'item "aucun" est sélectionné ; restaurer la sélection en testant `""`
  explicitement.
- **`_parse_group` vs `_parse_property`** : les en-têtes de groupe passent par
  `_parse_group` (pas de valeur de retour) — impossible de les supprimer
  depuis le plugin seul sans `@tool` sur l'objet.
- **Cache global des `class_name`** : erreurs parser "not declared in current
  scope" sur des références `class_name` indiquent souvent un cache obsolète ;
  redémarrer Godot ou supprimer `.godot/` pour forcer un re-scan.
- **Scene Reload > Soft Reload** : "Scene > Reload Saved Scene" est fiable pour
  rafraîchir l'inspecteur après un changement de script ; "Soft Reload" (clic
  droit sur le script) ne l'est pas.
- **Plancher `wait_time = 0`** : Godot impose un minimum ; utiliser
  `max(delay, 0.001)` en contournement.
- **Pas d'abstraction prématurée** : différer les migrations architecturales
  (ex. state machine enum/match) jusqu'à un besoin concret.

## Inventaire de l'outillage éditeur (`addons/`)

- **`addons/dynamic_object_tools/`** : plugin principal.
  - `plugin.gd` (`EditorPlugin`) enregistre `inspector_plugin.gd`, avec reload forcé
    du script via `ResourceLoader.CACHE_MODE_IGNORE` (contournement du souci de cache
    de `class_name`).
  - `inspector_plugin.gd` (`EditorInspectorPlugin`, `_can_handle` → `DynamicObject`) :
    gère aujourd'hui uniquement l'ancien système (toggle "Vision Behaviour" via
    `DotGroupToggle`, dropdowns d'animation seen/unseen via `DotChildPropertiesDropdown`).
    **Rien encore pour `states`/`triggers`/`actions`** — reste à construire pour la
    maquette d'inspecteur cible. Contient un vieux brouillon `AnimationDropdown`
    commenté (remplacé par `DotChildPropertiesDropdown`), candidat à suppression.
- **`addons/tools/`** : briques `EditorProperty` réutilisables.
  - `DotGroupToggle` : checkbox qui active/désactive un groupe de propriétés entier
    (lit `PROPERTY_USAGE_GROUP` via `get_property_list()`).
  - `DotChildPropertiesDropdown` : dropdown générique — trouve un enfant d'un type
    donné et appelle un `Callable` extracteur pour peupler la liste. Réutilisable
    tel quel pour le futur dropdown `animation_name` d'`ActionPlayAnimation`.
  - `DotExtractors` : fonctions d'extraction statiques (`extract_animations` pour
    l'instant).
- **`addons/editor_utils/dot_toggleable_group.gd`** : `DotToggleableGroupUtil
  .validate_group_header()`, logique statique pour masquer un header de groupe
  selon un toggle. **Prêt mais pas encore appelé** — nécessiterait un
  `_validate_property()` sur `DynamicObject`, absent actuellement.
- **`addons/collapse_children/`** : plugin indépendant sans rapport avec
  `DynamicObject` (raccourci Alt+clic / Ctrl+Alt+C pour replier les enfants dans
  le dock Scene).

Pour la maquette d'inspecteur `states`/`triggers`/`actions`, il manque encore :
un `EditorProperty` pour une ligne de trigger (2 dropdowns event_type + source_state),
un `EditorProperty` pour une ligne d'action (label + valeur + suppression), un
composant englobant pour un bloc State (header + triggers + actions + boutons Add),
et le branchement dans `inspector_plugin.gd` pour intercepter la propriété `states`
de `DynamicObjectStateMachine` (lu via `get_node` depuis `DynamicObject`).

## État d'implémentation (constaté par lecture de code)

Fichiers existants dans `Scripts/Dynamic Object/` : `dynamic_object.gd`,
`dynamic_object_state_machine.gd`, `dynamic_object_state.gd`,
`dynamic_object_trigger.gd`, `dynamic_object_action.gd`,
`action_play_animation.gd`, `seen_unseen_behavior.gd`, `vision_detector.gd`.

Points connus à corriger/finir dans `dynamic_object_state_machine.gd` :
- `check_triggers(event_type)` est commenté, non implémenté.
- Syntaxe de connexion de signal invalide : `x.connect.signal_name(callback)`
  au lieu de `x.signal_name.connect(callback)` (présent sur `seen_unseen` et
  sur chaque `action` dans `goto_state()`).
- `define_next_state()` calcule `next_state` mais `goto_state()` ne l'utilise
  jamais ; la transition réelle doit se faire depuis `check_triggers()`.
- `DynamicObjectState` (`name`, `triggers`, `actions`) et `DynamicObjectTrigger`
  (`source_state` en `String`, pas encore en dropdown) n'ont pas encore tous
  leurs champs en `@export`, donc pas encore éditables/visibles dans
  l'inspecteur par défaut.
- `dynamic_object.gd` n'a pas encore migré vers le state machine générique :
  il garde son ancien système d'animations seen/unseen codées en dur
  (`seen_animation`, `unseen_animation`, timers). Migration objet par objet
  envisagée, possiblement via un flag `use_state_machine` en transition.

## Préférences de travail

- Toujours répondre en français, quel que soit le contenu du code, des
  commentaires ou des messages de diagnostic (qui peuvent rester en anglais).
- Comprendre l'architecture conceptuellement avant d'implémenter ;
  privilégier les explications sans code lors de l'exploration du design.
- Solutions pragmatiques et simples ; pousser back contre l'over-engineering
  et les API suggérées qui n'existent pas sur la classe concernée.
- Code concis quand une implémentation est nécessaire.
- Contexte mixte français/anglais (certaines chaînes UI et commentaires en
  français).

## Outils

- Moteur : Godot 4 (GDScript)
- Animation (iPad) : Procreate (dessin) ; ToonSquid et/ou Procreate Dreams
  à l'étude.
