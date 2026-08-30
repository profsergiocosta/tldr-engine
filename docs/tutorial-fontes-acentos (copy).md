---
title: Acentos em português na tlDR Engine
tags:
  - tldr-engine
  - gamemaker
  - fontes
  - linux
---

# Tutorial: fazendo os acentos aparecerem

> A tlDR Engine, recém-clonada, não desenha `á`, `ã`, `ç`, `é`, `õ`. O texto aparece com buracos e nenhum erro é mostrado. Este guia resolve isso do começo ao fim.
>
> São **sete passos**, cada um com um jeito de verificar se funcionou. Você precisa baixar **uma** fonte, e o processo inteiro leva uns 20 minutos.
>
> Um aviso que economiza tempo: a engine usa **três fontes de texto diferentes** conforme o contexto — placa, balão de inimigo e menu não são a mesma coisa. O passo 4 explica como saber qual é qual.
>
> Escrito para **Linux Mint**. Os passos dentro do GameMaker valem em qualquer sistema; só a instalação da fonte muda.

---

## O problema, em um parágrafo

As fontes da engine são **bitmap fonts**: cada letra é um recorte de uma imagem pronta (`fonts/font_main/font_main.png`), e o arquivo `.yy` guarda a tabela de quais caracteres foram desenhados. Essa tabela cobre só ASCII — do 32 ao 127:

```json
"ranges":[
    {"lower":32,"upper":127,},
    {"lower":9647,"upper":9647,},
]
```

`á` é 225. `ç` é 231. `ã` é 227. Todos acima de 127, portanto **não existem no atlas**. O GameMaker não tem o que desenhar e não desenha nada — sem erro, sem aviso, sem log.

Consertar significa: **regerar cada fonte incluindo os caracteres acentuados**. Para isso o GameMaker precisa da fonte original instalada no seu sistema, porque o projeto não guarda nenhum arquivo `.ttf`.

> [!info] Isso não tem a ver com UTF-8
> O seu `.gml` está certo, o encoding está certo, o GameMaker leu a string certa. O buraco acontece só na hora de desenhar.

---

## O que você vai precisar

**Uma fonte: `8bitoperator JVE`**, de Jayvee Enaguas (GrafxKid). É uma pixel font gratuita, e ela cobre o português inteiro — os 28 caracteres acentuados estão todos lá.

Procure pelo nome e baixe o `.ttf`. Prefira a página do próprio autor quando encontrar; sites agregadores de fonte costumam ser re-uploads.

> [!warning] Sobre as outras fontes do projeto
> O projeto referencia seis fontes de origem diferentes, e nem todas são obteníveis — a do diálogo, chamada `Monospaced JVE` no `.yy`, não está disponível em lugar nenhum. **Você não precisa dela.** O passo 4 mostra como usar a `8bitoperator` no lugar, e o passo 5 recupera o espaçamento original. Não perca tempo procurando.

---

## Passo 1 — Crie uma branch

Você vai mexer em assets binários (`.png` + `.yy` de fonte). Um erro aqui suja vários arquivos de uma vez, e o jeito civilizado de desfazer é o git:

```bash
cd ~/GameMakerProjects/tldr-engine
git switch -c fontes
```

**Como verificar:** `git status` deve estar limpo, e `git branch --show-current` deve dizer `fontes`.

---

## Passo 2 — Monte uma sala de teste

Não teste no meio do seu jogo. Uma sala mínima abre em dois segundos e isola a variável.

1. No GameMaker: **Create → Room**, nome `RoomTeste`.
2. Arraste três objetos para dentro dela:
   - **`o_dev_world`** — o controlador do jogo. Sem ele nada funciona.
   - **`o_dev_playermarker`** — onde o jogador nasce.
   - **`o_ow_sign`** — a placa que vamos ler.
3. Clique na placa e, no **Instance Creation Code**, escreva:

```gml
text = "{col(y)}* Bem-vindo Sérgio, Bonitão.{col(w)}{p}{e}"
```

Essa frase tem duas famílias de acento: `é` (agudo, código 233) e `ã` (til, código 227). Se as duas aparecerem, o resto vem junto.

4. Rode o jogo. Se a `RoomTeste` não for a primeira sala, abra o console com **`TAB`**, digite `room_select` e escolha ela.
5. Leia a placa.

**O que você deve ver agora (o "antes"):**

```
* Bem-vindo Srgio, Bonito.
```

