# Tutorial: como funciona uma luta na tlDR Engine

> Guia de dinâmica de combate — a alma, os tiros, a física, o movimento. Complementa [`tldr-engine-guia.md`](tldr-engine-guia.md) e [`tutorial-batalhas.md`](tutorial-batalhas.md). Aqui o foco é **entender o porquê** de cada peça, não só copiar código.
>
> Todos os nomes, campos e comportamentos deste documento foram conferidos linha a linha contra o projeto. Veja o apêndice "Correções aplicadas" no final para o que mudou em relação ao rascunho original.

---

## Parte 1 — A lógica da batalha (sem código nenhum)

Se você nunca jogou Undertale/Deltarune, vale explicar o **conceito** antes da implementação. Isso não é um RPG de turno comum (tipo Pokémon ou Final Fantasy) — é um híbrido de duas coisas que normalmente não se misturam: **menu de turno** + **bullet hell** (jogo de desviar de tiros em tempo real, tipo os "shmups" clássicos de nave).

### 1.1 A ideia central: cada luta é uma conversa, não só uma matança

A diferença mais importante desse gênero pro RPG tradicional é esta: você **quase nunca é obrigado a matar o inimigo**. Toda luta tem dois caminhos possíveis de terminar:

- **Caminho violento**: baixar o HP do inimigo a zero (`Fight`).
- **Caminho pacífico**: convencer o inimigo a desistir de lutar e **poupá-lo** (`Act` + `Spare`).

O jogo é desenhado pra que o caminho pacífico seja **igualmente válido** — às vezes até mais interessante — do que o violento. Isso muda a pergunta que o jogador faz durante a luta: não é só "como eu ganho", é "como eu faço esse inimigo parar de lutar comigo".

É por isso que cada inimigo tem uma **personalidade codificada em ACTs** (seção 1.4). O Dustling que vocês estão criando, por exemplo, não é "derrotado" — ele é **acalmado**.

### 1.2 O menu: os cinco botões

Toda vez que é sua vez de agir, cada membro do grupo recebe uma fileira de **cinco botões** (`objects/o_enc/Create_0.gml:82`):

| Opção | O que faz |
|---|---|
| **FIGHT** | Ataca o inimigo, causando dano de verdade (reduz `hp`) |
| **ACT** *ou* **MAGIC** | O segundo slot é **ACT** se aquele personagem tem o "item" `item_s_act`; senão vira **MAGIC** (`enc_button_power`), o menu de magias |
| **ITEM** | Usa um item do inventário (cura, buff) |
| **SPARE** (Poupar / Mercy) | Só fica utilizável quando algum inimigo em campo está com `mercy >= 100` — encerra a luta pacificamente |
| **DEFEND** | Assume postura defensiva: dano recebido cai a 2/3 e o turno encurta |

> Repare que **ACT e MAGIC dividem o mesmo slot** — não é um menu fixo de quatro opções. Quem define isso é `item_spell_get_exists(item_s_act, nome)`.

A cada rodada você escolhe **uma** dessas ações pra cada membro do grupo, confirma, e então a luta passa pra fase de "levar tiro" — a parte descrita na Parte 2.

Internamente cada escolha vira um `PARTY_STATE` (`FIGHT`, `ACT`, `POWER`, `ITEM`, `SPARE`, `DEFEND`) e as ações são executadas numa ordem fixa, não na ordem em que você escolheu (`action_order` em `objects/o_enc/Create_0.gml:126`):

```
act → item → power → spare → fight → defend
```

### 1.3 O medidor de MERCY: a barra escondida

Cada inimigo tem uma barra interna chamada **MERCY** (misericórdia), que vai de 0 a 100 (`mercy` em `scripts/enc_enemies/enc_enemies.gml:15`). Quando ela chega em 100, a opção **SPARE** se torna utilizável — o inimigo está "convencido" a parar.

Duas coisas se confundem fácil, então vale separar:

- **`mercy`** (número, 0–100) — é o que **libera o botão SPARE**. A engine checa literalmente `_enemy.mercy >= 100` (`objects/o_enc/Create_0.gml:184`).
- **`can_spare`** (**booleano**, default `true`) — diz se aquele inimigo *pode ser poupado em teoria*. Se for `false`, a barra de MERCY aparece riscada com um X na UI (`objects/o_enc/Draw_64.gml:229`) e o SPARE nunca funciona, não importa a mercy.

> ⚠️ **`can_spare` tem que ser um bool, não uma função.** A engine o lê em contexto booleano direto (`if enemy_struct.can_spare` no Draw, `if __enemy.can_spare && ...` em `scripts/enc_actions/enc_actions.gml:369`). Passar um `function() { return mercy >= 100 }` ali quebra em tempo de execução. Se você quer "só pode poupar quando cheio", isso já é o comportamento padrão — deixe `can_spare = true`.

O jogador **não vê o número exato** normalmente (é uma barra de progresso) — parte da graça é descobrir o que faz essa barra subir, por tentativa e observação.

O que aumenta a MERCY, tipicamente:

- Usar o **ACT certo** naquele inimigo específico (às vezes mais de um, em sequência — ex: primeiro "Check", depois "Elogiar")
- Deixar o inimigo com **HP baixo** sem matá-lo: com `low_hp_tired = true` (default) e HP abaixo de `low_hp_tired_threshold` (default `1/2`), ele fica **TIRED** — estado que magias como "Sleep Mist" e "Pacify" usam pra poupar
- Tentar poupar e falhar: se `can_spare` for `true`, cada tentativa fracassada ainda soma `mercy_add_pity_percent` (default **20**) de "MERCY de consolo" (`scripts/enc_actions/enc_actions.gml:369`)

No seu Dustling, o ACT "Acalmar" dá `+60` de MERCY por uso — ou seja, em duas rodadas ele já está pronto pra ser poupado. É um exemplo propositalmente fácil, pensado pra ensinar a mecânica sem frustrar.

### 1.4 Por que cada inimigo tem ACTs diferentes

Isso é o coração da "escrita" de cada luta. Um ACT não é uma ação genérica — é escrito **especificamente para aquele personagem**, e geralmente é engraçado, curioso, ou revela algo sobre ele.

Pense nisso como um mini-diálogo interativo disfarçado de menu de batalha: em vez de o jogador *ler* sobre o inimigo, ele *investiga* o inimigo tentando ACTs diferentes até achar o que funciona. É basicamente um pequeno quebra-cabeça de "como eu resolvo esse conflito sem violência".

Por isso a tabela de ACTs do seu inimigo (`acts = [...]`) não é só mecânica — é onde a personalidade dele mora.

### 1.5 A fase de desviar: por que existe tensão ali

Depois que todo mundo escolheu sua ação, a luta entra na parte visual — a caixa preta, a alma, as balas (o "Bullet Board" descrito na Parte 2). Essa fase serve a dois propósitos ao mesmo tempo:

1. **Mecânico**: é o "turno do inimigo" — ele "ataca" através de um padrão de tiros que você precisa desviar. Se a alma é atingida, o grupo perde HP.
2. **Narrativo/emocional**: o *padrão de tiro em si* costuma refletir o estado emocional ou a personalidade do inimigo. Um inimigo nervoso atira devagar e sem mira. Um inimigo furioso atira rápido e denso. Um inimigo brincalhão faz um padrão bobo, quase decorativo.

Ou seja: o padrão de bala não é só "desafio de reflexo" — é também **caracterização**. É por isso que faz sentido variar o padrão conforme `o_enc.turn_count` (rodada 0 mais fácil, rodadas seguintes mais intensas) — isso simula o inimigo "esquentando" a luta.

### 1.6 As cores das balas — e por que elas mudam o jeito de desviar

Aqui mora a diferença mais importante entre a tlDR Engine e o que se costuma imaginar por "alma azul / alma laranja" nos jogos originais.

**Na tlDR Engine a alma não muda de cor.** Ela é sempre vermelha e sempre se move igual: livre nas quatro direções, sem gravidade, sem pulo (`enum SOUL_COLOR { RED }` em `objects/o_enc_soul/Create_0.gml:23`). **Não existe modo plataforma.**

Quem tem cor é a **bala**, e a cor é uma **regra de quando aquela bala machuca** (`objects/o_enc_bullet/Other_10.gml`):

| `BULLET_COLOR` | Quando machuca | O que exige do jogador |
|---|---|---|
| **`SOLID`** (padrão) | Sempre que encosta na alma | Desviar de verdade — sair do caminho |
| **`BLUE`** | **Só se a alma estiver se movendo** | **Ficar parado** enquanto ela passa |
| **`ORANGE`** | **Só se a alma estiver parada** | **Continuar se movendo** o tempo todo |

`BLUE` e `ORANGE` são espelhos um do outro. A leitura mental do jogador é "congela" vs. "não para", e é isso que dá variedade de ritmo sem inventar mecânica nova. O que a engine considera "se movendo" é a variável `o_enc_soul.moving`, que só é `true` quando há input de direção **e** a alma de fato saiu do lugar (não vale empurrar contra a parede).

Três consequências práticas que não são óbvias:

- **`destroy` só vale para `SOLID`.** Uma bala `BLUE`/`ORANGE` atravessa a alma e continua existindo mesmo depois de acertar (`if color == BULLET_COLOR.SOLID && destroy`).
- **Graze só acontece com balas `SOLID`.** O grazer ignora azuis e laranjas (`objects/o_enc_soul_grazer/Step_0.gml:12`), então elas não dão TP nem encurtam o turno.
- Misturar cores no mesmo turno é totalmente possível — cada bala carrega a sua regra. Um turno pode começar só com `SOLID` e depois soltar uma `BLUE` larga, forçando o jogador a parar de fugir e ficar imóvel.

### 1.7 Resumo do loop completo, em uma frase

> *"Escolha uma ação → veja o resultado → desvie do contra-ataque → repita, até o inimigo estar pronto pra ser poupado (ou até ele perder todo o HP)."*

Esse ciclo — decisão consciente seguida de reflexo em tempo real — é o que faz o gênero ser chamado às vezes de **"turn-based bullet hell"**. É um RPG na cabeça e um shooter nos dedos.

---

## Parte 2 — A implementação técnica na tlDR Engine

Com o conceito claro, agora sim: como cada peça da Parte 1 vira código.

> ⏱️ **O jogo roda a 30 FPS**, não 60 (`options/main/options_main.yy` → `"option_game_speed": 30`, e nada chama `game_set_speed` em lugar nenhum). Todas as conversões de frame para segundo neste documento usam 30. Isso importa: `timer_end = 60` é **dois** segundos.

