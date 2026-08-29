---
title: Criando o SONSO — um inimigo do zero
tags:
  - tldr-engine
  - gamemaker
  - combate
  - tutorial
---

# Tutorial passo a passo: criando o SONSO, um inimigo do zero

> Do arquivo vazio até uma luta jogável, em nove passos. Cada passo termina com algo **testável** — você nunca escreve mais de 20 linhas sem rodar o jogo.
>
> Companheiro de [`tldr-engine-guia.md`](tldr-engine-guia.md) (referência de campos), [`tutorial-batalhas.md`](tutorial-batalhas.md) (visão geral) e [`tutorial-luta.md`](tutorial-luta.md) (como a luta funciona por dentro).

---

## O que vamos construir

Um gato de rua chamado **SONSO**.

Ele não é um monstro. Ele é um gato — e a piada de design é essa: **o botão óbvio é o errado**. O jogador vai tentar `Chamar` o gato ("psiu, psiu"), porque é o que se faz com um gato. E o Sonso vai virar as costas, ofendido, e atacar com mais raiva.

O que funciona é o contrário: **`Ignorar`**. Olhar para o outro lado. Aí ele se aproxima sozinho.

Esse é o coração do gênero — o inimigo não é um saco de HP, é um pequeno enigma social. E a parte mais bonita: o **humor** dele muda o **padrão de balas**. O jogador percebe que errou não porque leu um texto, mas porque o ataque ficou pior.

| Humor | Como se chega lá | Fala | Ataque |
|---|---|---|---|
| `sonso` (inicial) | começo da luta | "não faz nada, de propósito" | **Patadas** — três garranhões horizontais alternando de lado |
| `irritado` | usar **Chamar** | "bufa, orelhas pra trás" | **Bufada** — chuvisco rápido + um **bote azul** (solte o direcional!) |
| `curioso` | usar **Ignorar** | "finge olhar pro outro lado" | **Ronronar** — um cerco **laranja** que fecha devagar (não pare de andar!) |

Duas vezes `Ignorar` (+50 de MERCY cada) e ele senta. Fim pacífico.

> [!tip] Por que um gato?
> Porque a mecânica *já é* a personagem. Não precisa explicar num diálogo que o gato é orgulhoso — o jogador descobre isso apanhando. Quando você for inventar o seu próprio inimigo, comece por aí: **qual comportamento humano vira uma regra de botão?**

---

## Passo 0 — Onde cada coisa mora

Quatro peças, quatro lugares:

| Peça | Onde escrever | Nome que vamos usar |
|---|---|---|
| A **ficha** do inimigo (`enemy()`) | `scripts/rpg_enc_enemies/rpg_enc_enemies.gml` | `rpg_enemy_sonso()` |
| O **encontro** (`enc_set()`) | `scripts/rpg_enc_sets/rpg_enc_sets.gml` | `rpg_enc_set_sonso()` |
| O **turno** (padrão de balas) | objeto novo, Parent `o_turn` | `o_turn_sonso` |
| O **ator** (o corpo na tela) | nenhum! usamos `o_actor_e` | — |

Os dois scripts já existem no seu projeto. Só o objeto de turno vai ser criado do zero, e só no Passo 6.

Sprites: vamos usar os do **tasque**, que já estão no projeto e ainda não têm inimigo nenhum usando — `spr_ex_e_tasque`, `spr_ex_e_tasque_hurt`, `spr_ex_e_tasque_spared`. Quando você desenhar os seus, é só trocar três linhas.

> [!warning] A regra que evita 90% da dor
> Um identificador solto em GML é resolvido como **nome de asset em tempo de compilação**. Se o sprite não existir com aquele nome exato, o jogo não compila (`spr_xxx not defined`). Já um **campo de struct** com nome errado **nunca dá erro** — só é ignorado em silêncio. Por isso: sprite errado você descobre na hora; `maxhp` em vez de `max_hp` você descobre depois de uma hora de teste.

---

## Passo 1 — O inimigo mínimo que compila

Abra `scripts/rpg_enc_enemies/rpg_enc_enemies.gml` e escreva:

```gml
function rpg_enemy_sonso() : enemy() constructor {
    name = "Sonso"
    obj  = o_actor_e          // ator genérico da engine; serve perfeitamente

    // stats
    hp      = 60
    max_hp  = 60              // atenção ao underline: maxhp NÃO existe
    attack  = 4
    defense = 1
    carrying_money = 12

    // sprites (já existem no projeto)
    s_idle  = spr_ex_e_tasque
    s_hurt  = spr_ex_e_tasque_hurt
    s_spare = spr_ex_e_tasque_spared

    dialogue = "* Miau."

    turn_object = o_turn_default   // por enquanto: uma bala parada
}
```

É só isso. Todo o resto (`mercy`, `acts`, `can_spare`, hooks…) vem do `enemy()` base com defaults utilizáveis.

> [!info] Sobre `attack = 4`
> `attack` é um **stat**, não o dano. A conta é `5 * att`, menos a defesa do membro do grupo (`scripts/party_hp/party_hp.gml:225`). Então 4 tira uns **20 de HP** por bala acertada — um bom valor pra um inimigo de começo de jogo. Se quiser um gato inofensivo, use 2.

---

## Passo 2 — O encontro

Abra `scripts/rpg_enc_sets/rpg_enc_sets.gml`:

```gml
function rpg_enc_set_sonso() : enc_set() constructor {
    debug_name = "sonso"                    // o nome que aparece no console

    enemies = [ new rpg_enemy_sonso() ]     // repare no `new`

    flavor = "* Um gato bloqueia a passagem. Tecnicamente."

    enemies_pos = [ [0, 0, true] ]          // [x, y, relativo ao ponto padrão]
    bgm = mus_battle
}
```

> [!warning] `flavor` mora no `enc_set()`, não no `enemy()`
> É o texto do **encontro** (aparece a cada rodada, em cima do menu), não a fala do bicho. Se você puser `flavor` dentro do `enemy()`, ele simplesmente não faz nada — nenhum erro. A fala do inimigo é o `dialogue`, e ela aparece num balão.

---

## Passo 3 — Testar agora (não construa a sala ainda)

1. Rode o jogo.
2. **`TAB`** abre o console.
3. Digite `encounter_select`.
4. Escolha **`sonso`**.

A luta abre na hora. Você deve ver o gato, o menu de cinco botões, o balão "* Miau." e, ao confirmar as ações, uma caixa preta com uma bala parada.

Se `sonso` não aparecer na lista, o arquivo não compilou — olhe a janela **Output**. Esse ciclo (mexer → `TAB` → `encounter_select`) é o seu loop de trabalho pelo resto do tutorial. Não monte room nenhuma até o Passo 9.

> [!tip] Comandos de console que salvam tempo
> `encounter_end` encerra o turno na hora (útil quando você trava a luta com um `timer_end` mal feito) e `party_select` troca quem está no grupo.

---

## Passo 4 — Dar voz: o `dialogue` que reage ao humor

Agora o gato ganha estado. Vamos guardar o humor **no próprio struct do inimigo** — structs em GML aceitam campos novos sem reclamar, e o `enemy()` sobrevive a luta inteira, então é o lugar certo pra memória de curto prazo.

Troque o `dialogue = "* Miau."` por isto, e adicione os dois campos novos acima:

```gml
    // --- estado próprio do Sonso (campos nossos, não da engine) ---
    humor    = "sonso"     // "sonso" | "irritado" | "curioso"
    chamados = 0           // quantas vezes o jogador insistiu em chamar

    dialogue = method(self, function() {
        switch humor {
            case "irritado":
                return "* O Sonso bufa. As orelhas estão pra trás."

            case "curioso":
                return "* O Sonso finge olhar pro outro lado.";

            default:
                if o_enc.turn_count == 0
                    return "* Um gato te encara. Ele não parece impressionado."

                return choose(
                    "* O Sonso lambe a pata.",
                    "* O Sonso boceja.",
                    "* O Sonso não faz nada. De propósito."
                )
        }
    })
```

Duas coisas importantes aqui:

**Por que `method(self, ...)`?** Porque dentro dessa função queremos ler `humor`, que é campo do próprio inimigo. `method(self, ...)` amarra a função ao struct, então `humor` resolve certo. É o idioma que a própria engine usa (`enc_enemies.gml:363`).

**`dialogue` não recebe argumentos.** O guia diz que ela "pode aceitar o slot como arg0", mas o ponto onde a engine chama é `variable_callable_to_value(enemies[i].dialogue)` — **sem argumentos** (`objects/o_enc/Step_0.gml:254`). Se você escrever `function(slot)`, `slot` chega `undefined`. Se precisar do índice dentro dela, use `self.slot`, que a engine preenche (`objects/o_enc_anim/Alarm_1.gml:69`).

O `flavor` do encontro também pode reagir. Volte no `enc_set()` e troque a string por:

```gml
    flavor = function() {
        if o_enc.turn_count == 0
            return "* Um gato bloqueia a passagem. Tecnicamente."

        switch o_enc.encounter_data.enemies[0].humor {
            case "irritado": return "* O ar está tenso. E peludo."
            case "curioso":  return "* O Sonso está mais perto do que estava."
            default:         return "* Cheiro de telhado quente."
        }
    }
```

**Teste.** O texto ainda não muda (nada mexe no humor), mas a rodada 0 já fala diferente das seguintes.

---

## Passo 5 — Os ACTs: o enigma

### O que é um ACT

No menu de batalha, **ACT** é o botão do meio — o que **não** machuca ninguém. Enquanto `FIGHT` tira HP e `ITEM` usa o inventário, o ACT abre um **submenu de ações escritas especificamente para aquele inimigo**: Checar, Chamar, Ignorar, Elogiar, Dançar, o que a cena pedir.

É por ali que passa o caminho pacífico da luta: um ACT certo enche a barra de **MERCY**, e é a MERCY em 100 que acende o botão **SPARE**. Sem ACTs, o inimigo só pode ser resolvido na porrada.

Dito de outro jeito: **o ACT é onde a personalidade do inimigo mora**. É o mini-diálogo interativo disfarçado de menu.

### Onde o código vai

`acts` é **um campo do struct `enemy()`**, como `hp` ou `s_idle`. Vai **dentro** da função que você escreveu no Passo 1, em `scripts/rpg_enc_enemies/rpg_enc_enemies.gml`:

```gml
function rpg_enemy_sonso() : enemy() constructor {
    name = "Sonso"
    hp   = 60
    // ... todo o resto que você já escreveu ...

    acts = [        // ←— AQUI, ainda dentro das chaves da função
        { ... },
        { ... },
    ]
}                   // ←— a chave que fecha o constructor
```