Os acentos simplesmente desaparecem, e as letras que os carregavam vão junto. **Anote isso.** É contra esse resultado que você vai comparar tudo daqui pra frente.

---

## Passo 3 — Instale a fonte no sistema

### Instale

**Pelo gerenciador de arquivos:** clique duplo no `.ttf` → abre o visualizador de fontes → botão **Instalar**.

**Pelo terminal**, mais confiável quando são várias:

```bash
mkdir -p ~/.local/share/fonts
cp ~/Downloads/8bitoperator_jve.ttf ~/.local/share/fonts/
fc-cache -f
```

### Verifique que o sistema enxerga

```bash
fc-list : family | grep -i "8bitoperator"
```

Tem que sair `8bitoperator JVE`. **Esse nome importa:** é exatamente o que você vai selecionar dentro do GameMaker.

### Verifique que ela tem os acentos

```bash
fc-list ":lang=pt" family | grep -i "8bitoperator"
```

Se o nome aparecer, a fonte cobre o português. (Um verificador mais minucioso está no fim deste guia, para quando você testar outras fontes.)

### Reinicie o GameMaker

> [!warning] Este passo não é opcional
> O IDE monta a lista de fontes do sistema **ao iniciar**. Se ele estava aberto quando você instalou, continua sem enxergar a fonte — e o pior é que ele não avisa: gera o bitmap a partir de uma fonte substituta qualquer, e o seu pixel art vira uma fonte lisa e maior.

---

## Passo 4 — Descubra qual fonte o seu texto usa, e conserte

### São três fontes de texto, não uma

Este é o ponto que mais custa tempo. A engine não desenha todo texto com a mesma fonte — ela escolhe conforme o contexto, e **consertar o asset errado não muda nada na tela**:

| O texto | Fonte usada | Asset |
|---|---|---|
| Placa, diálogo de overworld, cutscene, texto de ACT | `loc_font("text")` | **`font_main_mono`** |
| **Balão de fala do inimigo, dentro da batalha** | `loc_font("enc")` | **`font_dotumche`** |
| Menus, console, nome do inimigo, HP/TP, gameover | `loc_font("main")` | **`font_main`** |

O mapa de qual chave aponta para qual asset está em `datafiles/loc/fonts.json`.

**A placa da sua sala de teste** percorre este caminho:

```
o_ow_sign → dialogue_start()            objects/o_ow_sign/Other_10.gml:1
          → o_ui_dialogue
          → text_typer_create()         objects/o_ui_dialogue/Other_10.gml:15
          → o_text_typer
                font = loc_font("text")     objects/o_text_typer/Create_0.gml:5
          → fonts.json:  "font_text" → "font_main_mono"
```

**O balão do inimigo na batalha desvia no meio do caminho.** Ele passa pelo mesmo `o_text_typer`, mas com um *preset* que troca a fonte:

```
enemy.dialogue → actor_dialogue_create()          scripts/misc/misc.gml:313
               → o_ui_actordialogue
                     preset = "{preset(enemy_text)}"    Create_0.gml:7
               → o_text_typer, ao processar o preset:
                     font = loc_font("enc")             Other_10.gml:98
               → fonts.json:  "font_enc" → "font_dotumche"
```

Por isso é perfeitamente possível consertar a placa e, ao entrar numa batalha, o inimigo continuar falando sem acento. **São assets diferentes.**

> [!info] Existem outros presets
> O mesmo mecanismo vale para `{preset(god_text)}` e `{preset(light_world)}`, definidos em `objects/o_text_typer/Other_10.gml:96`. Se um texto seu aparecer sem acento mesmo depois de tudo, procure um `{preset(...)}` no começo dele.

Este passo conserta a **`font_main_mono`** — a fonte da placa. O passo 7 cuida das outras duas.

### Conserte

1. Abra **`font_main_mono`** no Asset Browser.
2. No campo **Font**, troque `Monospaced JVE` por **`8bitoperator JVE`**.
3. Na seção **Character Range**, clique em **Add** e preencha *lower* = **192**, *upper* = **255**. Isso cobre `À-ÿ` inteiro, que são todos os acentos do português. (Se quiser `º ª « » ¿` também, use 160 em vez de 192.)
4. **Force a regeneração:** o GameMaker só redesenha o bitmap quando alguma coisa muda. Mexa no campo **Size** de `12` para `13` e de volta para `12`.
5. **Ctrl+S.**

**Como verificar:** olhe o preview da fonte, ali mesmo no editor.