### 2.0. O nome disso tudo: "Bullet Board"

O sistema de luta da tlDR Engine é uma implementação do que a comunidade Undertale/Deltarune chama de **Bullet Board** (também "bullet hell de turnos"). A ideia geral, fora do código, é sempre a mesma:

1. Você **decide** o que fazer no menu (Fight, Act/Magic, Item, Spare, Defend).
2. A tela vira uma **caixa fechada** (a *box*).
3. Um coraçãozinho — a **alma** (*soul*) — aparece dentro da box.
4. Balas (*bullets*) entram na box e se movem.
5. Você desvia. Se a alma toca uma bala, toma dano.
6. Quando o turno acaba, a box fecha e volta pro menu.

Isso se repete até o inimigo morrer, ser poupado, ou você perder.

Cada uma dessas fases é um **objeto GameMaker diferente** que aparece e some na hora certa. Entender qual objeto é responsável por qual fase é a chave.

| Fase | Quem manda |
|---|---|
| Menu (Fight/Act/Item/Spare/Defend) | `o_enc` |
| A "sala" onde a alma fica | `o_enc_box` (visual) + `o_enc_box_solid` (paredes) |
| O coração controlável | `o_enc_soul` |
| A zona de graze em volta do coração | `o_enc_soul_grazer` |
| Os tiros | `o_enc_bullet` (uma instância por bala) |
| O padrão de ataque de um turno | `turn_object` (`o_turn_*`) |

---

### 2.1. `o_enc` — o maestro da luta inteira

Quando você chama `enc_start(meu_set)`, a engine cria um `o_enc_anim` que por sua vez leva ao `o_enc`. Ele existe do primeiro ao último frame da batalha e guarda o estado geral:

```gml
o_enc.turn_count        // qual rodada estamos (0, 1, 2...)
o_enc.encounter_data    // o enc_set() em uso, com o array enemies[]
o_enc.encounter_data.enemies[slot]   // o struct enemy() de um inimigo específico
o_enc.tp                // a barra de TP (0–100), alimentada pelo graze
o_enc.turn_objects      // array com o turn_object de cada inimigo
o_enc.mybox / o_enc.mysoul   // as instâncias da box e da alma do turno atual
```

`o_enc` **não desenha as balas nem move a alma**. O trabalho dele é orquestrar uma máquina de estados (`battle_state_order` em `Create_0.gml:140`) e chamar os hooks do seu `enemy()`/`enc_set()` na ordem certa.

#### A ordem real dos eventos de um turno

Esta é a sequência exata de `objects/o_enc/Step_0.gml` — vale decorar, porque a ordem intuitiva está errada em dois pontos:

```
MENU        → você escolhe as ações
EXEC        → as ações rodam (ordem fixa: act, item, power, spare, fight, defend)
              → ev_party_exec
DIALOGUE    → os turn_objects são CRIADOS  ← as instâncias já existem aqui
              → User Event 0 de cada turn_object   ("init")
              → ev_dialogue
              → os alvos do turno são sorteados (enc_calculate_target)
TURN        → o_enc_box e o_enc_soul são criados
              → User Event 2 de cada turn_object   ("box is created")
              → User Event 1 de cada turn_object   ("turn starts")
              → ev_turn_start
              → ... o turno roda ...
              → acaba quando TODOS os turn_objects forem destruídos
              → a box fecha
POST_TURN   → turn_count ++          ← já incrementou antes do hook
              → ev_post_turn
```

Dois detalhes que pegam todo mundo:

- **O `turn_object` nasce antes de `ev_turn_start`**, não depois. Se você precisa configurar algo no turn_object a partir de um hook do inimigo, o ponto certo é `ev_dialogue` (ou o próprio User Event 0/2 do turn_object).
- **`turn_count` já foi incrementado quando `ev_post_turn` roda.** Dentro de `ev_post_turn`, `turn_count` vale a rodada *seguinte*.

O que encerra o turno **não é um timer do `o_enc`** — é o desaparecimento dos turn_objects. Enquanto restar um vivo, a box continua aberta.

---

### 2.2. A `box` — os limites onde a alma pode andar

`o_enc_box` é o retângulo (visualmente, o quadrado preto) que contém a alma e as balas. Ele nasce centralizado na tela e tem `width`/`height` próprios (default 75×75):

```gml
o_enc_box.x        // centro X da box
o_enc_box.y        // centro Y da box
o_enc_box.width    // largura (default 75)
o_enc_box.height   // altura  (default 75)
```

> ⚠️ **As paredes não são o `o_enc_box`.** A colisão da alma é feita contra **`o_enc_box_solid`** (`objects/o_enc_soul/Step_0.gml`), que são os blocos sólidos das bordas. `o_enc_box` é a parte visual/superfície. Se você for mexer em formato de arena, é o `o_enc_box_solid` que importa.

**Balas ignoram as paredes.** Nada segura uma bala dentro da box — ela atravessa e sai. Quem decide se ela *aparece* recortada é o campo `inside` (seção 2.4), não a posição.

---

### 2.3. A alma (`o_enc_soul`) — o que ela é de verdade

A alma **não é algo que você cria por inimigo**. Ela é parte fixa do sistema: o `o_enc` a cria quando a fase de defesa começa e ela some quando a fase termina.