O valor é um **array de structs**: cada `{ ... }` dentro dos colchetes é um botão do submenu, na ordem em que aparecem. O `enemy()` base já vem com um ACT "Check" de exemplo — o que você escrever **substitui** esse array inteiro.

> [!warning] Só o Kris tem o botão ACT
> O segundo slot do menu é **ACT** para quem tem o "item" `item_s_act` nos `spells`, e **MAGIC** para todo o resto (`objects/o_enc/Create_0.gml:82`). No projeto, só o Kris tem (`scripts/party_init/party_init.gml:152`). Se você testar a luta com a Susie selecionada e não achar o botão ACT, não é bug: é a Susie.
>
> Para dar uma ação própria aos outros membros, existe o campo irmão **`acts_special`**, com uma entrada por personagem — veja o virovirokun em `scripts/enc_enemies/enc_enemies.gml:239`. Ela aparece dentro do menu MAGIC daquele personagem, como "ação padrão".

### Os três ACTs do Sonso

Um que informa, um que **parece** certo e está errado, e um que parece inútil e é a solução:

```gml
    acts = [
        {
            name: "Checar",
            desc: "Análise inútil",
            party: [],
            exec: function(slot, user) {
                encounter_scene_dialogue(
                    "* SONSO - ATK 4 DEF 1{br}{resetx}"
                  + "* Gato de rua. Decide sozinho de quem ele gosta.{br}{resetx}"
                  + "* Detesta ser chamado."
                )
            }
        },
        {
            name: "Chamar",
            desc: "Psiu, psiu, psiu",
            party: [],
            exec: function(slot, user) {
                var me = o_enc.encounter_data.enemies[slot]
                me.chamados ++
                me.humor = "irritado"

                audio_play(snd_ui_cant_select)

                if me.chamados == 1
                    encounter_scene_dialogue("* " + party_getname(user) + " chamou o Sonso.{br}{resetx}* Ele virou as costas.")
                else
                    encounter_scene_dialogue("* " + party_getname(user) + " chamou de novo.{br}{resetx}* Agora ele está OFENDIDO.")
            }
        },
        {
            name: "Ignorar",
            desc: "Olhar fixamente para qualquer outra coisa",
            party: [],
            exec: function(slot, user) {
                var me = o_enc.encounter_data.enemies[slot]
                me.humor = "curioso"

                enc_enemy_add_spare(slot, 50)   // metade da barra de MERCY

                encounter_scene_dialogue("* " + party_getname(user) + " olhou fixamente para o nada.{br}{resetx}* O Sonso deu um passo na sua direção.")
            }
        }
    ]
```

### As três regras de um `exec`

**A assinatura é `function(slot, user)`.** `slot` é o índice do inimigo em `o_enc.encounter_data.enemies`; `user` é o **nome** de quem agiu, uma string (`"kris"`, `"susie"`…). A engine chama assim: `method_call(act.exec, array_concat([target, acting_member], exec_args))` (`scripts/enc_actions/enc_actions.gml:93`). Argumentos extras vêm do campo `exec_args`.

**Dentro do `exec`, `self` NÃO é o inimigo.** Ao contrário do `dialogue`, aqui a função está dentro de um *struct literal* (`{ ... }` no meio do array), então ela não está amarrada ao `enemy()`. Por isso a primeira linha é sempre `var me = o_enc.encounter_data.enemies[slot]`.

**Texto usa `encounter_scene_dialogue()`, nunca `dialogue_start()`.** O segundo é a caixa do overworld e abre no lugar errado. `{br}{resetx}` é o par de tags pra quebrar linha e voltar a margem — repare que aparece em todo exemplo da engine.

> [!info] O campo `party` decide quem vê o ACT
> `[]` = qualquer um. `["susie"]` = só a Susie. `["susie", "ralsei"]` = ACT conjunto, exige os dois no grupo. `-1` = ACT do grupo inteiro. Se você listar alguém que não está no grupo, o ACT some do menu — sem erro.

**Teste.** Agora sim: use `Chamar`, veja a fala mudar na rodada seguinte. Use `Ignorar` duas vezes e o botão **SPARE** acende (a barra chega a 100). Poupe. O gato deve trocar pro sprite `spr_ex_e_tasque_spared` e a luta acaba.

> [!warning] `can_spare` é bool, não função
> Existe a tentação de escrever `can_spare = function() { return mercy >= 100 }`. **Não faça.** A engine lê esse campo em contexto booleano direto, todo frame, no desenho da barra (`objects/o_enc/Draw_64.gml:229`) — uma função ali quebra em runtime. Quem libera o SPARE já é `mercy >= 100`; `can_spare` só responde "esse inimigo pode ser poupado *em teoria*?". Deixe `true`.

---

## Passo 6 — O turno próprio: `o_turn_sonso`

Até aqui o gato usa `o_turn_default` — uma bala parada. Vamos dar garras a ele.

### 6.1 Criando o objeto