| O preview mostra | Significa |
|---|---|
| pixel art, com `À Á Â Ã Ç É` no meio | ✅ deu certo, siga para o passo 5 |
| pixel art, mas os acentos são espaços vazios | a fonte selecionada não tem esses glifos — reveja o passo 3 |
| letras lisas e maiores, sem pixel | o IDE não achou a fonte — feche o IDE, reabra, e refaça este passo |

Rode a `RoomTeste`. A placa já deve dizer **`Bem-vindo Sérgio, Bonitão.`** — mas com o espaçamento entre as letras diferente do resto do jogo. O passo 5 conserta isso.

---

## Passo 5 — Devolva o espaçamento original

O diálogo da tlDR Engine é **monoespaçado**: todo caractere ocupa exatamente 8 pixels, dê no que der. É isso que dá o ritmo de máquina de escrever ao texto.

A `8bitoperator` é proporcional — o `.` ocupa 3px, o `i` ocupa 7, o `W` ocupa 8. Ao regenerar a partir dela no passo 4, o diálogo herdou esse espaçamento variável. Este passo devolve o avanço fixo.

É seguro fazer isso porque nenhum desenho de letra da fonte passa de 8px de largura — não há risco de uma letra invadir a seguinte.

1. **Feche o projeto** no GameMaker. O IDE reescreve o `.yy` ao salvar, então ele não pode estar com o arquivo aberto.
2. No terminal, na raiz do projeto:

```bash
python3 - <<'EOF'
import re
p = 'fonts/font_main_mono/font_main_mono.yy'
s = open(p).read()
def fix(m):
    return f'{m.group(1)}"shift":{16 if int(m.group(2)) > 9000 else 8},'
s2, n = re.subn(r'("(\d+)":\{"character":\d+,"h":\d+,"offset":\d+,)"shift":\d+,', fix, s)
open(p, 'w').write(s2)
print("glifos com avanço fixado em 8:", n)
EOF
```

Deve imprimir algo como `glifos com avanço fixado em 8: 160`.

3. Reabra o projeto.

> [!warning] Este é sempre o último passo
> Se você voltar ao editor e mexer de novo em Size, Range ou Font, o IDE regenera o `.yy` do zero e o espaçamento volta a ser proporcional. Não é um erro — é só rodar o script outra vez. Acerte tudo no IDE primeiro, rode o script por último.

---

## Passo 6 — Teste

### Na tela

Rode a `RoomTeste` e leia a placa:

| | Resultado |
|---|---|
| **Antes de tudo** | `* Bem-vindo Srgio, Bonito.` |
| **Depois do passo 4** | `* Bem-vindo Sérgio, Bonitão.` com espaçamento apertado e irregular |
| **Depois do passo 5** | `* Bem-vindo Sérgio, Bonitão.` com o espaçamento regular da engine |

Compare o passo 5 com qualquer outro texto do jogo — o menu, uma placa do `room_ex_church` — para confirmar que o ritmo das letras ficou igual.

### Teste também o balão do inimigo

A placa e o balão de batalha usam **fontes diferentes** (passo 4), então um pode estar certo e o outro não. Para conferir os dois:

1. Abra o console (**`TAB`**) e digite `encounter_select`.
2. Escolha qualquer encontro cujo inimigo fale com acento.
3. Leia o balão que aparece sobre o inimigo no começo da rodada.

| O que acontece | Significa |
|---|---|
| Placa **e** balão com acento | ✅ `font_main_mono` e `font_dotumche` estão OK |
| Placa com acento, balão sem | falta consertar a `font_dotumche` — passo 7 |
| Balão com acento, placa sem | falta consertar a `font_main_mono` — passo 4 |
| Nome do inimigo, na lista, sem acento | falta consertar a `font_main` — passo 7 |

### No arquivo

Dá para conferir sem abrir o jogo. Cole na raiz do projeto:

```bash
python3 - <<'EOF'
import re, glob, os
for f in sorted(glob.glob('fonts/*/*.yy')):
    if f.endswith('.old.yy'): continue
    if os.path.basename(f)[:-3] != os.path.basename(os.path.dirname(f)): continue
    s = open(f).read()
    nome = re.search(r'"%Name":"([^"]*)"', s).group(1)
    ttf  = re.search(r'"fontName":"([^"]*)"', s).group(1)
    lh   = re.search(r'"lineHeight":(\d+)', s).group(1)
    rng  = re.findall(r'\{"lower":(\d+),"upper":(\d+),\}', s)
    ac   = re.search(r'"225":\{"character":225,"h":\d+,"offset":\d+,"shift":\d+,"w":(\d+)', s)
    est  = "sem a" if not ac else ("a VAZIO" if ac.group(1) == '0' else "a OK")
    print(f'{nome:20} {ttf:24} lineHeight={lh:<3} {est:8} ranges={rng}')
EOF
```