```gml
o_enc_soul.x / .y     // posição — use pra mirar
o_enc_soul.moving     // true só se houve input E a alma realmente saiu do lugar
o_enc_soul.i_frames   // invencibilidade restante, em frames
o_enc_soul.spd        // velocidade base (8); segurar CANCEL anda na metade
o_enc_soul.canmove
```

Ela se move sempre igual — livre nas quatro direções, colidindo com `o_enc_box_solid` em passos de 0.25px. Não há gravidade, pulo ou modo alternativo: o enum `SOUL_COLOR` do projeto tem **um único valor, `RED`**.

#### Colisão com bala: onde isso acontece de verdade

Não existe evento `Collision` na bala. Quem detecta é a **própria alma**, no `Step`:

```gml
// objects/o_enc_soul/Step_0.gml
if place_meeting(x, y, o_enc_bullet) {
    with instance_place(x, y, o_enc_bullet) {
        event_user(0);     // ← o "fui atingido" da bala é o User Event 0 dela
    }
}
```

Ou seja: **o User Event 0 de `o_enc_bullet` é o evento de acerto.** É lá que a cor é checada, os i-frames são aplicados e o dano é distribuído. Se você criar uma bala filha e quiser mudar o que acontece no acerto, é esse evento que se sobrescreve.

#### Graze — o "quase acertei"

Em volta da alma existe um segundo objeto, **`o_enc_soul_grazer`**, que segue a alma todo frame. Se uma bala **`SOLID`** encosta nele sem encostar na alma, a engine conta como "grazada" e:

1. soma `graze` pontos na barra de **TP** (`o_enc.tp`, limitada a 0–100);
2. **encurta o turno** em `time_points` frames, para cada turn_object que tenha `shorten_by_tension = true`;
3. toca `snd_graze` e pisca o anel do grazer.

Grazar a *mesma* bala repetidamente rende bem menos (`graze/12` e `time_points/30`).

> **O campo `graze` da bala não é um raio.** É a **quantidade de TP** que ela concede (`"how many graze points the bullet should give upon first contact"`, `objects/o_enc_bullet/Create_0.gml:7`). O **tamanho** da zona vem da escala do sprite do `o_enc_soul_grazer`, e é aumentado por itens equipados (`item_a_pink_ribbon` +20%, `item_a_twin_ribbon` +25%, teto de 2.5×).

É por isso que jogadores habilidosos voam rente às balas: mais TP, mais magias, e turnos mais curtos.

#### Invencibilidade (i-frames)

Depois que a alma toma um hit, ela fica temporariamente imune, pra não tomar dano múltiplo da mesma bala ou de balas empilhadas:

```gml
inv = global.enc_soul_inv   // frames de invencibilidade — default 40 (~1,3s a 30fps)
```

Definido em `scripts/enc_setup/enc_setup.gml:3`. Enquanto `i_frames > 0` a alma também **não consegue grazar**.

---

### 2.4. A bala (`o_enc_bullet`) — anatomia completa

Cada tiro é uma **instância independente**. O `Step` de `o_enc_bullet` é vazio: o movimento é o nativo do GameMaker (`speed`/`direction`, e por tabela `hspeed`/`vspeed`/`friction`/`gravity`), então você não precisa escrever `x += ...` na mão.

Os campos, com os defaults reais de `objects/o_enc_bullet/Create_0.gml`:

```gml
enum BULLET_COLOR { SOLID, BLUE, ORANGE }   // definido no Create da própria bala

graze       = 2                     // quantos pontos de TP dá ao ser grazada
att         = 6                     // STAT de ataque base do dano (não é o dano final)
inv         = global.enc_soul_inv   // i-frames concedidos ao acertar (40)
time_points = 5                     // frames que o graze tira da duração do turno

color       = BULLET_COLOR.SOLID    // regra de quando essa bala machuca
destroy     = true                  // some ao acertar — SÓ vale para SOLID
element     = ""                    // elemento, para redução por resistência
inside      = false                 // desenhar recortada dentro da box?
```

#### `att` não é dano

`att` é o **stat** que entra no cálculo, não o número de HP perdido. A conta está em `scripts/party_hp/party_hp.gml:225`:

```
dano = 5 * att, menos a defesa do membro (1 a 3 por ponto de defesa),
       × 2/3 se ele estiver com DEFEND
```

Então `att: 4` não tira 4 de HP — tira algo em torno de 20. Para calibrar dificuldade, pense no `att` como "o quão forte é esse inimigo", na mesma escala do campo `attack` do `enemy()`.

#### Criando uma bala

A engine tem um **wrapper próprio** de `instance_create` (`scripts/custom/custom.gml:297`):

```gml
instance_create(obj, xx, yy, depth, post_var_struct)
```

```gml
instance_create(o_enc_bullet, xx, yy, DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
    att: 6,                        // stat de ataque
    color: BULLET_COLOR.SOLID,     // regra de acerto
    speed: 3,                      // velocidade (px/frame)
    direction: 270,                // 0=direita, 90=cima, 180=esquerda, 270=baixo
    graze: 2,                      // TP dado ao grazar
    time_points: 5,                // frames tirados do turno ao grazar
    inv: global.enc_soul_inv,      // i-frames concedidos
    destroy: true,                 // some depois de acertar (só SOLID)
    inside: false,                 // desenhar recortada dentro da box
    element: ""
})
```