1. **Asset Browser** → botão direito na pasta de objetos → **Create → Object**. Nome: **`o_turn_sonso`**.
2. **Sprite: nenhum.** É um objeto invisível de controle, não desenha nada.
3. **Parent: `o_turn`.** No painel do objeto, o campo **Parent** fica logo abaixo do de Sprite. Clique em *No Object Selected* e escolha `o_turn`. **É o passo mais fácil de esquecer, e sem ele nada funciona** — o objeto vira um objeto vazio qualquer, sem `timer`, sem `enemy_struct`, sem `__support_destroy_check()`.
4. Salve (`Ctrl+S`).

Depois, lá no `rpg_enc_enemies.gml`, aponte a ficha do inimigo pra ele:

```gml
    turn_object = o_turn_sonso
```

> [!warning] O evento que você abre pode ser o do PAI
> Depois que o Parent está definido, a lista de eventos do `o_turn_sonso` passa a mostrar **também** os eventos herdados do `o_turn`. Clicar num deles abre o código do **`o_turn`**, não o seu — é por isso que você pode acabar encarando um Create cheio de `buff = 0`, `pattern_pool = [1]` e `__support_init_default = function() { ... }`. Esse é o código da engine.
>
> Confira sempre o **título da aba** da janela de código: tem que dizer `o_turn_sonso : Create`, e não `o_turn : Create`. Se você digitar por cima do código do `o_turn`, quebra o turno de **todos** os inimigos do jogo.

### 6.2 Os eventos, um de cada vez

São quatro, e vamos criar e preencher um por vez. A rotina é sempre a mesma: **Add Event** → escolher o evento → o GameMaker avisa que ele existe no pai e oferece chamar a versão herdada → **aceite**. Ele já escreve o `event_inherited();` na primeira linha, que é exatamente o que queremos.

#### Evento 1 — Create

**Add Event → Create.** Cole:

```gml
event_inherited()

_lado = choose(-1, 1)   // de que lado começa a primeira patada
```

Uma variável só, por enquanto: de que lado a primeira garrada vem. Sortear no Create (e não no Step) faz cada luta começar diferente sem ficar aleatória demais no meio do turno.

#### Evento 2 — User Event 0

**Add Event → Other → User Events → User Event 0.** Cole:

```gml
event_inherited()
__support_init_default()

// o padrão deste turno É o humor do gato
pattern = enemy_struct.humor

if !am_support {
    switch pattern {
        case "irritado": timer_end = 150 break   // 5s — o mais longo e mais denso
        case "curioso":  timer_end = 90  break   // 3s — quase um carinho
        default:         timer_end = 120 break   // 4s
    }
}
```

Este é o evento de **init** do turno, e é onde a ligação entre personagem e mecânica acontece: o `pattern` deste turno passa a ser literalmente o humor do gato.

Duas coisas que não são óbvias aqui:

**`enemy_struct` já está preenchido.** A engine cria o turn_object passando `{enemy_index, enemy_struct}` no struct de criação e só depois chama o User Event 0 (`objects/o_enc/Step_0.gml:249`). Então dá pra ler o humor logo no init, sem esperar.

**Seu `pattern` não vai ser sobrescrito.** O `o_turn` base sorteia um `pattern` do `pattern_pool` mais tarde, no User Event 2 — mas usando `??=`, ou seja, **só se ainda estiver `undefined`**. Como você já definiu aqui, o seu vence.

#### Evento 3 — Step

**Add Event → Step → Step.** Cole:

```gml
event_inherited()          // ← é ISTO que faz o timer_end funcionar

// (os padrões de bala entram aqui no Passo 7)

__support_destroy_check()
```

**O `event_inherited()` aqui é obrigatório.** O `timer` que conta e o `timer_end` que encerra o turno vivem no Step do `o_turn` pai. Esqueceu a chamada? O turno nunca acaba e a batalha trava.

#### Evento 4 — Destroy

**Add Event → Destroy.** Cole:

```gml
event_inherited()               // devolve o inimigo ao sprite de idle
instance_destroy(o_enc_bullet)  // e recolhe as balas órfãs
```

**Limpar as balas não é frescura.** Nada na engine recolhe bala órfã — elas voam pra fora da box e continuam existindo. Sem essa linha, a próxima rodada começa com o lixo da anterior atravessando a tela. A própria engine faz isso em `o_ex_turn_complex_box/Destroy_0.gml`.

**E o `event_inherited()` também importa aqui.** O Destroy do `o_turn` pai devolve o inimigo ao sprite de idle (`objects/o_turn/Destroy_0.gml`). Sem a chamada, um inimigo que trocou de sprite durante o ataque fica congelado na pose de ataque pro resto da luta. O `o_turn_default` esquece essa chamada — só não dá problema porque ele nunca troca o sprite de ninguém.

> [!info] Os dois eventos que você NÃO deve criar
> O `o_turn` também tem **User Event 1** (faz `turn_started = true`, que é o que põe o `timer` pra contar) e **User Event 2** (sorteia o `pattern` do `pattern_pool`). O Sonso não precisa mexer em nenhum dos dois — **não adicione esses eventos** e deixe o pai cuidar deles. Se você adicionar o User Event 1 e esquecer o `event_inherited()`, o `timer` nunca anda e a batalha trava.

### 6.3 Teste

O gato agora ataca com... nada, por 3 a 5 segundos, dependendo do humor. Mas a caixa abre e fecha sozinha, e é exatamente isso que queríamos confirmar antes de escrever padrão de bala nenhum.

---

## Passo 7 — Humores viram padrões de bala

