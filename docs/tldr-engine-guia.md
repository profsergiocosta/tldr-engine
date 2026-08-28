# tlDR Engine — Guia de Arquitetura

> Base de conhecimento sobre a **tlDR Engine v2.2.1**, uma engine 1:1 de DELTARUNE feita em GameMaker.
> Escrito para quem **já programa** mas nunca usou GameMaker, com o objetivo de usar a engine como base de um RPG próprio.
>
> Gerado a partir da leitura direta do código-fonte (172 objetos, 386 scripts, 41.029 linhas de GML).
> Caminhos de arquivo são relativos à raiz do projeto.

---

## Índice

1. [Ficha técnica](#1-ficha-técnica)
2. [GameMaker: o mínimo que você precisa saber](#2-gamemaker-o-mínimo-que-você-precisa-saber)
3. [O modelo mental da engine](#3-o-modelo-mental-da-engine)
4. [Estrutura de pastas](#4-estrutura-de-pastas)
5. [Boot: `room_init` e `o_world`](#5-boot-room_init-e-o_world)
6. [A room como interface de autoria](#6-a-room-como-interface-de-autoria)
7. [Cutscenes](#7-cutscenes)
8. [Diálogo e a linguagem de markup](#8-diálogo-e-a-linguagem-de-markup)
9. [Atores e party](#9-atores-e-party)
10. [Itens e inventário](#10-itens-e-inventário)
11. [Encontros (batalha)](#11-encontros-batalha)
12. [Lojas](#12-lojas)
13. [Save e memories](#13-save-e-memories)
14. [Localização](#14-localização)
15. [Subsistemas menores](#15-subsistemas-menores)
16. [Console de debug](#16-console-de-debug)
17. [Convenções de nomenclatura](#17-convenções-de-nomenclatura)
18. [Variáveis globais](#18-variáveis-globais)
19. [Armadilhas conhecidas](#19-armadilhas-conhecidas)
20. [Roteiro de estudo](#20-roteiro-de-estudo)
21. [Receitas rápidas](#21-receitas-rápidas)
22. [Glossário](#22-glossário)

---

## 1. Ficha técnica

| | |
|---|---|
| Nome | tlDR Engine (*Totally Lit DELTARUNE Engine*) |
| Versão | `v2.2.1` (`GAME_VERSION` em `scripts/game_info/game_info.gml`) |
| Última versão de save compatível | `v2.0.0` (`GAME_LAST_COMPATIBLE_VERSION`) |
| Linguagem | GML (GameMaker Language), estilo moderno: structs, constructors, methods |
| Objetos | 172 |
| Scripts | 386 (inclui bibliotecas externas) |
| Sprites | 582 |
| Rooms | 19 |
| Sons | 90 |
| Linhas de GML | 41.029 |
| Resolução lógica | 320 × 240 (`GAME_W` / `GAME_H`) |
| Camada de GUI | 640 × 480 (`GAME_W_GUI` / `GAME_H_GUI`) |

**Bibliotecas de terceiros embutidas** (em `@Engine/External Libraries`, não modificar):

- **Input** — biblioteca de entrada de Juju Adams (teclado, gamepad, rebinding, hotswap)
- **Clean Shapes** — desenho de formas vetoriais anti-aliased, também de Juju Adams
- **Anime** — biblioteca de animação/tweening de futuregamer25 (`animate()`, `lerp_type`)
- **Retro Palette Swap** — shader de troca de paleta (`pal_swap_init_system`)

**Bibliotecas opcionais** (`@Libraries/`): `dark_lighting_ch4`, `music_pitcher`, `ripple`, `beat_pulser`.

**Links oficiais**:
- Documentação: https://docs.google.com/document/d/14SpnU32P-_HLdNS17gwaIe8Z2mO8AG1KUUGMe_hNdzM/edit
- Discord: https://discord.gg/x3t8JTyC2p

---

## 2. GameMaker: o mínimo que você precisa saber

Se você vem de programação "normal", estes são os conceitos que não têm equivalente óbvio e que confundem no começo.

### 2.1 Objeto vs. instância

- **Objeto** (`o_actor`) é a classe/template. Fica em `objects/o_actor/`.
- **Instância** é a cópia viva dentro de uma room. Tem um `id` numérico.
- Instâncias colocadas no room editor têm **id estável entre execuções** (aparecem como `inst_2A8AF2D1`). É por isso que a engine usa `id` como chave do sistema de memories.

### 2.2 Eventos = arquivos

Um objeto não é um arquivo só. Cada **evento** é um `.gml` separado dentro da pasta do objeto. O nome do arquivo codifica o evento — essa tabela é essencial para ler o código:

| Arquivo | Evento | Quando roda |
|---|---|---|
| `Create_0.gml` | Create | uma vez, ao criar a instância |
| `Destroy_0.gml` | Destroy | ao destruir |
| `CleanUp_0.gml` | Clean Up | ao destruir, inclusive no fim do jogo |
| `Step_0.gml` | Step | todo frame |
| `Step_1.gml` | Begin Step | todo frame, **antes** de todos os Step |
| `Step_2.gml` | End Step | todo frame, **depois** de todos os Step |
| `Alarm_0.gml` … `Alarm_11.gml` | Alarm 0–11 | quando o contador `alarm[n]` chega a zero |
| `Draw_0.gml` | Draw | desenho no mundo |
| `Draw_64.gml` | Draw GUI | desenho na camada de interface (640×480) |
| `Draw_72.gml` / `Draw_73.gml` | Draw Begin / Draw End | antes/depois de todos os Draw |
| `Draw_74.gml` / `Draw_75.gml` | Draw GUI Begin / Draw GUI End | idem, na GUI |
| `Draw_76.gml` / `Draw_77.gml` | Pre Draw / Post Draw | fora do ciclo normal de desenho |
| `Draw_65.gml` | Window Resize | ao redimensionar a janela |
| `Other_2.gml` | **Game Start** | uma vez, no início do jogo |
| `Other_3.gml` | Game End | ao fechar |
| `Other_4.gml` | **Room Start** | ao entrar numa room |
| `Other_5.gml` | Room End | ao sair de uma room |
| `Other_7.gml` | Animation End | quando a animação do sprite dá a volta |
| `Other_10.gml` … `Other_25.gml` | **User Event 0–15** | só quando você chama `event_user(n)` |

Os **User Events** são o mecanismo mais usado pela engine para criar "métodos" nomeados em objetos. Exemplos reais:

- `o_trigger/Other_10.gml` = User Event 0 = "trigger entrou"
- `o_trigger/Other_11.gml` = User Event 1 = "trigger saiu"
- `o_ow_interactable/Other_10.gml` = User Event 0 = "foi interagido"
- `o_text_typer/Other_10.gml` = User Event 0 = "executar comando de markup"

Distribuição real no projeto: 166 `Create_0`, 98 `Step_0`, 62 `Draw_0`, 40 `Other_10`, 32 `Draw_64`, 25 `Alarm_0`.

### 2.3 Herança de objetos

Um objeto pode ter um **parent**. `event_inherited()` chama o evento equivalente do pai — é o `super()`. Exemplo: `o_ow_interactable` herda de `o_ow_depthobj`, e `o_actor_kris` herda de `o_actor`.

### 2.4 `with` — o loop sobre instâncias

```gml
with (o_dev_marker) {          // roda o bloco no escopo de CADA instância de o_dev_marker
    if m_type == _m_type && m_id == _m_id
        return id
}
```

Dentro de `with`, `self` é a instância iterada e `other` é o escopo de fora. Aparece o tempo todo na engine.

### 2.5 `persistent`

Um objeto marcado como `persistent` sobrevive à troca de rooms. Na engine só o `o_world` (e alguns UI) são persistentes.

### 2.6 `instance_deactivate` ≠ `instance_destroy`

Instâncias **desativadas** continuam existindo mas não rodam eventos nem aparecem em `with()`. A engine usa isso para encadear cutscenes (`instance_deactivate_object(id)` no começo, `instance_activate_object(inst_XXXX)` quando é a vez dela). Se algo "sumiu", verifique se não está apenas desativado.

### 2.7 Structs e constructors

GML não tem classes, mas tem:

```gml
function base() constructor {
    x = 0
    metodo = function() { return x }
}
function derivado() : base() constructor {   // herança
    x = 10
}
var inst = new derivado()
```

Funções guardadas em structs são **methods** — têm `self` ligado ao struct. `method(self, f)` religa manualmente.

### 2.8 `.yy` e `.yyp`

Todo recurso tem um `.yy` (JSON com metadados). O `.yyp` na raiz é o manifesto do projeto: lista de recursos, pastas e — importante — o `RoomOrderNodes`, que define a **ordem das rooms**.

---

## 3. O modelo mental da engine

Três ideias explicam quase todo o código.

### 3.1 Struct é a classe

Todo dado de conteúdo (item, inimigo, encontro, loja, borda) é uma função construtora que herda de uma base e sobrescreve só o que muda.

```gml
function ex_item_butjuice() : item() constructor {
    name = "ButJuice"
    desc = ["It's short for ButlerJuice.", "Heals\n 100HP", "", "Short for ButlerJuice\n+100HP"]

    use = function(item_index, target_index, caller = -1) {
        party_heal(global.party_names[target_index], 100, caller)
        item_delete(item_index)
    }
    reactions = { susie: "Hell'd you call this!?", ralsei: "I made this." }
    buy_price = 200

    item_localize("ex_item_butjuice")
}
```

**Padrão recorrente e muito importante:** quase todo campo dessas structs aceita **um valor ou uma função (callable)**. `buy_price`, `can_use`, `flavor`, `color`, `enabled`, `dialogue`, `shop_in_stock` — se você passar uma função, a engine a chama no momento do uso. Antes de escrever lógica em volta de um struct, verifique se o campo já aceita callable. Normalmente aceita.

### 3.2 A room é a interface de autoria

Você não escreve conteúdo em scripts. Você arrasta objetos deliberadamente vazios na room e preenche o comportamento no **Instance Creation Code** daquela instância específica. Detalhado na seção 6.

### 3.3 `o_world` é o kernel

Singleton `persistent` que monta o jogo inteiro. Detalhado na seção 5.

---

## 4. Estrutura de pastas

A árvore do Asset Browser (campo `parent` de cada `.yy`) é **apenas organização visual** — não tem relação com ordem de execução nem com o sistema de arquivos.

```
@Engine/                     núcleo — leia bastante, altere pouco
  scripts/
    systems/engine/          actors_scr, borders, climb, dialogue, dodge,
                             lighting, recruits, typer_chars
    systems/general/external cutscenes, cutscene_events, cutscene_shortcuts,
                             markers, memories, music
    systems/general/internal loc, save, save_entries, save_settings
    encounter/               enc_actions, enc_buttons, enc_enemies, enc_scripts,
                             enc_sets, enc_setup, enc_scene_defaults
    inventory/               item, items_consumables, items_weapons, items_armors,
                             items_spells, items_key
    party/                   party_init, party_get, party_set, party_hp, party_scripts
    shops/                   shops, shop_options, shop_scripts
    macro/                   macro_depth, macro_dir, macro_markers
    (raiz)                   custom, misc, game_info, deprecated
  objects/
    actors/                  o_actor + party/ + enemies/
    dev/                     markers/, climb/, menus/, squares/, triggers/
    enc/                     bullets/, turns/, ui elements/ (box, soul, misc)
    ow/                      dodge/, misc/ — objetos de overworld
    ui/                      menus e text/
    effects/                 particles/, spells/
    misc/
  rooms/                     room_init, room_shop, room_gameover,
                             room_save_select, room_chapter_select,
                             room_ex_infinity_room
  External Libraries/        Input, Clean Shapes — NÃO MEXER
  sprites/ sounds/ fonts/ shaders/ tilesets/ music/ paths/

zzz Examples/                conteúdo de exemplo — seu playground, apagável
  Scripts/                   ex_items, ex_shop, ex_borders, ex_typer_chars
  Scripts/encounter/         ex_enc_enemies, ex_enc_sets, ex_enc_enemies_recruits
  Objects/ow/                church/, city/, dforest/, test/
  Rooms/                     room_ex_church, room_ex_city, room_ex_dforest,
                             room_ex_light_world, room_ex_multi_path,
                             room_test_main, room_test_movement, room_test_inventory,
                             room_test_shops, room_test_climbing, room_test_cutscene,
                             room_test_loopback
  Sprites/ Sounds/ Tile Sets/ Music/ Paths/

@Libraries/                  plugins opcionais
  dark_lighting_ch4          iluminação do capítulo 4
  music_pitcher              alteração de pitch da trilha
  ripple                     efeito de ondulação
  (raiz) beat_pulser
```

### A regra de ouro

Para cada sistema de `@Engine` existe um **arquivo espelho** em `zzz Examples/Scripts` com prefixo `ex_`:

| Núcleo | Espelho de exemplo |
|---|---|
| `items_consumables`, `items_weapons`, … | `ex_items` |
| `enc_sets` | `ex_enc_sets` |
| `enc_enemies` | `ex_enc_enemies` |
| `enc_enemies_recruits` | `ex_enc_enemies_recruits` |
| `shops` | `ex_shop` |
| `borders` | `ex_borders` |
| `typer_chars` | `ex_typer_chars` |

**É nesses arquivos `ex_` que você escreve seu conteúdo.** Melhor ainda: crie arquivos com o prefixo do seu jogo (`rpg_items`, `rpg_enc_sets`) e apague `zzz Examples` inteira quando não precisar mais dos exemplos.

### Distribuição das rooms por pasta

Cuidado: as rooms estão espalhadas entre pastas, o que faz parecer que algumas "sumiram".

| Room | Pasta |
|---|---|
| `room_init`, `room_chapter_select`, `room_save_select`, `room_shop`, `room_gameover`, `room_ex_infinity_room` | `@Engine/rooms` |
| `room_ex_church`, `room_ex_city`, `room_ex_dforest`, `room_ex_light_world`, `room_ex_multi_path`, `room_test_*` | `zzz Examples/Rooms` |
| `room_lb_dark_lighting` | `@Libraries/dark_lighting_ch4` |

---

## 5. Boot: `room_init` e `o_world`

### `room_init`

Room sem cenário nenhum. Contém **uma única instância: `o_world`**. Existe só para bootar o jogo.

### `o_world`

Objeto `persistent: true` — sobrevive a todas as trocas de room. É o kernel.

**`objects/o_world/Create_0.gml`** — define as globais e as configurações persistentes:

```gml
frames = 0
volume_sfx = 1  |  volume_bgm = 1  |  volume_master = .6
window_scale = 1  |  window_border_scale = 1  |  fullscreen_scale = 1
allow_incompatible_saves = false

global.temp_choice = 0            // resultado do último {choice(...)}
global.typer_chars = {}           // personagens de diálogo registrados
global.simplify_vfx = false
global.current_light = c_white
global.console = false            // true = console/menu aberto, trava o input do jogo
global.current_cutscene = noone
global.time = 0
global.memories = {}
global.room_name = ""
global.menu_page = 0
global.player_moveable_global = true
global.border_mode = BORDER_MODE.OFF
global.console_enabled = true
global.climbing_enabled = function() { return item_contains(item_key_claimbclaws) }
global.party_limit = 3            // undefined = ilimitado
global.slide_speed = 5
global.ow_dodge_inv = 40

// emissores e buses de áudio (emitter_sfx/bus_sfx, emitter_bgm/bus_bgm, eff_reverb)
// save_settings_init() + save_entry(...) das configurações
// inventário: global.items, global.key_items, global.weapons, global.armors,
//             global.storage, global.recruits, global.lw_items, ...
```

**`objects/o_world/Other_2.gml` (Game Start)** — o boot propriamente dito, na ordem:

1. `randomize()`, `pal_swap_init_system(shd_pal_swapper)`, `save_init()`
2. Cria os objetos onipresentes: `o_camera`, `o_window`, `o_dev_musiccontrol`, `o_fader`, `o_flash`
3. Checagem de compatibilidade de save (pode abrir `o_dev_savewipe_prompt`)
4. Cria `o_console` se `global.console_enabled`
5. Calcula escala de janela (mesma fórmula do DELTARUNE), aplica bordas, `window_center()`
6. `enum WORLD_TYPE { DARK, LIGHT }`, `global.world = WORLD_TYPE.DARK`
7. Cria `o_ui_quit`; define `global.chapter = 1`
8. Registra **todas** as `save_entry(...)` do jogo — há um comentário marcando onde adicionar as suas:
   ```gml
   // if you wish to add new save entries, please add them here ⌄⌄⌄⌄⌄⌄⌄⌄
   ```
9. `party_init()`, define `global.party_names = ["kris","susie","ralsei"]`, `party_apply_equipment()`
10. Carrega fontes por sprite (`global.font_ui_hp`, `font_numbers_w`, `font_numbers_g`)
11. `save_reload()` + `save_load(global.save_slot)`
12. `typer_chars_init()` e registro dos personagens de diálogo
13. **`room_goto_next()`** ← última linha

**Consequência crítica:** `room_init` precisa ser a **primeira** room da room order. Como o boot termina em `room_goto_next()`, a room que você quer como inicial deve ser a **segunda**. Sem `o_world`, nenhuma global existe e qualquer room quebra imediatamente.

**Outros eventos de `o_world`:**
- `Other_4.gml` (Room Start) — `global.menu_page = 0`
- `Step_0.gml`, `Step_1.gml`, `Other_3.gml`, `Other_10.gml`

---

## 6. A room como interface de autoria

Dois mecanismos da IDE fazem todo o trabalho de autoria de conteúdo.

### 6.1 Instance Creation Code

Cada instância numa room pode ter **um bloco de código só dela**. Na IDE: botão direito na instância dentro do room editor → *Instance Creation Code*. No disco vira `rooms/<room>/InstanceCreationCode_inst_XXXXXXXX.gml`.

A engine oferece objetos praticamente vazios com **slots de função** que você preenche ali.

**`o_trigger`** — o objeto inteiro:

```gml
// objects/o_trigger/Create_0.gml
triggered = false
trigger_exit = false
controlled_activation = true   // só dispara se o player estiver no controle
can_trigger = true

trigger_code      = function(){}   // ao entrar   (User Event 0 → Other_10.gml)
trigger_exit_code = function(){}   // ao sair     (User Event 1 → Other_11.gml)
trigger_step_code = function(){}   // a cada frame dentro
```

```gml
// objects/o_trigger/Step_0.gml
if place_meeting(x, y, get_leader()) {
    if !triggered && !controlled_activation && can_trigger
        event_user(0)
    else if !triggered && controlled_activation && instance_exists(get_leader())
            && get_leader()._checkmove() && can_trigger
        event_user(0)

    if triggered
        trigger_step_code()
}
else if trigger_exit
    event_user(1)
```

E o comportamento real de **uma** instância mora na room:

```gml
// rooms/room_ex_church/InstanceCreationCode_inst_2A8AF2D1.gml
count = 0
trigger_code = function() {
    cutscene_create()
    if count == 0
        cutscene_dialogue([
            "* (You were going to leave, but...)",
            "* (The road was cut abruptly right before you.)"
        ])
    else
        cutscene_dialogue(["* (There is no road.)"])

    cutscene_func(function() {
        actor_move(get_leader(), new actor_movement(-20, 0, 30,,, DIR.RIGHT, false))
    })
    cutscene_sleep(20)
    cutscene_set_variable(id, "triggered", false)   // rearma o trigger
    cutscene_party_interpolate()
    cutscene_play()
    count++
}
```

Objetos com o mesmo padrão:

| Objeto | Slots |
|---|---|
| `o_trigger` | `trigger_code`, `trigger_exit_code`, `trigger_step_code` |
| `o_ow_interactable` | `interaction_code`, `interaction_args` |
| `o_ow_sign` | `text` (e chama `dialogue_start(text)`) |
| `o_actor_interactable` | herda `interaction_code` de `o_actor` |

### 6.2 Variable Definitions

Um objeto declara variáveis expostas (aba *Variable Definitions* no editor de objetos) e você preenche o valor **por instância**, no inspetor da room, sem escrever código.

| Objeto | Variáveis | Uso |
|---|---|---|
| `o_dev_marker` | `m_id`, `m_type`, `m_toggle_group`, `walk_toggle`, `sprite_index` | ponto nomeado no mapa |
| `o_dev_music` | `mus`, `slot`, `pitch`, `gain`, `loop` | trilha da área |
| `o_dev_world` | `world` (`WORLD_TYPE.DARK` / `.LIGHT`) | chama `world_switch(world)` no Create |
| `o_dev_border` | `_border_name` | moldura da tela |
| `o_dev_ambiance` | `footsteps` | som de passos da área |
| `o_ow_shortcut_door` | `room_1..3`, `room_1_name..3`, `current_room_name` | porta com menu de destinos |

### 6.3 Objetos `o_dev_*` (a caixa de ferramentas do room editor)

| Objeto | Função |
|---|---|
| `o_dev_playermarker` | no Room Start cria o líder (`party_leader_create`) e o resto do grupo. **Toda room jogável precisa de um.** |
| `o_dev_world` | define Dark World / Light World da room |
| `o_dev_music` | toca a trilha da área |
| `o_dev_ambiance` | som ambiente e passos |
| `o_dev_border` | moldura da tela |
| `o_dev_marker` | ponto nomeado (base de warps, escaladas, posições de cutscene) |
| `o_dev_marker_land` | marcador de chegada de transição entre rooms |
| `o_dev_marker_climb` | marcador de fim de escalada |
| `o_dev_marker_enemy_defeat` | onde o inimigo cai ao ser derrotado |
| `o_dev_climb_tile` / `_auto` / `_catcher` / `_interact` / `_controller` | sistema de escalada |
| `o_dev_roomselect`, `o_dev_partyselect`, `o_dev_encselect` | menus do console (herdam de `o_dev_selector`) |
| `o_dev_savewipe_prompt` | aviso de save incompatível |

Objetos de colisão: `o_block` (retangular) e `o_block_diag` (diagonal).

### 6.4 Markers e navegação

```gml
marker_get(m_type, m_id)                      // → Id.Instance ou noone
marker_find_closest(xx, yy, mtype)            // → marcador mais próximo do tipo

party_leader_warp(target_marker_type, target_marker_id, warp_dir = DIR.DOWN)

// tipos embutidos — scripts/macro_markers/macro_markers.gml
#macro MARKER_GENERIC       ""
#macro MARKER_CLIMB         "climb"
#macro MARKER_ENEMY_DEFEAT  "enemy_defeated"
#macro MARKER_LAND          "land"
```

`m_type` e `m_id` são livres — no `room_ex_church` há marcadores com `m_type = "prophecy_pos"` e `m_id` igual ao nome do personagem, para posicionar cada membro do grupo numa cutscene.

### 6.5 Anatomia de uma room nova

1. `o_dev_playermarker` — onde o grupo aparece
2. `o_dev_world` — Dark ou Light
3. `o_dev_music` — trilha
4. `o_dev_ambiance` — passos/ambiente (opcional)
5. `o_block` / `o_block_diag` nas paredes
6. `o_dev_marker` com `m_type = MARKER_LAND` nas saídas
7. `o_trigger` nas bordas, com `party_leader_warp()` ou `room_goto()` no `trigger_code`
8. `o_ow_sign`, `o_ow_npc`, `o_ow_chest`, `o_ow_save` para conteúdo

Zero código de infraestrutura.

---

## 7. Cutscenes

`scripts/cutscenes/cutscenes.gml` + `scripts/cutscene_events/cutscene_events.gml` (444 linhas) + `scripts/cutscene_shortcuts/cutscene_shortcuts.gml`.

### Modelo

Uma **fila de eventos**, não uma máquina de estados. Cada evento tem uma condição de retomada, então a fila se auto-sincroniza.

```gml
function cutscene_event(_call, _resume_condition = undefined, _step = undefined, _finish = undefined) constructor
```

### Ciclo de vida

```gml
cutscene_create()        // abre a fila e a define como global.current_cutscene
  ...comandos...         // cada cutscene_* empilha um evento
cutscene_play()          // executa
```

Outras funções: `cutscene_get_current()`, `cutscene_set_current(c)`, `cutscene_stop(c)`, `cutscene_queue_event(c, e)`, `cutscene_isvalid(c)`.

O parâmetro `wait` aparece em quase todos os comandos: `true` bloqueia a fila até terminar, `false` dispara em paralelo com o próximo. É assim que se move três personagens simultaneamente.

### Comandos

| Função | O que faz |
|---|---|
| `cutscene_dialogue(dialogue, postfix="{p}{e}", wait=true, box_pos_down, _destroy_other)` | caixa de diálogo; aceita array de falas |
| `cutscene_actor_dialogue(dialogue, actor_inst, prefix, postfix, wait, coming_from)` | balão preso a um ator |
| `cutscene_choicer(_choices, wait=true, box_pos_down)` | menu de escolha; resultado em `global.temp_choice` |
| `cutscene_wait_dialogue_boxes(n)` | espera N caixas passarem — sincroniza pose com fala |
| `cutscene_wait_dialogue_finish()` | espera o diálogo acabar |
| `cutscene_actor_move(target, movement, wait=true)` | move um ator (`new actor_movement(...)`) |
| `cutscene_party_follow(follow)` | liga/desliga o grupo seguindo o líder |
| `cutscene_party_interpolate()` | reagrupa a fila indiana suavemente |
| `cutscene_player_canmove(_can_move, _global=false)` | tira/devolve o controle |
| `cutscene_camera_pan(x, y, time, wait, ease, confined_x, confined_y)` | move a câmera |
| `cutscene_set_variable(instance, "nome", valor)` | escreve variável de instância no tempo certo |
| `cutscene_set_partysprite(party_name, sprite_ref, image_index, image_speed)` | troca o sprite de um membro |
| `cutscene_anim(v1, v2, frames, ease, call_method)` | anima passando o valor a um callback |
| `cutscene_animate(v1, v2, frames, ease, inst, var_name)` | anima uma variável de instância |
| `cutscene_instance_create(obj, x, y, depth, post_var_struct)` | cria instância já com variáveis |
| `cutscene_audio_play(sound, loop, gain, pitch, nonstack, sound_type, offset)` | som |
| `cutscene_sleep(frames)` | pausa |
| `cutscene_wait_until(resume_condition, arguments)` | espera uma condição |
| `cutscene_func(func, args)` | escape hatch: roda GML arbitrário |
| `cutscene_debug_message(msg)` | log |

**Atalhos** (`cutscene_shortcuts.gml`): `cutscene_spare_enemy(index)`, `cutscene_actor_override(actor_inst, override)`, `cutscene_enc_wait(wait)`.

### Rodar só uma vez

```gml
if memory_get("cutscenes", id) {
    instance_destroy()
    instance_activate_object(inst_3CB25A36)   // ativa o estado "pós-cutscene"
    exit
}
```

### Melhor material de estudo

`room_test_cutscene` — cena longa e real: câmera, poses, movimentação sincronizada de três personagens, diálogo, tudo no Instance Creation Code de dois triggers.

---

## 8. Diálogo e a linguagem de markup

Objeto: `o_text_typer`. Parser dos comandos: `objects/o_text_typer/Other_10.gml` (User Event 0).

Fora de cutscene: `dialogue_start(text, _destroy_other_instances = true, allow_movement = false)`.

### Sintaxe

Tags entre chaves, argumentos entre parênteses separados por vírgula. Crases (`` ` ``) protegem strings que contenham vírgulas.

```gml
"{char(susie, 6)}* Woah... Is that...{p}{e}"
"* {col(y)}TP{col(w)} Gain reduced outside of {col(g)}COURAGE{col(w)}!"
"{char(susie, 26)}* Heh. {mini(`(I'd need a chair...)`, noelle, 7)}"
```

### Tabela completa de comandos

| Tag | Efeito |
|---|---|
| `{char(nome, face)}` | define quem fala + expressão do retrato |
| `{face(...)}` / `{f_ex(...)}` | troca só o retrato |
| `{voice(...)}` | som de voz da fala |
| `{s(n)}` / `{sleep(n)}` | espera n frames no meio da digitação |
| `{p}` / `{pause(n)}` | pausa até o botão / por n frames |
| `{e}` / `{end}` / `{stop}` | encerra a caixa |
| `{c}` / `{clear}` | limpa a caixa e continua |
| `{br}` | quebra de linha |
| `{speed(n)}` | velocidade de digitação |
| `{instant}` | escreve tudo de uma vez |
| `{col(x)}` / `{color(...)}` / `{solid_col(...)}` / `{reset_col}` | cor do texto |
| `{font(...)}` | troca de fonte |
| `{shadow(...)}` | sombra do texto |
| `{eff(...)}` / `{effect(...)}` / `{eff_reset}` / `{effect_reset}` | efeito de texto |
| `{choice(\`a\`, \`b\`)}` | menu de escolha inline → `global.temp_choice` |
| `{mini(texto, quem, face)}` | balãozinho paralelo de outro personagem |
| `{spr(...)}` / `{sprite(...)}` | sprite embutido na fala |
| `{snd(...)}` / `{sound(...)}` | som embutido |
| `{box_pos(...)}` / `{preset(...)}` | posição / preset da caixa |
| `{scale}` `{xscale}` `{yscale}` `{xspace}` `{yspace}` `{resetx}` | métricas do texto |
| `{auto_pauses}` `{auto_breaks}` `{break_system}` `{break_tabulation}` | comportamento de quebra automática |
| `{can_skip(...)}` / `{can_superskip(...)}` | permite ou bloqueia pular |
| `{money_display}` / `{money_display_hide}` | contador de dinheiro |
| `{link(...)}` / `{unlink(...)}` / `{npc_link(...)}` / `{npc_unlink(...)}` | vincula a caixa a uma instância |
| `{link_var_set(...)}` / `{link_sprite_set(...)}` | manipula a instância vinculada |
| `{god}` | modo de debug do typer |

### Personagens de diálogo (typer chars)

Registrados em `scripts/typer_chars/typer_chars.gml` e nos exemplos `ex_typer_chars`. O `o_world` faz `typer_chars_init()` e depois `new ex_typer_gerson().__initialize()`. É o que faz `{char(gerson, 3)}` funcionar.

### Funções relacionadas

```gml
dialogue_start(text, _destroy_other_instances, allow_movement)
dialogue_array_to_string(arr)
text_typer_create(text, xx, yy, depth, prefix, postfix, var_struct, end_with_stop)
actor_dialogue_create(text, actor_inst, prefix, postfix, var_struct, off_x, off_y, off_type, coming_from)
text_typer_choicer(_choices, _caller, _box_pos_down)
ui_dialoguebox_create(xx, yy, width, height, world)
```

---

## 9. Atores e party

### `o_actor`

Classe base de todo personagem andante. `Create_0.gml` tem ~260 linhas de configuração. Campos principais:

**Identidade** — `name`, `is_enemy`, `is_follower`, `is_player`, `is_party`, `is_in_battle`, `is_selected_for_battle`

**Movimento** — `spd` (2 no Dark World, 3 no Light), `basespd`, `auto_run`, `noclip`, `diagonal`, `slide_vertical_allow`, `spacing` (12), `dir` (`DIR.*`), `moving`, `running`, `sliding`, `freeze`

**Seguimento** — `follow`, `follow_target` (default `get_leader()`), `chaser`, `chasing`

**Sprites** — `s_auto`, `s_state`, `s_prefix`, `s_override`, `s_dynamic`, `s_hurt`, `s_ball`, `s_landed`, `s_slide`, `s_walk_ispd`, `s_run_ispd`, `s_drawer`, `s_get_middle_y()`

**Efeitos visuais** — `trail` (afterimage), `flashing`, `flash_color`, `darken`, `dim`, `sweat`, `shake`, `xoff`, `yoff`, `override_blend`

**Profundidade** — `autoheight`, `myheight`, `depth_override`, `pos`

**Iluminação** — `lighting_highlight_enabled`, `lighting_darken_enabled`, `lighting_shadow_enabled`, `lb_dl_highlight_color`

**Reflexo** — `can_reflect`, `reflection_code`

**Interação** — `interaction_code`, `interaction_args`, `interactable_instances`

**Som** — `stepsounds`, `stepsoundprefix` (`"snd_step"`)

**Métodos internos** — `__initialize()`, `__step(index)`, `__new_record()`, `__refresh_follow(_pos)`

### API de atores — `scripts/actors_scr/actors_scr.gml`

```gml
actor_create(obj, xx = 0, yy = 0, ddepth = 0)
actor_find(obj, xx = x, yy = y, snap = 10, require = {})
actor_move(_actor, movement)
actor_angletodir(angle)

new actor_movement(_x, _y, _time, _seed = "", _spd, _char_dir, _absolute = true, _play_sfx = true)
new actor_movement_jump(_x, _y, _absolute = true, _time = 15, _play_sfx = true)
new actor_movement_jump_into(_x, _y, _absolute = true, _time = 15, _play_sfx = true)
```

`_absolute = false` faz o movimento ser relativo à posição atual.

### API de party

```gml
// composição
global.party_names = ["kris", "susie", "ralsei"]   // o array manda
global.party_limit = 3                             // undefined = ilimitado

// consulta — scripts/party_get/party_get.gml
get_leader()                          // instância do líder
party_get_inst(name)                  // instância de um membro
party_get_obj(name)                   // objeto (asset) do membro
party_get_struct(name) / party_nametostruct(name)
party_getdata(name, value)
party_getname(name, full = true)
party_get_index(name)
party_contains(_name, _full_party = false)
party_length(full = false)
party_isup(name)
party_get_will_down(name, hp_change) / party_get_will_up(name, hp_change)
party_get_icon(name) / party_get_icon_hurt(name) / party_get_icon_ow(name)
party_getbattleheight(name) / party_getpossiblecount()

// mutação — scripts/party_set/party_set.gml e party_scripts.gml
party_setdata(name, hash, value)
party_adddata(name, hash, value) / party_subtractdata(name, hash, value)
party_setfollow(follow)
party_member_add(name, _x, _y, _recalculate_positions = true)
party_member_kick(name)
party_leader_create(name, xx, yy, ddepth)
party_member_create(name, recordnow = true, xx, yy)
party_leader_warp(target_marker_type, target_marker_id, warp_dir = DIR.DOWN)
party_member_interpolate(name) / party_reposition(lx, ly)
party_set_state(_name, _state)     // troca o conjunto de sprites (ex. "serious")
party_fade_out(time = 10) / party_fade_in(time = 10)

// HP — scripts/party_hp/party_hp.gml
party_hpchange(name, heal, caller, sfx, spawn_text)
party_heal(name, heal, caller, sfx)      party_heal_all(heal, caller)
party_hurt(name, hurt, caller, sfx)      party_hurt_all(hurt, caller)
party_attack(name, enemy_attack, caller, element, sfx)
party_attack_all(att, caller, element, enemy_index)
party_hurt_targets(hurt, caller) / party_attack_targets(att, caller, element)
party_check_gameover()
damage(attack, party_name, element)
```

### Sprites por convenção de nome

```gml
party_get_sprite_from_scheme(name, identifier, prefix = "", state = "",
                             scheme = "spr_{0}_{1}_{2}",
                             optional_arguments = [], fallback = spr_default)
party_get_cardinal(name, prefix, state, scheme, optional_arguments, fallback)
party_m_get_cardinal(party_name, world = global.world)
party_m_get_sprite(party_name, identifier, world = global.world)
```

O padrão é `spr_{personagem}_{identificador}_{estado}`, com `spr_default` como fallback. É por isso que `party_set_state("susie", "serious")` troca o conjunto inteiro de sprites dela sem nenhum `switch`. **Ao criar um personagem seu, siga essa nomenclatura e ele funciona de graça.**

### Constantes de direção

```gml
enum DIR { UP = 0, RIGHT = 90, DOWN = 180, LEFT = 270 }   // são ângulos
```

---

## 10. Itens e inventário

Base: `scripts/item/item.gml`. Exemplos do usuário: `scripts/ex_items/ex_items.gml`.

### Enums

```gml
enum ITEM_TYPE { CONSUMABLE, KEY, WEAPON, ARMOR, SPELL, STORAGE, LIGHT }
enum ITEM_USE  { INDIVIDUAL, EVERYONE, ENEMY }
enum ITEM_DESC_TYPE { FULL = 0, SHORTENED = 1, ... }
```

### Campos de `item()`

```gml
name        // ["curto", "longo"] — cada um pode ser callable
desc        // [overworld, batalha, ação, loja]
type        // ITEM_TYPE.*
tp_cost     // custo de TP
color
icon        // sprite do ícone no menu

lw_counterpart / dw_counterpart   // versão do item no outro mundo

use_type    // ITEM_USE.*
can_use     // bool ou função
throw_scripts = { can, execute_code }

stats = { attack, defense, magic, element_resistance: {} }
stats_misc = {}                   // ex. money_modifier
reactions = { susie: "...", ralsei: "..." }   // fala ao usar; entradas podem ser callable
apply(party_name) / deapply(party_name)       // ao equipar/desequipar
unequipped(new_item_index, target_index)

effect      // { sprite, text }
perform_act_anim

use_instant(item_index, target_index)
use_instant_cancel(item_index, target_index)
use_encounter_text = "item_use"   // chave de localização; {0}=personagem {1}=item
use(item_index, target_index, caller = -1)
use_args = []

buy_price       // pode ser callable
sell_price      // se undefined, metade do buy_price
shop_in_stock   // infinity, ou um número = quantidade disponível
can_sell
```

### Funções de inventário

```gml
item_add(item_struct, type)          item_delete(item_slot, type)
item_set(item_struct, index, type)   item_get_array(type)
item_get_count(type)                 item_get_maxcount(type)
item_contains(_item_ref, _item_type) item_count(_item_ref)
item_use(item_struct, item_index, target)
item_spell_use(spell_struct, spell_user, target)
item_get_name(s)                     item_get_desc(s, desc_type)
item_get_buy_price(s)                item_get_sell_price(s)
item_get_can_sell(s)                 item_get_in_stock(s)
item_get_type(s)                     item_get_type_name(type, key_display)
item_get_stat(s, stat)               item_get_fatal(s)
item_get_equipped(_item_ref, _party_name)
item_spell_get_exists / _get_struct / _get_index / item_spell_reload
item_apply(item_struct, party_name)  item_deapply(item_struct, party_name)
item_menu_reaction(item_struct, user) item_menu_party_react(name, reaction)
item_localize("prefixo")             // puxa nome e descrições do JSON de loc
```

Arrays globais: `global.items`, `global.key_items`, `global.weapons`, `global.armors`, `global.storage` (com `global.storage_pages`), `global.lw_items`, `global.lw_weapon`, `global.lw_armor`.

---

## 11. Encontros (batalha)

Scripts: `enc_enemies`, `enc_sets`, `enc_actions`, `enc_buttons`, `enc_scripts`, `enc_setup`, `enc_scene_defaults`, `enc_enemies_recruits`.
Objetos: `o_enc*` (14), `o_turn*`, `o_dodge*`, bullets e UI de batalha.

### `enemy()` — `scripts/enc_enemies/enc_enemies.gml`

```gml
name, obj                                  // obj = objeto do ator inimigo (o_actor_e...)
hp, max_hp, attack, defense, element, status_effect, carrying_money

// MERCY
mercy, mercy_add_pity_percent, can_spare, no_mercy_text
tired, low_hp_tired, low_hp_tired_threshold

// ACTs
acts = [ {
    name, desc, party: [], tp_cost, color, enabled,
    perform_act_anim, return_to_idle_sprites,
    exec: function(enemy_slot, user_index) { ... }, exec_args
} ]
acts_special = {}, acts_special_desc

// diálogo do inimigo
dialogue                                   // string ou função(slot)
dia_bubble_off_x, dia_bubble_off_y, dia_bubble_off_type
dia_bubble_sprites

turn_object                                // o_turn_default — o padrão de balas do turno

// sprites
s_idle, s_spare, s_hurt

// misc
freezable, defeat_marker, run_away, hurt_sound

// hooks de combate
ev_init          // 1 frame depois de o_enc existir
ev_pre_dialogue, ev_dialogue
ev_turn_start, ev_turn, ev_post_turn
ev_party_exec, ev_hurt, ev_win

recruit = new enemy_recruit()
```

### `enc_set()` — o encontro

```gml
function ex_enc_set_shadowguys() : enc_set() constructor {
    debug_name = "shadowguys"
    enemies = [ new ex_enemy_shadowguy(), new ex_enemy_shadowguy() ]

    flavor = function() {                  // string OU função
        if o_enc.turn_count == 0
            return "* Shadowguys play on in."
        return choose("* Shadowguy plays the blues, blues, blues.",
                      "* Shadowguy snaps their fingers rhythmically.")
    }

    enemies_pos = [ [-4, -6, true], [-14, 6, true] ]   // ou função(i, xx, yy)
    bgm = mus_ex_spawn
    bgm_pitch = 1
    bgm_gain = 1
}
```

### Funções de batalha

```gml
enc_start(set)
enc_setup()                       // chamada antes de o_enc ser criado — ponto de customização
enc_hurt_enemy(target, hurt, user, sfx, fatal, seed)
enc_enemy_add_spare(target, percent, sfx)
enc_enemy_add_spare_from_var(target, instance, variable, sfx)
enc_enemy_set_tired(enemy_index, _tired)
enc_enemy_is_fighting(target)     enc_enemy_count(only_alive)
enc_enemy_is_recruitable(ref_or_struct)
enc_set_contains_enemy(set_or_ref, enemy_ref)
enc_set_count_enemy(set_or_ref, enemy_ref)
enc_get_flavor(data)              enc_count_fighting_enemies()
enc_getparty_sprite(party_name, sprname)
enc_party_set_battle_sprite(party_name, sprite_ref, index, speed)
enc_item_get_enabled(item_struct)
enc_calculate_target(encounter)   enc_recalculate_condition(encounter, current_targets)
enc_gameover()                    tp_clamp(tp)
```

### Profundidades de batalha

```gml
enum DEPTH_ENCOUNTER {
    BACKGROUND = -6000, ACTORS = -6100, BULLETS_INSIDE = -6200,
    BOX = -6300, SOUL = -6400, BULLETS_OUTSIDE = -6500, UI = -7000
}
enum DEPTH_UI {
    FADER = -2000, DIALOGUE_UI = -3000, MENU_UI = -3800,
    HIGHEST = -8000, CONSOLE = -15000
}
```

---

## 12. Lojas

`scripts/shops/shops.gml`, `shop_options`, `shop_scripts`. Exemplo: `ex_shop`. Room: `room_shop`.

```gml
shopkeeper, shopkeeper_x = 160, shopkeeper_y = 120
flavor                          // string ou callable
flavor_prefix                   // usado para links e vozes
bgm, bgm_pitch, bgm_gain
return_room, return_marker_id, return_direction
options = [ ... ]               // itens à venda e opções de menu
start = method(self, function() { ... })
```

Ao entrar numa loja, a engine guarda `return_room` / `return_marker_id` para devolver o jogador ao lugar certo. Dados persistentes da loja vão na save entry `SHOP_DATA`.

---

## 13. Save e memories

Dois sistemas distintos e fáceis de confundir.

### 13.1 Save entries — o estado do jogo

`scripts/save/save.gml`, `save_entries.gml`, `save_settings.gml`.

```gml
save_entry(_name, _default_value, _import_method, _extract_method,
           _target_recording = global.save_recording, _target_struct = global.save)
```

- `_import_method(_raw)` — o que fazer ao **carregar**
- `_extract_method()` — o que devolver ao **salvar**
- se ambos forem `undefined`, o valor é guardado direto no struct de save

```gml
save_entry("MONEY", 12800)
save_entry("CHAPTER", global.chapter,
    function(_d) { global.chapter = _d },
    function()   { return global.chapter })
```

**Todas as entries do jogo estão em `objects/o_world/Other_2.gml`**, com um marcador de onde adicionar as suas.

Entries existentes: `NAME`, `ROOM`, `ROOM_NAME`, `TIME`, `CHAPTER`, `PLOT`, `MONEY`, `EXP`, `CRYSTAL`, `COMPLETED`, `COMPLETE_ROOM`, `COMPLETE_TIME`, `LW_NAME`, `LW_LV`, `LW_HP`, `LW_MAXHP`, `LW_MONEY`, `LW_SINCE_CHAPTER`, `LW_WEAPON`, `LW_ARMOR`, `LW_ITEMS`, `ITEMS`, `KEY_ITEMS`, `WEAPONS`, `ARMORS`, `STORAGE`, `SHOP_DATA`, `MEMORIES`, `WORLD`, `RECRUITS`, `RECRUITS_LOST`, `PARTY_DATA`, `PARTY_NAMES`.

Configurações (struct separado `global.settings`): `SAVE_SLOT`, `VOLUME_SFX`, `VOLUME_BGM`, `VOLUME_MASTER`, `SIMPLIFY_VFX`, `AUTO_RUN`, `CONTROLS_KEY`, `CONTROLS_GP`, `LANG`, `VERSION_SAVED`, `BORDER_MODE`.

**API:**

```gml
save_init()                              save_get(_entry_name, _failsafe)
save_set(_entry_name, _value)            save_exists(_slot, _chapter)
save_read(_slot, _chapter)               save_read_all(chapter)
save_load(_slot, _chapter, _data, _to_default_values)
save_export(_data)                       save_export_to_file(_slot, _chapter, _save_data)
save_delete(_slot, _chapter)             save_reload(_chapter)
save_to_string(_d) / save_from_string(_s)
save_wipe()
save_entry_get_default(n) / save_entry_set_default(n, v) / save_entry_reset_default(n)
save_settings_init / _get / _set / _exist / _read / _load / _export / _export_to_file
```

**Onde a room inicial de um jogo novo é definida:** `save_entry("ROOM", room_test_main, ...)` em `objects/o_world/Other_2.gml`. O `o_ui_save_select` faz `room_goto(save_get("room"))`. O `o_ui_chapter_select` sobrescreve com `save_entry_set_default("ROOM", room_ex_dforest / room_ex_city / room_test_main / room_ex_church)` por capítulo.

### 13.2 Memories — "isso já aconteceu?"

`scripts/memories/memories.gml`. Dicionário `categoria → identificador → valor`, salvo junto com o jogo em `global.memories`.

```gml
memory_get(_category, _identificator)
memory_set(_category, _identificator, _value, _locked = false)
memory_flick(_category, _identificator, _locked = false)   // alterna e devolve o novo valor
```

O identificador costuma ser o `id` da instância (estável para instâncias do room editor). Categorias usadas pela engine: `"cutscenes"`, `"boxes"`.

```gml
if memory_get("cutscenes", id) {
    instance_destroy()
    exit
}
```

---

## 14. Localização

`scripts/loc/loc.gml`. Arquivos em `datafiles/loc/*.json`, um por assunto:
`text.json`, `menu.json`, `items.json`, `items_consumables.json`, `items_weapons.json`, `items_spells.json`, `party.json`, `damage.json`, `save_menu.json`, `save_select.json`, `naming_menu.json`, `chapter_select.json`, `money_display.json`, `fonts.json`, `examples.json`, `ex_shop.json`, `ex_items.json`.

```json
{
    "ex_spell_revivekris":      { "en": "ReviveKris",  "ja": "" },
    "ex_spell_revivekris_desc": { "en": "Revive\nKris", "ja": "" }
}
```

```gml
loc(loc_id)                                   // texto no idioma atual
loc_string(loc_id, r0, r1, r2, r3, r4)        // com interpolação
loc_exists(loc_id)                            loc_sprite(loc_id)
loc_font(loc_id)                              loc_load(lang)
loc_getlang()                                 loc_switch_lang(lang, load_save)
item_localize("prefixo")                      // nome + descrições de um item
```

Idiomas presentes: `en`, `ja`. Você pode ignorar tudo isso e usar strings literais — mas se o jogo for ganhar tradução, começar já com `loc()` sai muito mais barato.

---

## 15. Subsistemas menores

### Música — `scripts/music/music.gml`, `o_dev_musiccontrol` (4 canais)

```gml
music_play(_sound, _slot, _loop = true, _gain = 1, _pitch = 1)
music_stop(slot)          music_stop_all()
music_pause(slot)         music_resume(slot)
music_fade(slot, target_gain, time = 30)     music_fade_all(target_gain, time = 30)
music_isplaying(slot)     music_getplaying(slot)     music_getplaying_id(slot)
music_slot_reset(_slot)   music_slot_reset_all()     music_update()
```

Na room, o mais prático é o `o_dev_music` com as Variable Definitions `mus / slot / pitch / gain / loop`.

### Escalada — `scripts/climb/climb.gml`

```gml
climb_start_nearest()   climb_stop_nearest()   climb_check()   climb_get_enabled()
```

Controlado por `global.climbing_enabled`, que por padrão é uma função: `item_contains(item_key_claimbclaws)`. Objetos: `o_dev_climb_tile`, `_auto`, `_catcher`, `_interact`, `_controller`, `o_dev_marker_climb`. Room: `room_test_climbing`.

### Dodge no overworld — `scripts/dodge/dodge.gml`

A alma (soul) fora da batalha. `dodge_on()`, `dodge_off()`, `dodge_darken_self(drawer)`, `dodge_getalpha()`, `dodge_gameover()`. Objetos `o_dodge_soul`, `o_dodge_bullet`, `o_dodge_controller`. `global.ow_dodge_inv = 40` são os frames de invencibilidade.

### Iluminação — `scripts/lighting/lighting.gml`

`lighting_on(color, fade_color = c_gray)`, `lighting_off()`, `lighting_darken_self(drawer)`. `global.current_light` guarda a cor atual. Biblioteca avançada em `@Libraries/dark_lighting_ch4` (room `room_lb_dark_lighting`).

### Bordas de tela — `scripts/borders/borders.gml`

```gml
function border() constructor
function border_none()   : border() constructor
function border_simple() : border() constructor

borders_toggle(borders_on)
border_set(_border, _force = false, _animation_length = 30)
borders_window_resize(borders_on, window_scale, border_scale)
```

`global.border_mode` (`BORDER_MODE.OFF` etc.) é uma configuração persistente. Exemplos em `ex_borders`; na room, `o_dev_border` com `_border_name`.

### Câmera e efeitos — `scripts/custom/custom.gml`

```gml
guipos_x() / guipos_y()
onscreen(instance, tolerance, percise_collisions)
screen_shake(pow, timelen)
camera_pan(x_dest, y_dest, time, ease_type, ...)   camera_unpan(target, time)
```

### Utilidades — `scripts/misc/misc.gml`

```gml
string_to_color(s) / color_to_string(c) / dir_to_string(dir, capitalize)
world_switch(world)                       // troca Dark ↔ Light World
convert_leader_equipment()
draw_sprite_tiled_area(...)               draw_sprite_part_parallax(...)
draw_scrollbar(...)                       draw_text_scale(...)
draw_text_transformed_shadow(...)         draw_pixel(...) / draw_pixel_center(...)
input_verb_get_name(_verb)
```

### Recrutas — `scripts/recruits/recruits.gml`

`global.recruits` e `global.recruits_lost`; `enemy_recruit()` no struct do inimigo.

---

## 16. Console de debug

Objeto `o_console`. Ligado por padrão (`global.console_enabled = true` em `o_world`).

**Abrir: tecla `TAB`.** Digite `help` para listar.

| Comando | Efeito |
|---|---|
| `help` | lista os comandos registrados |
| `room_select` | teleporta para qualquer room |
| `party_select` | monta o grupo com quem quiser |
| `encounter_select` | inicia qualquer encontro imediatamente |
| `encounter_end` | encerra a batalha atual |
| `language_switch` | troca de idioma (volta ao último save) |
| `save_wipe` | apaga todos os saves e configurações |

Registrados em `objects/o_console/Create_0.gml` como array de structs `{ name, desc, execute }` — adicionar comandos próprios é trivial e compensa muito durante o desenvolvimento.

> `global.console = true` significa "console ou menu aberto" e trava o input do jogo. Vários objetos checam essa flag no `Step`.

---

## 17. Convenções de nomenclatura

### Objetos

| Prefixo | Qtd | Significado |
|---|---|---|
| `o_actor_*` | 10 | personagens andantes (party, inimigos) |
| `o_dev_*` | 20 | ferramentas de room editor |
| `o_ow_*` | 13 | overworld (npc, sign, chest, save, porta, parallax) |
| `o_enc_*` | 14 | batalha |
| `o_turn_*` | 3 | padrões de turno inimigo |
| `o_dodge_*` | 3 | esquiva no overworld |
| `o_ui_*` | 12 | menus e interface |
| `o_text_*` | 6 | typer e caixas de texto |
| `o_eff_*` | 25 | efeitos visuais e magias |
| `o_shop_*` | 2 | loja |
| `o_lb_*` | 5 | objetos de bibliotecas |
| `o_ex_*` | 41 | conteúdo de exemplo (apagável) |

Singletons sem prefixo de categoria: `o_world`, `o_camera`, `o_window`, `o_console`, `o_fader`, `o_flash`, `o_gameover`, `o_afterimage`, `o_reflection`, `o_dummy`, `o_block`, `o_block_diag`, `o_trigger`.

### Outros recursos

| Prefixo | Tipo |
|---|---|
| `spr_` | sprite |
| `snd_` | efeito sonoro |
| `mus_` | música |
| `room_` | room |
| `shd_` | shader |
| `item_`, `item_w_`, `item_a_`, `item_key_` | structs de item / arma / armadura / item-chave |
| `enc_set_` | conjunto de encontro |
| `ex_` | conteúdo de exemplo (em qualquer tipo) |
| `lb_` | biblioteca opcional |
| `__` | interno/privado por convenção |

Sprites de personagem seguem `spr_{personagem}_{identificador}_{estado}`.

---

## 18. Variáveis globais

As mais usadas no código (contagem de referências):

| Global | Usos | O que é |
|---|---|---|
| `global.party_names` | 237 | array de strings — composição do grupo |
| `global.chapter` | 36 | capítulo atual (afeta o slot de save) |
| `global.settings` | 29 | struct de configurações persistentes |
| `global.console` | 22 | console/menu aberto → trava o input |
| `global.items` | 20 | inventário de consumíveis |
| `global.world` | 18 | `WORLD_TYPE.DARK` ou `.LIGHT` |
| `global.save_slot` | 17 | slot de save ativo |
| `global.save` | 16 | struct do save carregado |
| `global.memories` | 16 | dicionário de memories |
| `global.border_mode` | 16 | modo de moldura |
| `global.storage` | 15 | armazenamento estendido |
| `global.key_items` | 14 | itens-chave |
| `global.recruits` / `_lost` | 12 / 6 | recrutas |
| `global.current_cutscene` | 12 | cutscene em execução |
| `global.lw_weapon` / `lw_armor` / `lw_items` | 12 / 13 / 10 | equipamento do Light World |
| `global.party` | 11 | struct com os dados de cada membro |
| `global.time` | 10 | tempo de jogo em frames |
| `global.loc_lang` / `loc_source` | 10 | idioma e tabela de textos |
| `global.weapons` / `global.armors` | 6 | equipamentos guardados |
| `global.temp_choice` | 6 | resultado do último `{choice(...)}` |
| `global.menu_page` | 6 | página do menu (resetada a cada room) |
| `global.room_name` | 7 | nome legível da área atual |
| `global.player_moveable_global` | — | trava global de movimento |
| `global.party_limit` | — | máximo de membros (`undefined` = ilimitado) |
| `global.climbing_enabled` | — | função que diz se a escalada está liberada |
| `global.typer_chars` | — | personagens de diálogo registrados |
| `global.simplify_vfx` | — | modo de efeitos reduzidos |
| `global.ow_dodge_inv` | — | frames de invencibilidade no dodge |
| `global.slide_speed` | — | velocidade de deslizar |

---

## 19. Armadilhas conhecidas

### `room_init` tem que ser a primeira room

Ela só contém `o_world`, e o Game Start dele termina com `room_goto_next()`. Para começar em outra sala, coloque-a em **segundo** na room order — nunca tire a `room_init` do topo. Sem `o_world`, todas as globais somem e a room quebra na hora.

### Pasta ≠ ordem das rooms

A árvore do Asset Browser é só organização visual. A ordem de execução vive em `RoomOrderNodes`, dentro do `.yyp`, e se edita na IDE em **Asset Browser → Quick Access → Room Order** (o *Room Manager*). Em português: **Acesso rápido → Ordem dos cenas**.

Se a `room_init` "sumiu" da pasta Rooms, é porque ela está em `@Engine/rooms` e não em `zzz Examples/Rooms`.

Atalhos de teclado do Room Manager (vêm sem tecla atribuída; configuráveis em Preferences → Keybindings → Asset Browser): `Arrange Up One`, `Arrange Down One`, `Arrange To Top`, `Arrange To Bottom`.

### Versão da IDE

Se o `.yyp` foi salvo numa IDE mais nova que a sua, abrir o projeto rebaixa `MetaData.IDEVersion` e pode gerar erros de compilação sem nenhuma relação com o seu código. Confira esse campo antes de caçar bug em GML.

### Instâncias desativadas, não destruídas

Cutscenes encadeiam triggers com `instance_deactivate_object()` / `instance_activate_object()`. Uma instância desativada não roda Step nem aparece em `with()`. Se algo "sumiu", pode estar só desativado.

### `o_world` é persistente

Variáveis de instância dele (`volume_bgm`, `frames`, `window_scale`, `emitter_bgm`) sobrevivem à troca de room — diferente de qualquer outro objeto. Por isso tantos scripts referenciam `o_world.algo` diretamente.

### Quase todo campo aceita função

Antes de escrever lógica em volta de uma struct, cheque se o campo já aceita callable. Normalmente aceita.

### Resolução

Se mudar `GAME_W_GUI` / `GAME_H_GUI`, o comentário no `game_info.gml` avisa: mude também o tamanho da `room_init` para bater.

### Saves incompatíveis

`GAME_LAST_COMPATIBLE_VERSION` controla o aviso de save antigo. Se você mudar as save entries de forma incompatível, suba a versão — senão o jogador toma erro silencioso ou o prompt fatal de wipe.

---

## 20. Roteiro de estudo

Ordem do concreto ao abstrato; cada passo depende do anterior.

1. **Jogue a Test Zone inteira.** É a recomendação do próprio autor em `notes/setup`. Rode o projeto como está (com `room_init` em primeiro) e explore.

2. **Abra o console e teleporte.** `TAB` → `room_select`. Passe por `room_test_movement`, `room_test_inventory`, `room_test_shops`, `room_test_climbing`, `room_test_cutscene`. Cada uma isola um sistema.

3. **Leia uma room com o editor aberto ao lado.** Abra `room_ex_church` no room editor e, em paralelo, os seis `InstanceCreationCode_*.gml` dela. Clique em cada instância e ache o código correspondente.

4. **Faça uma placa falar.** Coloque um `o_ow_sign` numa room e escreva `text = "* Olá."` no Instance Creation Code. Depois brinque com as tags: `{col(y)}`, `{p}`, `{char(...)}`.

5. **Crie um item.** Copie um bloco de `ex_items.gml`, renomeie, mude `use` e `buy_price`. Pegue-o pelo console ou pela loja. É o menor ciclo completo "struct → aparece no jogo".

6. **Escreva uma cutscene curta.** Um `o_trigger` com `cutscene_create()`, dois `cutscene_dialogue()`, um `cutscene_actor_move()` e `cutscene_play()`. Depois adicione a guarda `memory_get("cutscenes", id)` para rodar só uma vez.

7. **Monte um encontro.** Um `enemy()` seu com dois ACTs, um `enc_set()` que o use, e dispare com `encounter_select` no console.

8. **Construa uma room do zero.** Room vazia + `o_dev_playermarker` + `o_dev_world` + `o_dev_music` + `o_block` nas paredes + um `o_dev_marker` de saída. Ligue-a às outras com `party_leader_warp()` ou `o_ow_shortcut_door`.

9. **Só então comece o seu jogo.** Crie arquivos com prefixo próprio (não `ex_`), tire o que não usa de `zzz Examples`, ajuste `GAME_NAME`, `GAME_VERSION` e a room inicial.

---

## 21. Receitas rápidas

### Mudar a room inicial

1. Room Manager: `room_init` em 1º, sua room em 2º.
2. Para saves novos, ajuste também `save_entry("ROOM", <sua_room>, ...)` em `objects/o_world/Other_2.gml`.

### Uma placa que fala

`o_ow_sign` na room; Instance Creation Code:

```gml
text = "{col(y)}* Bem-vindo.{col(w)}{p}{e}"
```

### Um NPC com diálogo condicional

`o_ow_npc` ou `o_ow_interactable`; Instance Creation Code:

```gml
interaction_code = function() {
    cutscene_create()
    if memory_get("npcs", id)
        cutscene_dialogue("{char(gerson, 1)}* De novo você?{p}{e}")
    else {
        cutscene_dialogue("{char(gerson, 0)}* Olá, forasteiro.{p}{e}")
        cutscene_func(memory_set, ["npcs", id, true])
    }
    cutscene_play()
}
```

### Transição entre rooms

`o_trigger` na borda; Instance Creation Code:

```gml
trigger_code = function() {
    room_goto(room_minha_praca)
    // ou, chegando num marcador específico:
    // party_leader_warp(MARKER_LAND, 1, DIR.UP)
}
```

Na room de destino, um `o_dev_marker_land` com o `m_id` correspondente.

### Adicionar um dado ao save

Em `objects/o_world/Other_2.gml`, no bloco marcado:

```gml
save_entry("MEU_FLAG", false)
// ler:    save_get("MEU_FLAG")
// gravar: save_set("MEU_FLAG", true)
```

### Adicionar um comando ao console

Em `objects/o_console/Create_0.gml`, junto dos outros:

```gml
{
    name: "give_money",
    desc: "Adiciona 1000 de dinheiro.",
    execute: function() {
        save_set("MONEY", save_get("MONEY") + 1000)
    }
},
```

### Trocar o grupo

```gml
global.party_names = ["kris", "noelle"]
party_reposition()
```

### Tocar música

```gml
music_play(mus_minha_trilha, 0, true, 1, 1)
music_fade(0, 0, 60)     // fade out do slot 0 em 60 frames
```

---

## 22. Glossário

| Termo | Significado |
|---|---|
| **actor** | personagem andante no overworld (`o_actor` e derivados) |
| **ACT** | ação não-violenta contra um inimigo, no menu de batalha |
| **encounter / enc** | batalha |
| **enc_set** | struct que define um encontro (inimigos, música, flavor, posições) |
| **flavor** | texto que descreve a situação no início de cada turno |
| **MERCY** | barra de piedade; cheia permite poupar o inimigo |
| **TIRED** | estado do inimigo com HP baixo, mais fácil de poupar |
| **TP** | recurso de magia, ganho ao esquivar de perto |
| **soul** | o coração controlado pelo jogador na fase de defesa |
| **box** | a caixa onde a soul se move durante a defesa |
| **bullet** | projétil do turno inimigo |
| **turn_object** | objeto que roda o padrão de balas de um inimigo |
| **overworld / ow** | fase de exploração, fora da batalha |
| **Dark World / Light World** | os dois mundos (`WORLD_TYPE.DARK` / `.LIGHT`) |
| **marker** | ponto nomeado numa room (`o_dev_marker`) |
| **memory** | flag persistente "isso já aconteceu" |
| **save entry** | dado registrado no sistema de save |
| **typer** | o objeto que digita o texto letra a letra (`o_text_typer`) |
| **typer char** | personagem registrado para uso em `{char(...)}` |
| **recruit** | inimigo que pode ser recrutado ao ser poupado |
| **border** | moldura decorativa em volta da tela |
| **dodge** | esquiva com a soul fora da batalha |
| **climb** | sistema de escalada |
| **slot** (música) | um dos 4 canais de áudio de `o_dev_musiccontrol` |
| **slot** (save) | posição do arquivo de save |

---

*Documento gerado por leitura do código-fonte da tlDR Engine v2.2.1.
Para dúvidas sobre a engine em si, consulte a documentação oficial e o Discord (seção 1).
Para dúvidas sobre GameMaker, consulte a documentação oficial do GMS2 — esta engine usa GML moderno
(structs, constructors, methods) e muito tutorial antigo ensina padrões que ela abandonou.*