> [!warning] Duas armadilhas do wrapper
> O nome `post_var_struct` já entrega as duas:
>
> 1. O struct é aplicado **depois** do evento Create da bala — então ele sobrescreve os defaults, como você espera.
> 2. Ele só atribui campos que **já existem** na instância (`variable_instance_exists`). Inventar um campo novo no struct (`meu_dado: 5`) é **silenciosamente ignorado** — nenhum erro. Para dados próprios, crie a variável no Create de uma bala filha primeiro, ou atribua depois: `inst.meu_dado = 5`.

`speed` e `direction` funcionam no struct porque são variáveis nativas da instância — a própria engine faz isso em `objects/o_enc_bullet_dark/Create_0.gml:32`.

#### `inside` — o que ele realmente faz

`inside` **não** controla onde a bala nasce. Ele controla **como ela é desenhada** (`objects/o_enc_bullet/Draw_0.gml`):

- `inside: false` (default) — desenha direto na tela. A bala é visível dentro e fora da box, e você a vê chegando de longe.
- `inside: true` — desenha na *surface* da box, ou seja, **recortada pelas bordas**: some visualmente ao sair. É o que dá a sensação de balas "presas" na arena.

Uma bala com `inside: true` desenhada numa depth `BULLETS_OUTSIDE` continua sendo recortada — quem manda no recorte é o `inside`, e a depth só decide a ordem de desenho:

```gml
DEPTH_ENCOUNTER.BULLETS_OUTSIDE  // -6500 — na frente de tudo (inclusive da alma)
DEPTH_ENCOUNTER.SOUL             // -6400
DEPTH_ENCOUNTER.BOX              // -6300
DEPTH_ENCOUNTER.BULLETS_INSIDE   // -6200 — atrás da moldura da box
```

#### Bala com desenho customizado

O desenho de `o_enc_bullet` mora no **User Event 1** (`Other_11.gml`), não no `Draw`. O `Draw` só decide *onde* desenhar (tela ou surface da box) e chama `event_user(1)`. Então, numa bala filha:

- para mudar o **visual**, sobrescreva `Other_11.gml`;
- para mudar o **acerto**, sobrescreva `Other_10.gml`;
- para mudar o **movimento**, sobrescreva `Step_0.gml` (com `event_inherited()`).

Exemplos reais: `o_ex_bullet_sguy_bullet`, `o_enc_bullet_dark`, `o_ex_bullet_dentos_eye`.

---

### 2.5. `turn_object` — onde a dinâmica de tiro é programada

Esse é o objeto que **você escreve**. Ele herda de `o_turn`, nasce no estado DIALOGUE e **se autodestrói para encerrar o turno**. Enquanto ele existe, a alma está ativa na tela.

#### Ciclo de vida (mapa de eventos → arquivos)

| Evento GameMaker | Arquivo | Quando roda | Pra que serve |
|---|---|---|---|
| Create | `Create_0.gml` | 1×, ao nascer | inicializar variáveis suas |
| User Event 0 | `Other_10.gml` | 1×, logo depois do Create | **init** — configurar `timer_end`, `pattern_pool` |
| User Event 2 | `Other_12.gml` | 1×, quando a box e a alma já existem | sortear/ajustar `pattern`, medir a box |
| User Event 1 | `Other_11.gml` | 1×, quando o turno começa de fato | **criar as balas** |
| Step | `Step_0.gml` | todo frame | lógica contínua |
| Destroy | `Destroy_0.gml` | ao se destruir | limpar balas remanescentes |

> **Nomes de arquivo:** User Event 0 = `Other_10.gml`, User Event 1 = `Other_11.gml`, **User Event 2 = `Other_12.gml`**. O User Event 2 ("box is created") costuma ser esquecido, mas é onde o `o_turn` base sorteia o `pattern` a partir do `pattern_pool` — se você usa padrões múltiplos e sobrescreve esse evento, chame `event_inherited()`.

#### Campos herdados de `o_turn` que valem conhecer

```gml
timer / timer_end     // contador do turno; timer só anda depois do User Event 1
enemy_index           // slot do inimigo dono deste turno
enemy_struct          // o struct enemy() dele — enemy_struct.actor_id é a instância na tela
pattern / pattern_pool          // sorteio de padrão de ataque (default [1])
assign_unique_patterns = true   // dois inimigos iguais tendem a sortear padrões diferentes
buff / debuff         // quantos inimigos iguais / diferentes estão atacando junto
allow_same_turns = false        // se false, turnos duplicados se fundem e viram `buff`
shorten_by_tension = true       // deixa o graze encurtar este turno
am_support = false              // turno "de apoio": só existe junto de um turno principal
```

#### Como um turno termina — os dois mecanismos

São **coisas diferentes**, e é fácil confundir:

**1. `timer_end` — o timer.** Fica no `Step` do `o_turn` **pai**, herdado via `event_inherited()`:

```gml
// objects/o_turn/Step_0.gml
if turn_started
    timer ++
if !is_undefined(timer_end) && timer > timer_end
    instance_destroy()
```

Note que `timer` **conta pra cima** e só começa depois do User Event 1. Com `timer_end = undefined` o turno nunca acaba sozinho — você precisa chamar `instance_destroy()` na mão.