Todo o resto acontece no `Step_0.gml`, entre o `event_inherited()` e o `__support_destroy_check()`. Lembre: **30 frames = 1 segundo**.

### Humor `sonso` — as Patadas

Três garranhões paralelos entrando de um lado, depois do outro. A **falha entre as garras** é o caminho — o jogador tem que ler onde ela está e se posicionar.

```gml
if pattern == "sonso" {
    if timer % 30 == 0 && timer > 0 && timer < timer_end - 30 {
        _lado *= -1                              // alterna esquerda/direita
        var _falha = irandom_range(-20, 20)      // onde fica o buraco

        for (var i = -1; i <= 1; i ++) {
            instance_create(o_enc_bullet,
                o_enc_box.x + 80 * _lado,
                o_enc_box.y + _falha + i * 26,
                DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                    speed: 3,
                    direction: (_lado == 1 ? 180 : 0),
                    att: 4
                })
        }
    }
}
```

O `_lado * 80` faz as balas nascerem **fora** da box (que tem 75px de largura, centro em `o_enc_box.x`). Isso é deliberado: bala que nasce em cima da alma é injusta, o jogador precisa vê-la chegando.

### Humor `irritado` — a Bufada

Você chamou o gato. Agora ele te enche de pelo e dá um bote.

```gml
else if pattern == "irritado" {
    // 1) chuvisco rápido, caindo de cima
    if timer % 10 == 0 && timer > 0 && timer < timer_end - 50 {
        instance_create(o_enc_bullet,
            o_enc_box.x + irandom_range(-32, 32),
            o_enc_box.y - 60,
            DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                speed: 4, direction: 270, att: 4
            })
    }

    // 2) O BOTE: uma parede AZUL atravessa a box inteira
    if timer == timer_end - 45 {
        audio_play(snd_spawn_attack)

        instance_create(o_enc_bullet,
            o_enc_box.x - 100, o_enc_box.y,
            DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                color: BULLET_COLOR.BLUE,
                speed: 4, direction: 0, att: 5,
                image_xscale: 1.5, image_yscale: 6    // 22 x 90 px — não dá pra desviar
            })
    }
}
```

> [!warning] O azul é o contrário do que parece
> Na tlDR Engine, **`BLUE` só machuca a alma se ela estiver se movendo** (`objects/o_enc_bullet/Other_10.gml`). Não é modo plataforma, não tem pulo — a alma é sempre vermelha e sempre anda igual. A resposta certa a uma bala azul é **soltar o direcional**.
>
> E é por isso que a parede tem 90px de altura numa box de 75: se der pra desviar, o jogador desvia e nunca aprende a regra. Bala azul **precisa** ser impossível de evitar.

### Humor `curioso` — o Ronronar

Você ignorou o gato e ele se aproximou. O ataque vira um cerco lento e laranja: ele te ronda, e você não pode congelar.

```gml
else if pattern == "curioso" {
    if timer == 10 {
        for (var i = 0; i < 10; i ++) {
            var _ang = i * 36                      // 360/10

            instance_create(o_enc_bullet,
                o_enc_box.x + lengthdir_x(90, _ang),
                o_enc_box.y + lengthdir_y(90, _ang),
                DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                    color: BULLET_COLOR.ORANGE,
                    speed: 1, direction: _ang + 180,
                    att: 3
                })
        }
    }
}
```

`ORANGE` é o espelho do azul: **só machuca se a alma estiver parada**. Um anel fechando devagar é o cenário perfeito, porque o instinto do jogador é encolher no centro e esperar — exatamente o que mata.

> [!info] Por que o humor bom tem o ataque mais difícil?
> Porque não é "mais difícil", é **mais lento**. `curioso` dura 3 segundos e tem 10 balas de velocidade 1; `irritado` dura 5 segundos e cospe uma bala a cada 10 frames. A leitura emocional continua certa: o gato irritado é uma tempestade, o curioso é um cerco preguiçoso. Dificuldade em bullet hell é **densidade × tempo**, não velocidade sozinha.

**Teste os três.** Entre na luta, olhe as Patadas. Use `Chamar` e apanhe. Use `Ignorar` e veja o cerco. Esse é o momento em que o inimigo deixa de ser uma tabela e vira um personagem.

---

## Passo 8 — Acabamento

### O gato reage a apanhar

Adicione na ficha do inimigo — um gato que apanha para de brincar:

```gml
    ev_hurt = method(self, function() {
        if hp <= max_hp * 0.4 && humor != "irritado" {
            humor = "irritado"
            enc_enemy_set_tired(slot, true)
        }
    })
```

`enc_enemy_set_tired` marca o inimigo como **TIRED** — estado que magias de misericórdia (como as que poupam inimigos cansados) sabem usar. Note que aqui `method(self, ...)` de novo, porque mexemos em `hp` e `humor` do próprio struct.

> [!warning] `ev_hurt` roda **antes** do dano ser aplicado
> Olhe a ordem em `scripts/enc_scripts/enc_scripts.gml:31` — o hook é chamado, e só depois vem o `enemy_struct.hp -= hurt`. Ou seja, o `hp` que você lê lá dentro ainda é o de **antes** deste golpe, e o gato só fica irritado no golpe *seguinte* ao que cruzou os 40%. Para um "ele percebe que está apanhando" isso é ótimo (dá um beat de atraso, parece reação). Se você precisar do valor exato pós-dano, use `ev_post_turn`.
>
> E `ev_hurt` é chamado **sem argumentos** (`enemy_struct.ev_hurt()`). Se você escrever `function(dmg)`, `dmg` chega `undefined`.