Como ler a saída, linha da `font_main_mono`:

| Coluna | Valor | Significa |
|---|---|---|
| estado | `a OK` | ✅ o glifo acentuado foi desenhado no atlas |
| estado | `sem a` | o range não foi ampliado, ou você não salvou — refaça o passo 4 |
| estado | `a VAZIO` | o range está certo, mas a fonte não tem esse glifo desenhado |
| `lineHeight` | `16` | ✅ veio da pixel font |
| `lineHeight` | subiu muito (ex. `22`) | o IDE usou uma fonte substituta — reinicie o IDE e refaça o passo 4 |
| `fontName` | qualquer valor | **não serve de prova**: o `.yy` sempre guarda o nome que você pediu, mesmo quando o IDE não achou a fonte |

> [!tip] Uma prova independente de que o problema era só o range
> Na mesma saída, repare nas fontes terminadas em **`_ja`** (as do japonês). Elas já vêm com range `32–65439` e aparecem como `a OK` num projeto recém-clonado, sem você fazer nada. Mesma engine, mesmo sistema — e nelas o acento sempre funcionou.

---

## Passo 7 — As outras duas fontes de texto

Os passos 4 e 5 consertaram a placa. Faltam as outras duas, e você vai notar a falta delas em lugares específicos:

| Asset | Você percebe que falta quando… | Fonte de origem | O que fazer |
|---|---|---|---|
| `font_main_mono` | uma placa ou cutscene come os acentos | indisponível | ✅ feito nos passos 4–5 |
| **`font_dotumche`** | **o inimigo fala sem acento na batalha** | DotumChe Pixel | não é obtenível — veja abaixo |
| `font_main` | o nome do inimigo ou um menu come os acentos | 8bitoperator JVE | você já tem a fonte |

### `font_main` — a mais fácil

A fonte de origem dela já é a que você instalou. Repita o passo 4 **sem trocar o campo Font** (ele já diz `8bitoperator JVE`) e **sem fazer o passo 5** — essa fonte é proporcional de propósito, é assim que a engine a usa.

### `font_dotumche` — o balão do inimigo

A `DotumChe Pixel` também não é encontrável, mesma situação da fonte do diálogo. Duas saídas:

**A. Aponte a chave para uma fonte que você já consertou.** Uma linha em `datafiles/loc/fonts.json`:

```json
"font_enc": {
    "en": "font_main",
    "ja": "font_dotumche_ja"
}
```

Resolve em dez segundos, e o balão passa a usar a mesma fonte dos menus.

**B. Regenere o asset a partir da `8bitoperator JVE`.** Abra `font_dotumche`, troque o campo **Font**, adicione o range 192–255, force a regeneração. Mais trabalho, mas mantém os assets separados — útil se depois você quiser dar uma cara própria a cada contexto.

### As demais

`font_lwmenu` (menu do Light World), `font_prophecy` (profecia do overworld) e `font_8bit` só importam se o seu jogo usar essas telas. O procedimento é sempre o mesmo: fonte de origem instalada → range 192–255 → forçar regeneração. Use o verificador de cmap do fim deste guia antes de adotar qualquer fonte nova.

> [!tip] Conserte sob demanda
> Não tente consertar as seis de uma vez. Jogue, ache um texto sem acento, descubra qual asset o desenha (passo 4), conserte, siga jogando.

---

## Se algo der errado