**2. `__support_destroy_check()` — turnos de apoio.** Ele **não olha o `timer_end`**. Ele só existe para inimigos de apoio (`am_support = true`): destrói este turno quando não sobrou mais nenhum turno **principal** vivo (`objects/o_turn/Create_0.gml:31`). Num turno normal (`am_support = false`) a chamada não faz nada — é uma rede de segurança, não o fim do turno.

E `__support_init_default()` é o companheiro dele: roda no init e marca `am_support = true` se já existir outro turn_object não-apoio em campo.

#### O exemplo mínimo (`o_turn_default`) explicado

```gml
// Create_0.gml
event_inherited()          // sempre primeira linha — herda do o_turn base
_ex_bullet = noone         // guarda referência da bala pra poder limpar depois
timer_end = undefined      // por ora, não termina sozinho

// Other_10.gml — User Event 0 (init)
event_inherited()
__support_init_default()   // decide se este turno é "de apoio"
if !am_support             // turno principal: dura um tempo fixo
    timer_end = 60         // 60 frames = 2 segundos a 30fps
                           // (turno de apoio fica com timer_end undefined
                           //  e morre junto com o principal)

// Other_11.gml — User Event 1 (turno começa)
event_inherited()
_ex_bullet = instance_create(
    o_enc_bullet,
    o_enc_box.x, o_enc_box.y - 20,     // nasce um pouco acima do centro
    DEPTH_ENCOUNTER.BULLETS_OUTSIDE
)

// Step_0.gml
event_inherited()          // ← é ISTO que faz o timer_end funcionar
__support_destroy_check()  // rede de segurança para turnos de apoio

// Destroy_0.gml
instance_destroy(_ex_bullet)   // limpa a bala se ainda existir
```

Repare que a bala criada aqui fica **parada** (sem `speed`) — o `o_turn_default` é literalmente "um turno que mostra uma bala e espera dois segundos". É o esqueleto pra copiar, não um padrão de verdade.

---

### 2.6. Construindo padrões de verdade

Aqui é onde a "dinâmica" de fato acontece — combinações de tempo, posição e ângulo criam a sensação de dificuldade crescente. **Lembre: 30 frames = 1 segundo.**

#### Padrão A — tiro reto simples (o mais básico)

```gml
// Other_11.gml
instance_create(o_enc_bullet, o_enc_box.x - 60, o_enc_box.y, DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
    speed: 2, direction: 0, att: 4    // vai da esquerda pra direita
})
```

#### Padrão B — rajada espaçada no tempo (usa `alarm`)

Uma bala só, várias vezes, com pausa entre cada uma:

```gml
// Other_11.gml
_shots_fired = 0
alarm[0] = 15   // primeira bala em 15 frames = 0,5s

// Alarm_0.gml
if _shots_fired < 5 {
    instance_create(o_enc_bullet, o_enc_box.x, o_enc_box.y - 40, DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
        speed: 3, direction: 270, att: 4
    })
    _shots_fired++
    alarm[0] = 15   // reagenda o próximo disparo
}
```

> Com 5 tiros a cada 15 frames você precisa de pelo menos `timer_end = 75+` pra rajada caber no turno.

Alternativa sem alarme, usando o `timer` herdado — costuma ser mais legível e é o que os exemplos da engine fazem:

```gml
// Step_0.gml
event_inherited()
if timer > 0 && timer % 15 == 0 && timer < timer_end - 20 {
    instance_create(o_enc_bullet, o_enc_box.x, o_enc_box.y - 40, DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
        speed: 3, direction: 270
    })
}
__support_destroy_check()
```

#### Padrão C — leque circular (várias balas de uma vez)

```gml
// Other_11.gml
for (var i = 0; i < 8; i++) {
    var ang = i * 45   // 8 balas espaçadas em círculo (360/8 = 45°)
    instance_create(o_enc_bullet, o_enc_box.x, o_enc_box.y, DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
        speed: 2, direction: ang, att: 3
    })
}
```

#### Padrão D — bala "teleguiada" (mira na alma)

Como o `Step` da bala base é vazio, dá pra fazer de duas formas.

**Mira fixa no momento do disparo** (mais justa, e sem objeto novo):

```gml
// Other_11.gml
instance_create(o_enc_bullet, o_enc_box.x, o_enc_box.y - 50, DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
    speed: 3,
    direction: point_direction(o_enc_box.x, o_enc_box.y - 50, o_enc_soul.x, o_enc_soul.y)
})
```

**Perseguição contínua** — aí sim vale um objeto filho de `o_enc_bullet`:

```gml
// Step_0.gml de o_enc_bullet_homing (Parent: o_enc_bullet)
event_inherited()
direction = point_direction(x, y, o_enc_soul.x, o_enc_soul.y)
```

> `point_direction(x1, y1, x2, y2)` é função nativa do GameMaker. Recalcular todo frame faz a bala colar na alma — na prática é quase impossível desviar sem um `friction`/limite de curva. Veja `o_enc_bullet_dark`, que faz homing "suave" de verdade e aceita um `homing_target` no struct de criação.

#### Padrão E — variando por rodada (progressão de dificuldade)

```gml
// Other_11.gml
if o_enc.turn_count == 0 {
    // primeira vez — padrão fácil, poucas balas lentas
} else if o_enc.turn_count == 1 {
    // segunda rodada — mais balas, mais rápido
} else {
    // rodadas seguintes — padrão final
}
```

