# BENTEVI — O pássaro viu tudo

Protótipo jogável do **prólogo** e do **Capítulo 1** de BENTEVI, um jogo de quebra-cabeças e suspense em estilo *escape room*, da Bentevi Apps.

> Minas Gerais, 1924. Lúcia Vaz, perita de seguros, chega a uma estação vazia. Toda foto que ela revela mostra o lugar como era em 14 de agosto de 1899 — e ela pode entrar nelas.

**Jogar no navegador:** https://jecal17-cmd.github.io/bentevi/ (funciona no celular, deitado)

## O que tem nesta versão (0.4)

- Confirmação antes de apagar o jogo salvo; "voltar" do Android nos painéis do título volta ao título.
- APK com cerca de metade do tamanho (só arm64, texturas WebP); botões com altura mínima de toque de 48 dp.
- Nome dos mineiros escrito a giz; capa sem margem de papel.

## Versão 0.3

- 0.3.1: sem moldura nos objetos tocáveis da cena; texto da fita da coroa seguindo a curva; margens de papel cortadas das cenas para todas terem o mesmo enquadramento.

- Arte final do Capítulo 1 (salão, relógios e espelho em 1924 e 1899), zooms da coroa, do caixão e do pêndulo, carruagem e ícones de todos os itens.
- Áreas de toque refeitas sobre a arte nova; parede com cinco relógios (o quinto, "L.").

## Versão 0.2

- **Prólogo — A Estação** e **Capítulo 1 — O Velório**: 5 cenários, cada um em 1924 e em 1899, cerca de 25 quebra-cabeças. Duração estimada: 30 a 40 minutos na primeira vez.
- Câmera com chapas, **câmara escura** e entrada nas fotos de 1899; mudanças no passado alteram o presente.
- Quebra-cabeças variados: cadeados de 3 e 4 dígitos, número lido num espelho, acertar os ponteiros de um relógio, encaixar medalhas, acender velas para ter luz para fotografar.
- **Tela de item**: todo item novo aparece em tela cheia; toque duas vezes num item do inventário para examiná-lo. Documentos aparecem como papel e têm verso.
- **Nomes dos 31 mineiros** escondidos pelos cenários (8 nesta versão), registrados no caderno.
- **Som**: ambiente de 1924 e de 1899, música do menu e efeitos para cada ação.
- **Menus**: principal (continuar, novo jogo, capítulos, configurações, créditos), pausa, e configurações de volume, texto grande e "mostrar áreas de toque".
- Dicas do bem-te-vi em 3 níveis, caderno automático, salvamento a cada ação.
- Botão "voltar" do Android fecha o painel aberto ou abre a pausa, em vez de fechar o jogo.

## Como rodar no computador

1. Instale o [Godot 4.5](https://godotengine.org/download) (versão padrão, não a .NET).
2. Abra o Godot → **Importar** → escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar.

### Testes

```bash
# Regras do jogo (123 verificações)
godot --headless -s tests/run_tests.gd

# Joga o prólogo e o Capítulo 1 inteiros pela interface, sem tela
godot --headless -- --smoke
```

### Gerar a versão web

Instale os *export templates* do Godot 4.5 (menu Editor → Gerenciar modelos de exportação) e rode:

```bash
godot --headless --export-release "Web" build/web/index.html
```

A versão web usa o modo sem *threads*, então funciona em qualquer hospedagem estática (GitHub Pages, itch.io).

### Gerar o APK de teste (Android)

O APK é assinado com uma **chave de teste fixa**, para que cada nova versão instale por cima da anterior sem perder o progresso. A chave não fica neste repositório.

1. Aumente `version/code` (e, se quiser, `version/name`) no preset "Android" de `export_presets.cfg`.
2. Rode:

```bash
GODOT=/caminho/godot KEYSTORE=/caminho/bentevi-teste.keystore tools/build_android.sh
```

O arquivo sai em `build/android/bentevi-<versão>-v<código>.apk`. A exportação Android exige o Java 17+ e os *export templates* do Godot 4.5.

## Onde mexer

| Quero mudar… | Arquivo |
| --- | --- |
| Textos, itens, dicas, capítulos, mineiros | `scripts/game/content.gd` |
| Posição das áreas de toque, variantes de arte, efeitos | `scripts/game/hotspots.gd` |
| Regras (o que cada objeto faz, códigos) | `scripts/game/logic.gd`, `logic_prologo.gd`, `logic_cap1.gd` |
| Menus | `scripts/ui/menus.gd` |
| Sons (gerados por síntese) | `tools/gen_audio.py` → `assets/audio/` |
| Cores, fontes e estilo dos botões | `scripts/ui/theme_factory.gd` |
| Imagens | `assets/art/` |

### Trocar ou adicionar arte

O jogo procura as imagens pelo nome e usa a arte provisória (desenhada em código) quando não encontra:

| Arquivo | Onde aparece |
| --- | --- |
| `assets/art/<vista>_<ano>.jpg` | Fundo da cena (ex.: `estacao_1924.jpg`), 1920×1080 |
| `assets/art/relogio_zoom.jpg` | Zoom do relógio |
| `assets/art/capa.jpg` | Tela de título |
| `assets/art/bemtevi.png` | Botão de dica |
| `assets/art/items/<item>.png` | Ícones do inventário e tela de item (fundo transparente) |
| `assets/art/<nome>_zoom.jpg` | Zooms: `relogio`, `coroa`, `caixao`, `pendulo` |
| `assets/art/carruagem.jpg` | Fim do prólogo |
| `assets/art/estacao_1899_sem_bilhete.jpg` etc. | Variantes depois de pegar um item (`hotspots.gd`, `ART_VARIANTS`) |

Ao trocar um cenário, confira se os retângulos em `content.gd` continuam sobre os objetos certos.

## Estrutura

```
scripts/game/    estado da partida, conteúdo e regras (sem interface)
scripts/ui/      tema, cena, inventário e painéis (cadeado, câmara escura…)
scripts/main.gd  liga a interface às regras
tests/           testes das regras
docs/            briefing e backlog
```

## Sobre a arte

As imagens atuais foram geradas com IA para prototipagem. Onde ainda não há imagem (Capítulo 1), o jogo desenha uma arte provisória em código. Os sons são provisórios, gerados por síntese em `tools/gen_audio.py`. A fonte é a Crimson Text (SIL Open Font License, `assets/fonts/OFL.txt`). O plano do jogo prevê arte final desenhada à mão; a Steam exige declarar conteúdo gerado por IA que o jogador vê.

Código, história e personagens © Bentevi Apps. Todos os direitos reservados.
