# BENTEVI — O pássaro viu tudo

Protótipo jogável do **prólogo** de BENTEVI, um jogo de quebra-cabeças e suspense em estilo *escape room*, da Bentevi Apps.

> Minas Gerais, 1924. Lúcia Vaz, perita de seguros, chega a uma estação vazia. Toda foto que ela revela mostra o lugar como era em 14 de agosto de 1899 — e ela pode entrar nelas.

**Jogar no navegador:** https://jecal17-cmd.github.io/bentevi/ (funciona no celular, deitado)

## O que o protótipo testa

A pergunta deste protótipo é uma só: **revelar uma foto e entrar no passado gera o momento “aha”?**

- Navegação entre duas vistas (bilheteria e plataforma), com zoom em objetos.
- Inventário com seleção e uso de itens.
- Cadeado de 3 dígitos.
- Câmera com 3 chapas, **câmara escura** (minijogo de revelação) e entrada na foto de 1899.
- Mudanças no passado trazem itens para o presente (chave de 1899 → gaveta de 1924).
- Caderno que anota as pistas sozinho.
- Dicas do bem-te-vi em 3 níveis (empurrão → direção → solução).
- Salvamento automático a cada ação; final do prólogo.

Duração: 5 a 10 minutos.

## Como rodar no computador

1. Instale o [Godot 4.5](https://godotengine.org/download) (versão padrão, não a .NET).
2. Abra o Godot → **Importar** → escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar.

### Testes

```bash
# Regras do jogo (41 verificações)
godot --headless -s tests/run_tests.gd

# Joga o prólogo inteiro pela interface, sem tela
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
| Textos, itens, dicas, posição das áreas de toque | `scripts/game/content.gd` |
| Regras (o que cada objeto faz, código do cadeado) | `scripts/game/logic.gd` |
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
| `assets/art/items/<item>.png` | Ícones do inventário (fundo transparente) |

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

As imagens atuais foram geradas com IA para prototipagem. O plano do jogo prevê arte final desenhada à mão; a Steam exige declarar conteúdo gerado por IA que o jogador vê.

Código, história e personagens © Bentevi Apps. Todos os direitos reservados.