Uma alternativa que a engine já oferece de graça: `buff`. Se dois inimigos iguais atacam juntos, `buff` vale 1, e o `o_turn_default_dark` usa isso pra atirar mais rápido:

```gml
var __buffed_period = clamp(25 - (5 * buff), 15, 25)
if timer % __buffed_period == 0 { ... }
```

#### Padrão F — misturando cores (`SOLID` → `BLUE` no mesmo turno)

Troca o *tipo de exigência* no meio do turno: primeiro fugir, depois congelar.

```gml
// Other_11.gml — fase 1: bala normal, o jogador foge dela
instance_create(o_enc_bullet, o_enc_box.x + 60, o_enc_box.y, DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
    color: BULLET_COLOR.SOLID, speed: 2, direction: 180
})
alarm[0] = 45   // 1,5 segundos depois, muda a exigência

// Alarm_0.gml — fase 2: parede AZUL atravessando a box
// azul só machuca quem está se movendo → o jogador tem que PARAR
instance_create(o_enc_bullet, o_enc_box.x - 70, o_enc_box.y, DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
    color: BULLET_COLOR.BLUE, speed: 2, direction: 0,
    image_xscale: 1, image_yscale: 6      // uma "parede" alta, impossível de desviar
})
```

O truque do azul é justamente esse: a bala é **grande demais pra desviar**, e a resposta certa é soltar o direcional. Uma bala azul pequena e fácil de evitar não ensina nada. Vale o mesmo, invertido, pro laranja: ele funciona quando o jogador está tentado a ficar parado num canto seguro.

---

### 2.7. Terminando o turno — as duas estratégias

**Timer fixo** (mais simples, usado no default):

```gml
timer_end = 90   // 3 segundos a 30fps; o o_turn pai destrói sozinho quando estoura
```

**Condicional manual** (quando você quer terminar só depois de algo específico, tipo "todas as balas desapareceram"):

```gml
// Other_10.gml
timer_end = undefined      // desliga o encerramento automático

// Step_0.gml
event_inherited()
if timer > 30 && !instance_exists(o_enc_bullet)
    instance_destroy()
```

Cuidado com `timer_end = undefined` sem uma condição de saída: o turno **nunca acaba** e a batalha trava. É o erro mais comum de turn_object customizado.

Lembre também que **o turno acaba quando o último turn_object morre** — com vários inimigos, um turno curto simplesmente espera os outros.

---

### 2.8. Ligando tudo — checklist de uma luta completa

1. **`enemy()`** — ficha do inimigo (hp, stats, acts, sprites, `turn_object`)
2. **`enc_set()`** — quem participa da luta, música, flavor, posição
3. **`o_turn_*`** — seu padrão de tiro customizado (copie `o_turn_default`, com Parent `o_turn`)
4. **Disparo**: `enc_start(new meu_enc_set())` — via console, trigger, ou tocando no inimigo do overworld

```gml
// enemy() aponta pro seu turno customizado
turn_object = o_turn_dustling

// enc_set() reúne o inimigo
enemies = [ new ex_enemy_dustling() ]
```

---

### 2.9. Testando a dinâmica de desvio

Antes de montar a room, use sempre o console (**`TAB`** → `encounter_select`) pra iterar rápido no padrão de tiro. O comando `encounter_end` encerra o turno na hora, o que ajuda quando você trava a batalha sem querer.

Perguntas úteis enquanto testa:

- **Dá pra desviar sem tomar dano nenhum, uma vez que você entendeu o padrão?** Se não, geralmente é rápido/denso demais para um inimigo cedo no jogo.
- **O primeiro segundo do turno dá tempo de reação?** Balas que nascem em cima da alma sem aviso costumam ser injustas — dê distância ou um atraso inicial. Repare que o grazer só liga depois de `o_enc.turn_timer > 10`, ou seja, a engine já assume um pequeno "aquecimento".
- **Dá pra grazar?** Se as balas passam sempre longe, o jogador nunca ganha TP e as magias ficam inúteis. Um bom padrão *convida* a chegar perto.
- **Se usar `BLUE` ou `ORANGE`, a bala é grande/densa o bastante pra forçar a regra?** Azul pequena vira bala normal que o jogador desvia sem perceber a mecânica. E dê alguma pista visual/textual de que a regra mudou.

---

### 2.10. Referência rápida de tudo que apareceu aqui

