# Análise: BENTEVI — protótipo 0.3.1 (prólogo + Capítulo 1)

Fonte analisada: código-fonte (`scripts/`), 20 capturas do teste automático, APK 0.3.1 · Objetivo assumido: diagnóstico geral antes de seguir para o Capítulo 2 · Data: 27/11/2026

## Resumo executivo

O protótipo já tem cara de jogo: arte final em todas as cenas, som, menu completo, telas de item, 30–40 min de jogo e testes automáticos. Os três problemas mais importantes eram: "Novo jogo" e "Capítulos → Jogar" apagavam o jogo salvo sem perguntar; o "voltar" do Android em Configurações/Capítulos/Créditos abertos pelo título caía numa cena vazia; e o APK pesava 78 MB, quase tudo em biblioteca duplicada para celulares antigos. Os três foram corrigidos na 0.4.0.

## Notas (0–10)

| Dimensão | Nota | Justificativa curta |
| --- | --- | --- |
| Estrutura técnica | 8 | Regras separadas da interface, 124 testes de regra + passeio completo pela interface; `main.gd` (490 linhas) já pede divisão |
| Navegação | 8 | Rasa, pausa completa, voltar do Android tratado (agora também nos painéis do título) |
| Completude funcional | 7 | Prólogo e Capítulo 1 completos; zoom dos cinco relógios ainda desenhado em código |
| Usabilidade | 7 | Dicas em 3 níveis, caderno, telas de item; botões estavam abaixo de 48 dp |
| Acessibilidade | 6 | Texto grande e áreas de toque visíveis como opção; sem leitor de tela (limite do Godot) |

## Mapa de telas

```
Título ─ Continuar / Novo jogo (confirma se há jogo salvo) / Capítulos / Configurações / Créditos
  └─ Cena (vistas em anel, 1924 ⇄ 1899)
       ├─ Item novo / Examinar (documentos com verso)   ├─ Nome de mineiro
       ├─ Zoom (coroa, caixão, relógios, reflexo)        ├─ Cadeado · Acertar ponteiros
       ├─ Álbum → Câmara escura → dentro da foto → Sair da foto
       ├─ Caderno · Dica (bem-te-vi)
       ├─ Pausa → Continuar / Caderno / Configurações / Menu principal
       └─ Fim de capítulo → Menu / Seguir · Jogar de novo
```

## Funcionalidades

| Funcionalidade | Categoria | Status | Evidência |
| --- | --- | --- | --- |
| Fotografar → revelar → entrar em 1899 | Núcleo | Completa | `logic.gd` |
| Prólogo e Capítulo 1 (≈ 30–40 min) | Conteúdo | Completa | `logic_prologo.gd`, `logic_cap1.gd` |
| Telas de item, examinar, verso de documento | Núcleo | Completa | `item_panel.gd` |
| Nomes dos 31 mineiros (8 no protótipo) | Conteúdo | Completa — cartão era provisório (linhas) | `item_panel.gd` `_draw_placeholder` |
| Zoom dos cinco relógios | Conteúdo | Parcial — mostradores em código, destoam da arte | `zoom_panel.gd` `_draw_clocks` |
| Som, ambiente por época, música do menu | Atmosfera | Completa (sintetizado) | `tools/gen_audio.py` |
| Salvamento automático, capítulos, configurações | Sistema | Completa | `game_state.gd`, `menus.gd` |

## Problemas de usabilidade

| # | Problema | Onde | Sev. | Esforço | Status 0.4.0 |
| --- | --- | --- | --- | --- | --- |
| 1 | "Novo jogo" e "Capítulos → Jogar" apagam o jogo salvo sem confirmar | `menus.gd` `_on_title_choice` | 4 | Baixo | Corrigido: confirmação com o capítulo salvo |
| 2 | "Voltar" do Android em Configurações/Capítulos/Créditos abertos pelo título fecha o painel e mostra cena vazia | `main.gd` `on_back` | 3 | Baixo | Corrigido: volta ao título |
| 3 | APK de 78 MB (biblioteca armv7 duplicada + texturas sem compressão) | `export_presets.cfg`, `*.import` | 3 | Baixo | Corrigido: só arm64, texturas WebP 85% |
| 4 | Botões com 96 px de altura ≈ 38 dp (abaixo de 48 dp) | `theme_factory.gd` `button` | 2 | Baixo | Corrigido: mínimo 112 px |
| 5 | Cartão do nome do mineiro com imagem provisória | `item_panel.gd` | 2 | Baixo | Corrigido: nome a giz numa tábua |
| 6 | Zoom dos relógios desenhado em código destoa da arte | `zoom_panel.gd` | 2 | Médio | Prompt de arte enviado |
| 7 | Capa com margem de papel diferente das cenas | `capa.jpg` | 1 | Baixo | Corrigido |
| 8 | Caderno mistura capítulos numa lista única | `main.gd` `open_notebook` | 1 | Médio | Backlog |
| 9 | `main.gd` com ~490 linhas mistura HUD, modais e transições | `main.gd` | 1 | Médio | Backlog (antes do Capítulo 2) |

## Plano de ação

1. **Feito na 0.4.0:** itens 1–5 e 7.
2. **Próximo ciclo:** arte do zoom dos relógios (item 6); dividir `main.gd` em HUD e gerenciador de modais; caderno por capítulo.
3. **Oportunidades:** teste com 5 jogadores medindo tempo por enigma e uso de dicas; Capítulo 2 (Botica).

## Limitações da análise

- Sem aparelho real: tamanho de toque estimado para tela 1080 px de altura e ~400 ppi.
- Desempenho em celular simples e consumo de bateria não medidos.
- Leitor de tela não avaliado (suporte limitado no Godot).