### Recompensa por grazar

Cada bala dá TP ao passar rente à alma. O padrão é `graze = 2`; nas Patadas, que são largas e lentas, vale aumentar pra convidar o jogador a arriscar:

```gml
                DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                    speed: 3,
                    direction: (_lado == 1 ? 180 : 0),
                    att: 4,
                    graze: 4,          // dobro de TP: as garras convidam a passar perto
                    time_points: 8     // e encurtam mais o turno
                })
```

> [!info] `graze` não é um raio
> É a **quantidade de TP** que a bala concede. O tamanho da zona vem do sprite do `o_enc_soul_grazer` (e cresce com itens tipo `item_a_pink_ribbon`). E só balas **`SOLID`** dão graze — azuis e laranjas não valem nada de TP.

### Balanceamento: os números que importam

| Se o teste mostrou… | Mexa em… |
|---|---|
| morre rápido demais | `att` das balas (é `5*att`, então 4 → 3 já tira 5 de dano) |
| turno arrastado | `timer_end` (30 frames = 1s) |
| impossível de desviar | espaçamento das balas, não a velocidade |
| jogador nunca ganha TP | balas passando longe demais — aproxime o padrão da alma |
| luta longa demais | `hp` do inimigo, ou dê mais MERCY por ACT |

---

## Passo 9 — Colocar o gato no mundo

Só agora vale mexer em room. Há três formas de iniciar a luta, e cada uma tem suas pegadinhas.

### A. Pelo ator no mapa (o jeito canônico)

Arraste um **`o_actor_e`** para dentro da room, clique nele e, nas *Variable Definitions* do inspetor, preencha o campo **`encounter`** com:

```gml
new rpg_enc_set_sonso()
```

Encostar nele começa a luta. Outras variáveis úteis no mesmo painel: `enable_chasing`, `chase_spd`, `chase_dist` (perseguição), `idle_path` (patrulha por um asset Path) e `sprite_facing_dir`.

Bônus dessa forma: o ator que já está na room **é reaproveitado** como o inimigo da batalha (`o_enc_anim/Alarm_4.gml` procura um `actor_find` antes de criar um novo), então a transição do overworld pra luta fica contínua.

### B. Por trigger — uma área da room que inicia a luta

Arraste um **`o_trigger`** para a room e escreva no *Instance Creation Code* dele:

```gml
trigger_code = function() {
    enc_start(new rpg_enc_set_sonso())
}

trigger_exit_code = function() {
    triggered = false     // rearma o trigger quando o jogador sai da área
}
```

O código acima é a parte fácil. O que costuma fazer o trigger "não funcionar" são **três detalhes de configuração**, nenhum deles de GML:

**1. Estique a instância.** `spr_trigger` tem **20×20 px**, com origem no canto superior esquerdo, e `o_trigger` é `visible: false` — ou seja, você colocou um quadradinho invisível que o jogador contorna sem perceber. Os triggers da própria engine são todos esticados: em `room_ex_church` eles usam `scaleX` entre 5 e 7 e `scaleY` 2, o que dá 100–140 × 40 px. Puxe as alças da instância no editor de room até cobrir a passagem inteira.

**2. `o_trigger` dispara uma vez só.** O evento de entrada faz `triggered = true` e **nada na engine devolve isso pra `false`** — o evento de saída (`Other_11.gml`) só mexe em `trigger_exit`. Daí o `trigger_exit_code` do exemplo. Isso morde especialmente numa batalha: quando a luta acaba, a party volta pra posição que tinha quando começou — **em cima do trigger**. Sem o rearme, ele nunca mais dispara até a sala recarregar. O idioma vem da própria engine, em `rooms/room_ex_church/InstanceCreationCode_inst_2B13ACD5.gml:13`.

**3. O jogador precisa estar no controle.** Com `controlled_activation = true` (o default), o Step só dispara se `get_leader()._checkmove()` for verdadeiro (`objects/o_trigger/Step_0.gml:4`), o que exige `moveable_console`, `moveable_dialogue`, `moveable_battle` e companhia — todos verdadeiros (`objects/o_actor/Create_0.gml:197`). Na prática: **com o console aberto (`TAB`), nenhum trigger dispara.** Se você quiser um trigger que funcione mesmo fora do controle (bordas de sala, por exemplo), ponha `controlled_activation = false` no Creation Code.

> [!tip] Diagnóstico em 30 segundos
> Ponha um `show_debug_message(">>> TRIGGER DISPAROU")` como primeira linha do `trigger_code`. Se a mensagem **não** aparece na janela *Output* ao andar por cima, o problema é colisão (item 1) ou controle (item 3) — e não o seu código de batalha.

> [!info] Quando NÃO rearmar
> Se o encontro é único — o gato foi derrotado e não deve voltar — é só omitir o `trigger_exit_code`. One-shot já é o comportamento padrão do `o_trigger`.

### C. Por código, de qualquer lugar

```gml
enc_start(new rpg_enc_set_sonso())

// exatamente idêntico a:
new rpg_enc_set_sonso()._start()
```