```gml
// objetos do sistema (não criados por você)
o_enc              // maestro — turn_count, encounter_data, tp, turn_objects
o_enc_box          // a arena (visual/surface) — .x .y são o centro
o_enc_box_solid    // as paredes de verdade (colisão da alma)
o_enc_soul         // a alma — .x .y .moving .i_frames
o_enc_soul_grazer  // a zona de graze que segue a alma
o_enc_bullet       // bala base (Step vazio: usa speed/direction nativos)

// o que você escreve
turn_object = o_turn_meu_padrao   // dentro do enemy(); Parent do objeto: o_turn

// criando uma bala (wrapper da engine: scripts/custom/custom.gml)
instance_create(o_enc_bullet, xx, yy, depth, {
    att, color, speed, direction, graze, time_points, inv, destroy, inside, element
})
// atenção: o struct só atinge campos que JÁ existem na instância

// cores da bala = regra de quando ela machuca (a alma nunca muda de física)
BULLET_COLOR.SOLID    // sempre; única cor que dá graze e que respeita `destroy`
BULLET_COLOR.BLUE     // só machuca se a alma estiver SE MOVENDO  → fique parado
BULLET_COLOR.ORANGE   // só machuca se a alma estiver PARADA      → continue andando

// eventos do turn_object
Create_0.gml    // suas variáveis
Other_10.gml    // User Event 0 — init (timer_end, pattern_pool)
Other_12.gml    // User Event 2 — box criada (pattern sorteado aqui pelo o_turn)
Other_11.gml    // User Event 1 — turno começa (crie as balas)
Step_0.gml      // event_inherited() faz o timer_end funcionar
Destroy_0.gml   // limpeza

// eventos da bala
Other_10.gml    // User Event 0 — ACERTO na alma
Other_11.gml    // User Event 1 — DESENHO
Step_0.gml      // vazio na base — sobrescreva para movimento customizado

// profundidades de desenho (scripts/macro_depth)
DEPTH_ENCOUNTER.BULLETS_OUTSIDE  // -6500  (na frente de tudo)
DEPTH_ENCOUNTER.SOUL             // -6400
DEPTH_ENCOUNTER.BOX              // -6300
DEPTH_ENCOUNTER.BULLETS_INSIDE   // -6200  (atrás da moldura)

// timing
30 frames = 1 segundo
```

---

## Apêndice — correções aplicadas ao rascunho original

Este documento foi escrito antes sem acesso ao `.yyp`. Segue o que foi corrigido depois da verificação contra o projeto, para referência:

| # | O que o rascunho dizia | O que é de verdade |
|---|---|---|
| 1 | `BLUE` = modo plataforma, gravidade e pulo | `BLUE` só machuca a alma **em movimento** (é o "fique parado"). Não existe modo plataforma; `SOUL_COLOR` só tem `RED` (`o_enc_soul/Create_0.gml:23`) |
| 2 | "a cor da bala muda a física da alma inteira" | A cor é regra de dano **por bala**. `destroy` só vale para `SOLID`, e **graze só é dado por balas `SOLID`** (`o_enc_soul_grazer/Step_0.gml:12`) |
| 3 | `graze` = "força da zona de graze" | `graze` = **pontos de TP** concedidos (`o_enc_bullet/Create_0.gml:7`). A zona vem da escala do `o_enc_soul_grazer` + itens ribbon. Faltava também `time_points` |
| 4 | `att` = dano ao acertar | `att` é **stat**: `dano = 5*att` menos defesa (`party_hp.gml:225`). Default é 6, não 4 |
| 5 | "60 frames = 1 segundo (a 60fps)" | O jogo roda a **30 FPS** (`options/main/options_main.yy`). `timer_end = 60` são 2 segundos |
| 6 | `inside: true` = "nasce dentro da box" | `inside` controla se a bala é **desenhada recortada** na surface da box (`o_enc_bullet/Draw_0.gml`). Não afeta spawn nem colisão |
| 7 | Menu de 4 botões (Fight/Act/Item/Spare) | São **5**: FIGHT, ACT **ou** MAGIC (mesmo slot), ITEM, SPARE, **DEFEND** (`o_enc/Create_0.gml:82`) |
| 8 | `ev_turn_start` → turn_object é criado | O turn_object é criado **antes**, no estado DIALOGUE. E `turn_count++` acontece **antes** de `ev_post_turn` |
| 9 | Tabela de eventos sem o User Event 2 | Existe `Other_12.gml` ("box is created"), onde o `pattern` é sorteado do `pattern_pool` |
| 10 | `__support_destroy_check()` "checa `timer_end`" | Ele só encerra **turnos de apoio** quando não há mais turno principal. O `timer_end` é tratado no `Step` do `o_turn` pai, via `event_inherited()` |
| 11 | Colisão bala↔alma não documentada | É `place_meeting` no `o_enc_soul/Step_0.gml`, que chama `event_user(0)` na bala. Não há evento Collision. E o **desenho** da bala é o User Event 1 |
| 12 | Paredes da box = `o_enc_box` | A colisão é com **`o_enc_box_solid`** |
| 13 | Referência a `sdsds.md` | Arquivo não existe; os companheiros são `tldr-engine-guia.md` e `tutorial-batalhas.md` |

Também vale um aviso fora do escopo do texto original: em `scripts/rpg_enc_enemies/rpg_enc_enemies.gml`, `can_spare` está escrito como uma **função**. A engine lê esse campo como **booleano** puro (`o_enc/Draw_64.gml:229`, `enc_actions.gml:369`) e isso quebra em runtime — use `can_spare = true`; quem libera o SPARE é `mercy >= 100`.

---

*Companheiro de `docs/tldr-engine-guia.md` e `docs/tutorial-batalhas.md`. Verificado contra `o_enc`, `o_enc_box`, `o_enc_soul`, `o_enc_soul_grazer`, `o_enc_bullet`, `o_turn`, `o_turn_default`, `o_turn_default_dark`, `o_ex_turn_sguy`, `o_ex_turn_complex_box`, `enc_scripts.gml`, `enc_enemies.gml`, `enc_actions.gml`, `party_hp.gml`, `custom.gml`, `macro_depth.gml`, `enc_setup.gml` e `options_main.yy`.*