| Sintoma | Causa |
|---|---|
| Acento some, sem erro nenhum | o range da fonte é 32–127 — passo 4 |
| Consertei uma fonte e a placa não mudou | consertou o asset errado; o diálogo é `font_main_mono` — passo 4 |
| A fonte ficou lisa, grande e sem pixel | o IDE não achou a fonte e usou uma substituta — reinicie o IDE (passo 3) |
| Instalei a fonte e o IDE não a lista | ele monta a lista só ao iniciar — reinicie |
| Mudei o range e nada aconteceu | o bitmap não foi regenerado — mexa no Size para forçar, e salve |
| O acento saiu como espaço em branco | a fonte selecionada não tem o glifo — escolha outra |
| O diálogo ficou com espaçamento irregular | falta o passo 5 |
| Rodei o script e o espaçamento voltou ao irregular | o IDE regenerou o `.yy` depois; rode o script de novo, por último |
| O inimigo fala sem acento na batalha, mas a placa está certa | o balão usa `font_dotumche`, não `font_main_mono` — passo 7 |
| Um texto específico ignora tudo que você consertou | ele começa com um `{preset(...)}` que troca a fonte — passo 4 |
| Menus e diálogo estão com fontes diferentes | são assets diferentes — passo 7 |
| Depois do passo 5 as letras se sobrepõem | algum glifo é mais largo que 8px; confira com o script do passo 6 (coluna de largura) e use avanço maior no script |

### Como desfazer tudo

```bash
git checkout -- fonts/
rm -f fonts/*/*.old.png fonts/*/*.old.yy
```

O `rm` limpa os backups que o próprio GameMaker cria ao regenerar. Depois **feche e reabra o projeto**, para o IDE reler os bitmaps do disco.

---

## Ferramenta: a fonte tem os glifos que eu preciso?

Antes de adotar qualquer fonte nova, vale checar. Este script lê o `cmap` da TTF instalada e testa os 28 caracteres acentuados do português:

```bash
python3 - <<'EOF' "8bitoperator"
import struct, sys, subprocess
alvo = "áàâãçéêíóôõúüÁÀÂÃÇÉÊÍÓÔÕÚÜºª"
nome = sys.argv[1] if len(sys.argv) > 1 else "8bitoperator"
saida = subprocess.run(['fc-list'], capture_output=True, text=True).stdout
caminho = next((l.split(':')[0] for l in saida.splitlines() if nome.lower() in l.lower()), None)
if not caminho:
    print("fonte nao instalada:", nome); raise SystemExit

d = open(caminho, 'rb').read()
tabs = {}
for i in range(struct.unpack('>H', d[4:6])[0]):
    o = 12 + 16*i
    tabs[d[o:o+4].decode('latin1')] = struct.unpack('>II', d[o+8:o+16])
off = tabs['cmap'][0]
chars = set()
for i in range(struct.unpack('>H', d[off+2:off+4])[0]):
    _, _, so = struct.unpack('>HHI', d[off+4+8*i:off+12+8*i])
    t = off + so
    fmt = struct.unpack('>H', d[t:t+2])[0]
    if fmt == 4:
        segX2 = struct.unpack('>H', d[t+6:t+8])[0]; seg = segX2//2
        ends   = struct.unpack('>%dH' % seg, d[t+14:t+14+segX2])
        starts = struct.unpack('>%dH' % seg, d[t+16+segX2:t+16+2*segX2])
        for s, e in zip(starts, ends):
            if e != 0xFFFF: chars.update(range(s, e+1))
    elif fmt == 6:
        first, cnt = struct.unpack('>HH', d[t+6:t+10]); chars.update(range(first, first+cnt))
    elif fmt == 0:
        chars.update(c for c in range(256) if d[t+6+c])

falta = [c for c in alvo if ord(c) not in chars]
print(caminho)
print("glifos na fonte:", len(chars))
print("FALTA:", ''.join(falta) if falta else "(nenhum) — pode usar")
EOF
```

Troque o argumento para testar outra: `... EOF "crypt of tomorrow"`.

---

## Referência rápida

```
Acentos do português:   range 192–255      (ou 160–255 com º ª « » ¿)
á=225  ã=227  ç=231  é=233  í=237  ó=243  õ=245  ú=250

As TRES fontes de texto:
  placa / cutscene / ACT      loc_font("text")  -> font_main_mono
  balao do inimigo (batalha)  loc_font("enc")   -> font_dotumche
  menus / nomes / HP / TP     loc_font("main")  -> font_main
Mapa completo:          datafiles/loc/fonts.json

Ordem que funciona:
  instalar TTF → reiniciar IDE → trocar Font → ampliar range
  → forçar regen (Size 12→13→12) → salvar → fechar projeto → script de avanço

Desfazer:               git checkout -- fonts/
```

---

*Companheiro de `docs/tldr-engine-guia.md`. Verificado contra `o_ow_sign`, `o_ui_dialogue`, `o_text_typer`, `scripts/loc/loc.gml`, `datafiles/loc/fonts.json` e os assets em `fonts/`.*