`_start()` é só açúcar sintático: o método chama `enc_start(self)` (`scripts/enc_scripts/enc_scripts.gml:157`). Use o que ficar mais legível no seu contexto.

---

## O que testar antes de dar por pronto

- **Dá pra zerar sem tomar dano, depois que você entendeu o padrão?** Se não, está denso demais pra um inimigo de começo.
- **O primeiro segundo dá tempo de reação?** Nenhuma bala deve nascer em cima da alma.
- **Dá pra grazar?** Se as balas passam sempre longe, o jogador não ganha TP e as magias ficam mortas.
- **A parede azul é mesmo impossível de desviar?** Se der pra fugir dela, o jogador nunca aprende a regra do azul.
- **O caminho pacífico é mais rápido que o violento?** No Sonso: 2 rodadas ignorando vs. 3 rodadas batendo. Se matar for sempre mais rápido, ninguém vai poupar.
- **Dá pra descobrir sozinho que `Chamar` é a armadilha?** O texto do `Checar` diz "detesta ser chamado" — essa é a pista honesta. Enigma sem pista é só frustração.

---

## Erros comuns (e o sintoma exato)

| Sintoma | Causa |
|---|---|
| `spr_xxx not defined` ao compilar | asset que não existe — confira o nome no Asset Browser |
| O encontro não aparece no `encounter_select` | o arquivo não compilou; veja a janela **Output** |
| A batalha trava e nunca sai do turno | faltou `event_inherited()` no `Step_0.gml` do turn_object |
| Balas da rodada passada aparecem na próxima | faltou `instance_destroy(o_enc_bullet)` no `Destroy_0.gml` |
| Barra de HP errada | escreveu `maxhp` em vez de `max_hp` |
| ACT aparece mas não faz nada | usou `func:` em vez de `exec:` |
| Texto do ACT abre a caixa do overworld | usou `dialogue_start()` em vez de `encounter_scene_dialogue()` |
| `humor` sempre volta pro inicial | você criou um `enemy()` novo a cada rodada, ou está lendo uma cópia em vez de `o_enc.encounter_data.enemies[slot]` |
| O turno ignora o humor | definiu `pattern` depois do User Event 2, e o `??=` do pai já tinha preenchido |
| Bala azul não machuca ninguém | é o comportamento certo: `BLUE` só acerta quem está **se movendo** |
| Crash ao desenhar a barra de MERCY | `can_spare` foi escrito como função; tem que ser bool |
| Campo que você escreveu é ignorado | nome errado — structs em GML aceitam qualquer campo sem reclamar |
| O trigger não inicia a luta | a instância está no tamanho original (20×20) — estique com `scaleX`/`scaleY` no editor de room |
| O trigger funcionou uma vez e nunca mais | `triggered` nunca volta pra `false` sozinho; zere no `trigger_exit_code` |
| Nenhum trigger dispara enquanto você testa | o console (`TAB`) está aberto — `_checkmove()` fica falso e o trigger não ativa |

---

## Código completo

### `scripts/rpg_enc_enemies/rpg_enc_enemies.gml`

```gml
function rpg_enemy_sonso() : enemy() constructor {
    name = "Sonso"
    obj  = o_actor_e

    // stats
    hp      = 60
    max_hp  = 60
    attack  = 4
    defense = 1
    carrying_money = 12

    // mercy
    can_spare     = true
    no_mercy_text = "* Mas o SONSO ainda não decidiu se gosta de você."

    // sprites
    s_idle  = spr_ex_e_tasque
    s_hurt  = spr_ex_e_tasque_hurt
    s_spare = spr_ex_e_tasque_spared

    turn_object = o_turn_sonso

    // --- estado próprio ---
    humor    = "sonso"     // "sonso" | "irritado" | "curioso"
    chamados = 0

    dialogue = method(self, function() {
        switch humor {
            case "irritado":
                return "* O Sonso bufa. As orelhas estão pra trás."

            case "curioso":
                return "* O Sonso finge olhar pro outro lado."

            default:
                if o_enc.turn_count == 0
                    return "* Um gato te encara. Ele não parece impressionado."

                return choose(
                    "* O Sonso lambe a pata.",
                    "* O Sonso boceja.",
                    "* O Sonso não faz nada. De propósito."
                )
        }
    })

    ev_hurt = method(self, function() {
        if hp <= max_hp * 0.4 && humor != "irritado" {
            humor = "irritado"
            enc_enemy_set_tired(slot, true)
        }
    })

    acts = [
        {
            name: "Checar",
            desc: "Análise inútil",
            party: [],
            exec: function(slot, user) {
                encounter_scene_dialogue(
                    "* SONSO - ATK 4 DEF 1{br}{resetx}"
                  + "* Gato de rua. Decide sozinho de quem ele gosta.{br}{resetx}"
                  + "* Detesta ser chamado."
                )
            }
        },
        {
            name: "Chamar",
            desc: "Psiu, psiu, psiu",
            party: [],
            exec: function(slot, user) {
                var me = o_enc.encounter_data.enemies[slot]
                me.chamados ++
                me.humor = "irritado"

                audio_play(snd_ui_cant_select)

                if me.chamados == 1
                    encounter_scene_dialogue("* " + party_getname(user) + " chamou o Sonso.{br}{resetx}* Ele virou as costas.")
                else
                    encounter_scene_dialogue("* " + party_getname(user) + " chamou de novo.{br}{resetx}* Agora ele está OFENDIDO.")
            }
        },
        {
            name: "Ignorar",
            desc: "Olhar fixamente para qualquer outra coisa",
            party: [],
            exec: function(slot, user) {
                var me = o_enc.encounter_data.enemies[slot]
                me.humor = "curioso"

                enc_enemy_add_spare(slot, 50)

                encounter_scene_dialogue("* " + party_getname(user) + " olhou fixamente para o nada.{br}{resetx}* O Sonso deu um passo na sua direção.")
            }
        }
    ]
}
```

