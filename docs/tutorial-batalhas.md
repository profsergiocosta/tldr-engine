# Tutorial: como criar batalhas na tlDR Engine

> Companheiro de [`tldr-engine-guia.md`](tldr-engine-guia.md). Aqui o foco é uma tarefa só: sair do zero até uma batalha jogável, e depois entender cada peça.
>
> Todo o código deste tutorial usa **assets que já existem no projeto** — você consegue rodar uma batalha hoje, sem desenhar nada.

---

## Índice

1. [Antes de tudo: entendendo o erro "not defined"](#1-antes-de-tudo-entendendo-o-erro-not-defined)
2. [As quatro peças de uma batalha](#2-as-quatro-peças-de-uma-batalha)
3. [Passo 1 — O ator (o corpo do inimigo)](#3-passo-1--o-ator-o-corpo-do-inimigo)
4. [Passo 2 — O struct `enemy()` (a ficha do inimigo)](#4-passo-2--o-struct-enemy-a-ficha-do-inimigo)
5. [Passo 3 — Os ACTs](#5-passo-3--os-acts)
6. [Passo 4 — O `enc_set()` (o encontro)](#6-passo-4--o-enc_set-o-encontro)
7. [Passo 5 — Testar](#7-passo-5--testar)
8. [Passo 6 — Disparar a batalha no overworld](#8-passo-6--disparar-a-batalha-no-overworld)
9. [Passo 7 — Turnos e balas](#9-passo-7--turnos-e-balas)
10. [Referência rápida](#10-referência-rápida)
11. [Erros comuns](#11-erros-comuns)

---

## 1. Antes de tudo: entendendo o erro "not defined"

Em GML, um identificador solto que não é variável local é resolvido em **tempo de compilação como nome de asset**. Então:

```gml
s_idle = spr_ballet_bg
```

Se não existir um sprite chamado exatamente `spr_ballet_bg` no projeto, o compilador não tem o que resolver e para com **`spr_ballet_bg not defined`**.

**Isso não é um erro na sua função.** É um asset que não existe. Três causas possíveis:

| Causa | Como confirmar |
|---|---|
| O sprite nunca foi criado | procure o nome no Asset Browser |
| O nome está diferente (typo, prefixo errado) | compare com o nome real do asset |
| O sprite foi apagado mas o código ficou | busque o nome no projeto inteiro |

> **Como conferir rápido:** no Asset Browser, digite o nome na busca. Se não aparecer nada, o asset não existe — não adianta mexer no GML.

### O mesmo erro está no seu arquivo agora

Em `scripts/rpg_enc_enemies/rpg_enc_enemies.gml` há quatro referências a assets inexistentes:

| No seu código | Existe? | Nome real no projeto |
|---|---|---|
| `o_actor_e_shadowguy` | ❌ | `o_ex_actor_e_sguy` |
| `spr_ex_enemy_shadowguy_idle` | ❌ | `spr_ex_e_sguy_idle` |
| `spr_ex_enemy_shadowguy_spare` | ❌ | `spr_ex_e_sguy_spare` |
| `spr_ex_enemy_shadowguy_hurt` | ❌ | `spr_ex_e_sguy_hurt` |

A convenção da engine para inimigos de exemplo é `spr_ex_e_<nome>_<estado>` — bem mais curta do que parece à primeira vista.

### E os erros da versão anterior (o Slime)

Aquela função tinha cinco problemas além do sprite. Todos silenciosos — nenhum gera erro de compilação, o que é pior:

| Você escreveu | Problema | Correto |
|---|---|---|
| `maxhp = 100` | cria um campo **novo**; o `max_hp` da base continua 170, e a barra de HP fica errada | `max_hp = 100` |
| `flavor = "..."` | `flavor` não pertence a `enemy()`, e sim a `enc_set()` — é o texto do **encontro**, não do inimigo | mover para o `enc_set()` |
| `func: function() {...}` | a engine lê `exec`, não `func` — o ACT aparece no menu e não faz nada | `exec: function(slot, user) {...}` |
| `add_mercy(100)` | função não existe | `enc_enemy_add_spare(slot, 100)` |
| `dialogue_start(...)` | é a caixa de diálogo do **overworld**; dentro da batalha ela abre no lugar errado | `encounter_scene_dialogue(...)` |

Faltava também o `obj` (o objeto ator do inimigo) e os sprites `s_idle` / `s_hurt` / `s_spare`.

> Este é o motivo de o item "quase todo campo aceita função" do guia vir acompanhado de um aviso: como structs em GML aceitam qualquer campo novo sem reclamar, **errar o nome de um campo nunca dá erro** — só deixa de funcionar. Ao criar conteúdo, copie sempre de um exemplo que funciona, em vez de escrever de memória.

---

## 2. As quatro peças de uma batalha

```
enc_set()          o ENCONTRO   — quem luta, música, fundo, texto de rodada
   └── enemy()     a FICHA      — HP, ATK, ACTs, diálogo, sprites
         ├── obj          o ATOR   — o objeto que aparece na tela (herda de o_actor_e)
         └── turn_object  o TURNO  — o objeto que dispara as balas na sua vez de defender
```

- Você **sempre** precisa das quatro, mas três delas têm um padrão utilizável pronto:
  - ator → `o_actor_e` (a própria base já funciona)
  - turno → `o_turn_default` (uma bala simples)
  - encontro → você escreve, é curto

Arquivos onde escrever (já existem no seu projeto):

| Arquivo | Conteúdo |
|---|---|
| `scripts/rpg_enc_enemies/rpg_enc_enemies.gml` | seus `enemy()` |
| `scripts/rpg_enc_sets/rpg_enc_sets.gml` | seus `enc_set()` |

Referência de exemplos que funcionam: `scripts/ex_enc_enemies/ex_enc_enemies.gml` e `scripts/ex_enc_sets/ex_enc_sets.gml`.

---

## 3. Passo 1 — O ator (o corpo do inimigo)

O ator é o objeto que fica na tela durante a batalha. Ele herda de **`o_actor_e`**, que por sua vez herda de `o_actor`.

### Opção A — sem criar nada (comece por aqui)

`o_actor_e` já é utilizável. É o default do `enemy()`. Para o seu primeiro inimigo, **não crie objeto nenhum** e use os sprites do virovirokun, que estão no núcleo da engine:

```gml
obj    = o_actor_e
s_idle = spr_e_virovirokun_idle
s_hurt = spr_e_virovirokun_hurt
s_spare= spr_e_virovirokun_spare
```

### Opção B — criar o seu

Quando quiser sprites próprios ou comportamento especial:

1. Asset Browser → botão direito na sua pasta de objetos → **Create → Object**
2. Nome: `o_rpg_actor_e_slime`
3. **Parent**: `o_actor_e` ← isso é obrigatório
4. **Sprite**: o sprite idle do inimigo
5. No `Create`, a primeira linha tem que ser `event_inherited()`

```gml
// objects/o_rpg_actor_e_slime/Create_0.gml
event_inherited()

s_intro = spr_rpg_e_slime_hurt   // sprite da animação de entrada na batalha
```

O que `o_actor_e` traz de graça: `is_enemy = true`, animação de entrada (`s_intro`), perseguição no overworld (`chase_spd`, `chase_zone`, `chase_dist`), caminho de patrulha (`idle_path`) e o gancho `encounter` que inicia a batalha ao encostar no jogador.

Se quiser desenho customizado (arma na mão, partes extras), sobrescreva `s_drawer` — veja `o_ex_actor_e_sguy` como referência.

---

## 4. Passo 2 — O struct `enemy()` (a ficha do inimigo)

Escreva em `scripts/rpg_enc_enemies/rpg_enc_enemies.gml`.

### O Slime, versão que compila e roda

```gml
function rpg_enemy_slime() : enemy() constructor {
    name = "Slime"
    obj  = o_actor_e                    // ator; troque pelo seu quando tiver

    // stats — atenção ao underline em max_hp
    hp      = 100
    max_hp  = 100
    attack  = 6
    defense = 0

    // MERCY
    mercy      = 0
    can_spare  = true

    // sprites
    s_idle  = spr_e_virovirokun_idle
    s_hurt  = spr_e_virovirokun_hurt
    s_spare = spr_e_virovirokun_spare

    // fala do inimigo no balão, a cada rodada
    dialogue = "* Blub..."

    // padrão de balas do turno
    turn_object = o_turn_default

    acts = [
        {
            name: "Checar",
            desc: "Analisa o inimigo",
            party: [],
            exec: function(slot, user) {
                encounter_scene_dialogue("* SLIME - ATK 6 DEF 0{br}{resetx}* Parece inofensivo.")
            }
        },
        {
            name: "Acariciar",
            desc: "Faz carinho",
            party: [],
            exec: function(slot, user) {
                enc_enemy_add_spare(slot, 100)          // enche a MERCY
                encounter_scene_dialogue("* Você fez carinho no Slime.{br}{resetx}* Ele gostou bastante!")
            }
        }
    ]
}
```

### Campos principais de `enemy()`

Base completa em `scripts/enc_enemies/enc_enemies.gml`.

| Campo | Default | O que é |
|---|---|---|
| `name` | `"Test"` | nome exibido |
| `obj` | `o_actor_e` | objeto ator |
| `hp` / `max_hp` | 170 | vida |
| `attack` / `defense` | 0 / 0 | stats |
| `element` | `undefined` | elemento do ataque |
| `carrying_money` | 0 | dinheiro dropado |
| `status_effect` | `""` | efeito de status |
| `mercy` | 0 | MERCY inicial (0–100) |
| `can_spare` | `true` | pode ser poupado |
| `no_mercy_text` | — | texto ao tentar poupar sem MERCY |
| `mercy_add_pity_percent` | 20 | MERCY de consolo |
| `tired` | `false` | estado cansado |
| `low_hp_tired` | `true` | fica TIRED com HP baixo |
| `low_hp_tired_threshold` | `1/2` | limiar de HP para TIRED |
| `acts` | Check | array de ACTs |
| `acts_special` | `{}` | ACTs exclusivos por personagem |
| `dialogue` | `"Test"` | fala do balão; string ou `function(slot)` |
| `dia_bubble_off_x` / `_off_y` / `_off_type` | 0 | posição do balão |
| `turn_object` | `o_turn_default` | padrão de balas |
| `s_idle` / `s_hurt` / `s_spare` | virovirokun | sprites |
| `freezable` | `false` | pode ser congelado |
| `defeat_marker` | 0 | `m_id` do marcador onde cai ao ser derrotado |
| `run_away` | `true` | foge ao levar dano fatal; `false` = morre |
| `hurt_sound` | `snd_hurt` | som de dano |
| `recruit` | `new enemy_recruit()` | dados de recrutamento |

**Hooks de combate** (todos default `-1` = desligado):

```gml
ev_init          // 1 frame depois de o_enc existir
ev_pre_dialogue  ev_dialogue
ev_turn_start    ev_turn      ev_post_turn
ev_party_exec    ev_hurt      ev_win
```

Exemplo real, do Shadowguy:

```gml
ev_post_turn = function() {
    instance_destroy(o_ex_enc_m_boogie_controller)
}
```

---

## 5. Passo 3 — Os ACTs

O array `acts` monta o submenu ACT. Cada entrada é um struct.

```gml
{
    name: "Acariciar",            // texto no menu
    desc: "Faz carinho",          // descrição na caixa lateral
    party: [],                    // quem pode usar — ver tabela abaixo
    tp_cost: 0,                   // custo de TP (opcional, 0 por padrão)
    color: c_white,               // cor no menu; pode ser callable
    enabled: true,                // bool ou função — controla se aparece habilitado
    perform_act_anim: true,       // toca a animação padrão de ACT
    return_to_idle_sprites: true, // volta os sprites ao idle depois

    exec: function(slot, user) { ... },
    exec_args: []                 // argumentos extras, entregues depois de (slot, user)
}
```

### O campo `party`

| Valor | Significado |
|---|---|
| `[]` | qualquer membro pode usar |
| `["susie"]` | só a Susie |
| `["susie", "ralsei"]` | ACT conjunto: exige que **ambos** estejam no grupo, e mostra os dois ícones |
| `-1` | ACT de grupo inteiro |

Se você listar um personagem que não está no grupo, o ACT simplesmente não aparece — a engine checa com `party_contains()`.

### A assinatura de `exec`

```gml
exec: function(slot, user) { ... }
```

- `slot` — índice do inimigo dentro de `o_enc.encounter_data.enemies`
- `user` — **nome** (string) de quem usou o ACT, ex. `"susie"`
- argumentos seguintes vêm de `exec_args`, na ordem

```gml
// passando dados extras
exec: function(slot, user, sprites) {
    var me = o_enc.encounter_data.enemies[slot]
    ...
},
exec_args: [boogie_sprites]
```

### Texto dentro de um ACT

Use **`encounter_scene_dialogue(texto)`**, não `dialogue_start()`. As tags de markup (seção 8 do guia) funcionam normalmente:

```gml
encounter_scene_dialogue("* SLIME - ATK 6 DEF 0{br}{resetx}* Parece inofensivo.")
```

`{br}{resetx}` é o par que a engine usa para quebrar linha e voltar a margem à esquerda — repare que aparece em todos os exemplos.

### ACT com cutscene (para efeitos elaborados)

Quando o ACT precisa animar algo, abra uma cutscene e **pause a batalha** com `cutscene_enc_wait`:

```gml
exec: function(slot, user) {
    cutscene_create()
    cutscene_enc_wait(true)        // trava a batalha

    cutscene_func(enc_enemy_add_spare, [slot, 5])
    cutscene_dialogue("* " + party_getname(user) + " dança entre as balas!")
    cutscene_set_partysprite(user, "idle")

    cutscene_enc_wait(false)       // devolve o controle à batalha
    cutscene_play()
}
```

### Funções úteis dentro de um ACT

```gml
enc_enemy_add_spare(slot, percent, sfx)        // adiciona MERCY
enc_enemy_add_spare_from_var(slot, inst, var)  // MERCY proporcional a uma variável
enc_enemy_set_tired(slot, true)                // marca como TIRED
enc_hurt_enemy(slot, dano, user, sfx, fatal)   // causa dano
party_heal(nome, valor, caller)                // cura um membro
o_enc.encounter_data.enemies[slot]             // o struct do inimigo
o_enc.turn_count                               // rodada atual
```

---

## 6. Passo 4 — O `enc_set()` (o encontro)

Escreva em `scripts/rpg_enc_sets/rpg_enc_sets.gml`. **É aqui que mora o `flavor`.**

```gml
function rpg_enc_set_slimes() : enc_set() constructor {
    debug_name = "slimes"            // nome que aparece no console

    enemies = [
        new rpg_enemy_slime(),
        new rpg_enemy_slime(),
    ]

    // texto no começo de cada rodada — string OU função
    flavor = function() {
        if o_enc.turn_count == 0
            return "* Dois Slimes bloqueiam o caminho!"
        return choose(
            "* Slime balança suavemente.",
            "* Slime faz um som molhado.",
            "* Cheiro de gelatina no ar."
        )
    }

    // posições: [x, y, relativo?] por inimigo
    enemies_pos = [
        [-4, -6, true],
        [-14, 6, true],
    ]

    bgm = mus_battle
}
```

### Campos principais de `enc_set()`

Base em `scripts/enc_sets/enc_sets.gml`.

| Campo | Default | O que é |
|---|---|---|
| `debug_name` | `"undefined"` | nome no `encounter_select` do console |
| `enemies` | `[]` | array de instâncias `new ...()` |
| `flavor` | função | texto da rodada; string ou callable |
| `bg_type` | `ENC_BG.GRID` | fundo da batalha — só dois valores: `ENC_BG.GRID` ou `ENC_BG.NONE` |
| `bgm` / `bgm_pitch` / `bgm_gain` | `mus_battle` | trilha |
| `enemies_pos` | `undefined` | `[x, y, relativo]` por inimigo, ou `function(i, xx, yy)` |
| `party_pos` | função | posição de cada membro do grupo |
| `party_actions` | ações padrão | ações extras por personagem |
| `win_condition` | todos derrotados | função que encerra a batalha |
| `can_change_turnlen` | `true` | defender encurta o turno |
| `display_target` | `false` | mostra o alvo do inimigo (estilo capítulo 1) |
| `target_calculation` | `ENC_TARGET.RANDOM` | como o inimigo escolhe alvo |
| `enc_var_struct` | `{}` | variáveis livres do encontro |

Os mesmos hooks (`ev_init`, `ev_turn`, `ev_win`, …) existem também no `enc_set()`, valendo para o encontro inteiro em vez de um inimigo.

### `enemies_pos` como função

Útil quando o número de inimigos varia:

```gml
enemies_pos = function(i, xx, yy) {
    return [ xx - i*10, yy ]
}
```

---

## 7. Passo 5 — Testar

Não construa a sala primeiro. Teste pelo console:

1. Rode o jogo
2. **`TAB`** para abrir o console
3. `encounter_select`
4. Escolha `slimes` (o `debug_name`)

A batalha começa na hora, com o grupo atual. Para testar com outro grupo, use `party_select` antes.

Se o encontro não aparecer na lista, o arquivo não compilou — olhe a janela **Output**.

---

## 8. Passo 6 — Disparar a batalha no overworld

Três formas, da mais simples à mais controlada.

### A. Inimigo andando pelo mapa (o jeito canônico)

`o_actor_e` e derivados têm **Variable Definitions** que você preenche no inspetor da room:

| Variável | Default | Uso |
|---|---|---|
| `encounter` | `new enc_set_ex()` | **o encontro que inicia ao encostar** |
| `enable_chasing` | `true` | persegue o jogador |
| `chase_spd` | 4 | velocidade da perseguição |
| `chase_zone` / `chase_zone_auto` / `chase_dist` | — | área e distância de detecção |
| `idle_path` | — | caminho de patrulha (asset Path) |
| `idle_path_spd` | 1 | velocidade da patrulha |
| `idle_path_autodir` / `idle_path_autopos` | `true` | segue direção/posição do path |
| `sprite_facing_dir` | `DIR.LEFT` | para que lado o sprite olha |
| `can_idle_encounter` | `true` | inicia batalha ao ser tocado parado |

Arraste o ator na room e escreva no campo `encounter`:

```gml
new rpg_enc_set_slimes()
```

### B. Por trigger

`o_trigger` na room; Instance Creation Code:

```gml
trigger_code = function() {
    new rpg_enc_set_slimes()._start()
}
```

### C. Por código, em qualquer lugar

```gml
new rpg_enc_set_slimes()._start()
// ou, com o struct já criado:
enc_start(meu_set)
```

Para o inimigo cair num ponto específico ao ser derrotado, coloque um `o_dev_marker_enemy_defeat` na room e aponte `defeat_marker` para o `m_id` dele.

---

## 9. Passo 7 — Turnos e balas

O `turn_object` é o objeto que roda durante a fase de defesa. Ele **herda de `o_turn`** e se destrói para encerrar o turno.

### Estrutura

| Evento | Arquivo | Função |
|---|---|---|
| Create | `Create_0.gml` | `event_inherited()` + suas variáveis |
| User Event 0 | `Other_10.gml` | **init** — configure `timer_end` aqui |
| User Event 1 | `Other_11.gml` | **turno começa** — crie as balas |
| Step | `Step_0.gml` | lógica por frame |
| Destroy | `Destroy_0.gml` | limpeza |

O `o_turn_default` inteiro é isto:

```gml
// Create_0.gml
event_inherited()
_ex_bullet = noone
timer_end = undefined

// Other_10.gml — init
event_inherited()
__support_init_default()
if !am_support
    timer_end = 60          // duração do turno em frames

// Other_11.gml — turno começa
event_inherited()
_ex_bullet = instance_create(o_enc_bullet, o_enc_box.x, o_enc_box.y - 20,
                             DEPTH_ENCOUNTER.BULLETS_OUTSIDE)

// Step_0.gml
event_inherited()
__support_destroy_check()

// Destroy_0.gml
instance_destroy(_ex_bullet)
```

### Campos de `o_turn`

| Campo | Default | O que é |
|---|---|---|
| `timer` / `timer_end` | 0 / 60 | duração em frames; `undefined` = não termina sozinho |
| `enemy_index` / `enemy_struct` | — | qual inimigo está atacando |
| `pattern` / `pattern_pool` | `[1]` | sorteio de padrões de ataque |
| `assign_unique_patterns` | `true` | evita repetir padrão entre inimigos |
| `buff` / `debuff` | 0 | ajuste de dificuldade |
| `allow_same_turns` | `false` | permite repetir o mesmo turno |
| `shorten_by_tension` | `true` | turno encurta conforme a tensão |
| `am_support` | `false` | turno de apoio — só existe junto com outro |

### Balas

`o_enc_bullet` é a bala base:

```gml
enum BULLET_COLOR { SOLID, BLUE, ORANGE }

graze       = 2      // pontos de graze ao passar perto
att         = 6      // stat de ataque base do dano
inv         = global.enc_soul_inv   // frames de invencibilidade concedidos
time_points = 5      // reduz a duração do turno ao ser grazada
color       = BULLET_COLOR.SOLID
destroy     = true   // some ao acertar
element     = ""
inside      = false  // desenhar dentro da box
```

Criando uma bala com propriedades já definidas:

```gml
instance_create(o_enc_bullet, xx, yy, DEPTH_ENCOUNTER.BULLETS_INSIDE, {
    att: 4,
    color: BULLET_COLOR.BLUE,
    inside: true,
    speed: 3,
    direction: 180
})
```

`global.enc_soul_inv` (padrão 40) é definido em `scripts/enc_setup/enc_setup.gml`, que roda antes de `o_enc` ser criado — é o lugar de configurações globais de batalha.

Exemplos completos de turno: `o_ex_turn_sguy`, `o_ex_turn_dentos`, `o_ex_turn_complex_box`.

---

## 10. Referência rápida

### Arquivos

| O quê | Onde |
|---|---|
| Seus inimigos | `scripts/rpg_enc_enemies/rpg_enc_enemies.gml` |
| Seus encontros | `scripts/rpg_enc_sets/rpg_enc_sets.gml` |
| Base `enemy()` | `scripts/enc_enemies/enc_enemies.gml` |
| Base `enc_set()` | `scripts/enc_sets/enc_sets.gml` |
| Funções de batalha | `scripts/enc_scripts/enc_scripts.gml` |
| Config global de batalha | `scripts/enc_setup/enc_setup.gml` |
| Exemplos que funcionam | `scripts/ex_enc_enemies/`, `scripts/ex_enc_sets/` |

### Assets que já existem (use nos testes)

```gml
// atores
o_actor_e                 // base genérica, funciona sozinha
o_actor_e_virovirokun
o_actor_e_killercar
o_ex_actor_e_sguy         // shadowguy
o_ex_actor_e_spawnling
o_ex_actor_e_dentos

// sprites do núcleo
spr_e_virovirokun_idle / _hurt / _spare
spr_e_killercar / _hurt

// sprites de exemplo
spr_ex_e_sguy_idle / _hurt / _spare
spr_ex_e_spawnling / _hurt
spr_ex_e_dentos / _hurt
spr_ex_e_tasque / _hurt / _spared

// turnos
o_turn_default            // uma bala simples
o_turn_default_dark       // exemplo de inimigo de apoio

// música
mus_battle
```

### Profundidades

```gml
enum DEPTH_ENCOUNTER {
    BACKGROUND = -6000, ACTORS = -6100, BULLETS_INSIDE = -6200,
    BOX = -6300, SOUL = -6400, BULLETS_OUTSIDE = -6500, UI = -7000
}
```

---

## 11. Erros comuns

| Sintoma | Causa provável |
|---|---|
| `<nome> not defined` ao compilar | asset que não existe — confira o nome no Asset Browser |
| Barra de HP errada / inimigo com vida demais | escreveu `maxhp` em vez de `max_hp` |
| ACT aparece no menu mas não faz nada | usou `func:` em vez de `exec:` |
| Texto do ACT abre a caixa do overworld | usou `dialogue_start()` em vez de `encounter_scene_dialogue()` |
| ACT não aparece | `party: [...]` lista alguém fora do grupo |
| Encontro não aparece no `encounter_select` | o arquivo não compilou — veja a janela Output |
| Texto de rodada não muda | pôs `flavor` no `enemy()`; ele pertence ao `enc_set()` |
| Turno nunca acaba | `timer_end = undefined` e nada destrói o objeto de turno |
| Inimigo não inicia batalha ao encostar | Variable Definition `encounter` vazia na instância da room |
| Campo que você escreveu é ignorado | nome do campo errado — structs aceitam qualquer campo sem reclamar |

> A regra que resolve metade desta tabela: **errar o nome de um campo de struct em GML nunca gera erro**. Sempre copie de um exemplo que funciona.

---

*Companheiro de `docs/tldr-engine-guia.md`. Escrito a partir da leitura de
`enc_enemies.gml`, `enc_sets.gml`, `enc_scripts.gml`, `enc_setup.gml`,
`ex_enc_enemies.gml`, `ex_enc_sets.gml`, `o_turn`, `o_turn_default`,
`o_enc_bullet`, `o_actor_e` e `o_ex_actor_e_sguy`.*