### `scripts/rpg_enc_sets/rpg_enc_sets.gml`

```gml
function rpg_enc_set_sonso() : enc_set() constructor {
    debug_name = "sonso"

    enemies = [ new rpg_enemy_sonso() ]

    flavor = function() {
        if o_enc.turn_count == 0
            return "* Um gato bloqueia a passagem. Tecnicamente."

        switch o_enc.encounter_data.enemies[0].humor {
            case "irritado": return "* O ar está tenso. E peludo."
            case "curioso":  return "* O Sonso está mais perto do que estava."
            default:         return "* Cheiro de telhado quente."
        }
    }

    enemies_pos = [ [0, 0, true] ]
    bgm = mus_battle
}
```

### `o_turn_sonso` (Parent: `o_turn`)

```gml
// ---------- Create_0.gml ----------
event_inherited()

_lado = choose(-1, 1)
```

```gml
// ---------- Other_10.gml — User Event 0 (init) ----------
event_inherited()
__support_init_default()

pattern = enemy_struct.humor

if !am_support {
    switch pattern {
        case "irritado": timer_end = 150 break
        case "curioso":  timer_end = 90  break
        default:         timer_end = 120 break
    }
}
```

```gml
// ---------- Step_0.gml ----------
event_inherited()

if pattern == "sonso" {
    // PATADAS — três garras paralelas, alternando de lado
    if timer % 30 == 0 && timer > 0 && timer < timer_end - 30 {
        _lado *= -1
        var _falha = irandom_range(-20, 20)

        for (var i = -1; i <= 1; i ++) {
            instance_create(o_enc_bullet,
                o_enc_box.x + 80 * _lado,
                o_enc_box.y + _falha + i * 26,
                DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                    speed: 3,
                    direction: (_lado == 1 ? 180 : 0),
                    att: 4,
                    graze: 4,
                    time_points: 8
                })
        }
    }
}
else if pattern == "irritado" {
    // BUFADA — chuvisco rápido...
    if timer % 10 == 0 && timer > 0 && timer < timer_end - 50 {
        instance_create(o_enc_bullet,
            o_enc_box.x + irandom_range(-32, 32),
            o_enc_box.y - 60,
            DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                speed: 4, direction: 270, att: 4
            })
    }

    // ...e o BOTE: parede azul, impossível de desviar. Solte o direcional.
    if timer == timer_end - 45 {
        audio_play(snd_spawn_attack)

        instance_create(o_enc_bullet,
            o_enc_box.x - 100, o_enc_box.y,
            DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                color: BULLET_COLOR.BLUE,
                speed: 4, direction: 0, att: 5,
                image_xscale: 1.5, image_yscale: 6
            })
    }
}
else if pattern == "curioso" {
    // RONRONAR — cerco laranja fechando devagar. Não pare de andar.
    if timer == 10 {
        for (var i = 0; i < 10; i ++) {
            var _ang = i * 36

            instance_create(o_enc_bullet,
                o_enc_box.x + lengthdir_x(90, _ang),
                o_enc_box.y + lengthdir_y(90, _ang),
                DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                    color: BULLET_COLOR.ORANGE,
                    speed: 1, direction: _ang + 180,
                    att: 3
                })
        }
    }
}

__support_destroy_check()
```

```gml
// ---------- Destroy_0.gml ----------
event_inherited()               // devolve o inimigo ao sprite de idle
instance_destroy(o_enc_bullet)  // e recolhe as balas órfãs
```

---

## Para levar pro seu próximo inimigo

O Sonso é um molde. Trocando o tema, a estrutura se repete:

1. **Escolha um comportamento humano**, não um monstro. Orgulhoso, medroso, tagarela, sonolento, carente.
2. **Ache o botão que parece certo e está errado.** É isso que transforma o menu em enigma.
3. **Guarde o humor num campo do `enemy()`** e faça o `dialogue`, o `flavor` e o `pattern` lerem ele. Uma variável, três canais de comunicação.
4. **Use a cor da bala como gramática**: `SOLID` = desvie, `BLUE` = pare, `ORANGE` = ande. Uma bala azul pequena não ensina nada; uma parede azul ensina na primeira vez.
5. **Faça o caminho pacífico ser o mais rápido.** Se matar for mais eficiente, o jogador vai matar — e a sua escrita toda vai pro lixo.

---

*Escrito e verificado contra o projeto: `enc_enemies.gml`, `enc_sets.gml`, `enc_scripts.gml`, `enc_actions.gml`, `party_hp.gml`, `party_get.gml`, `custom.gml`, `o_enc`, `o_enc_anim`, `o_enc_bullet`, `o_enc_soul`, `o_turn`, `o_turn_default`, `o_actor_e` e os sprites `spr_ex_e_tasque*`.*
