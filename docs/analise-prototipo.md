# Análise: BENTEVI — protótipo v0.1 (prólogo)

Fonte analisada: código-fonte (`scripts/`), capturas do teste automático e versão web · Objetivo: o que falta para o protótipo parecer o jogo final no celular · Data: 27/11/2026

## Resumo executivo

O protótipo v0.1 cumpre a pergunta principal: o laço fotografar → revelar → entrar em 1899 funciona de ponta a ponta, com salvamento, dicas e testes. Os três problemas mais importantes para o celular são: as áreas de toque não dão nenhum sinal sem mouse (caça ao pixel), o botão "voltar" do Android fecha o jogo e um item novo só aparece numa mensagem que some em 6 segundos. Falta também o que dá a "cara de jogo pronto": som, menu de opções, transições e mais conteúdo (hoje são 5–10 minutos).

## Notas (0–10)

| Dimensão | Nota | Justificativa curta |
| --- | --- | --- |
| Estrutura técnica | 8 | Regras separadas da interface (`logic.gd`/`content.gd`), salvamento automático, testes de regras e de ponta a ponta |
| Navegação | 6 | Rasa e clara, mas "Menu" joga direto para o título e o "voltar" do Android fecha o app |
| Completude funcional | 5 | Núcleo completo; sem som, sem configurações, sem seleção de capítulo, só o prólogo |
| Usabilidade | 6 | Dicas em 3 níveis e caderno ajudam; áreas de toque invisíveis no celular e mensagens que somem |
| Acessibilidade | 4 | Sem opção de texto grande, sem ajuda visual para achar objetos; texto claro sobre cena clara já foi corrigido |

## Estrutura

- **Stack:** Godot 4.5, GDScript, renderizador Compatibility; exporta para web (sem threads) e Android (APK sem Gradle).
- **Camadas:** `scripts/game/` (estado, conteúdo, regras, sem interface) → `scripts/main.gd` (liga interface e regras) → `scripts/ui/` (tema, cena, inventário, painéis).
- **Persistência:** `user://bentevi_save.json`, salvo a cada ação. Sem rede, sem permissões.

Mapa de telas (v0.1):

```
Título ─ Continuar / Novo jogo
  └─ Cena (bilheteria ⇄ plataforma) [1924]
       ├─ Cadeado (modal)        ├─ Zoom do relógio (modal)
       ├─ Álbum → Câmara escura → Cena [1899] → Sair da foto
       ├─ Caderno (modal)        ├─ Dica (mensagem)
       ├─ Menu → Título (perde o contexto)
       └─ Final do prólogo → Menu / Jogar de novo
```

## Funcionalidades

| Funcionalidade | Categoria | Status | Evidência |
| --- | --- | --- | --- |
| Fotografar, revelar e entrar em 1899 | Núcleo | Completa | `logic.gd` `take_photo`/`develop`/`enter_photo` |
| Inventário e uso de item | Núcleo | Parcial — item novo só em mensagem; sem tela de examinar | `inventory_bar.gd`, `logic.gd` `select_item` |
| Dicas do bem-te-vi | Suporte | Completa | `logic.gd` `next_hint` |
| Caderno automático | Suporte | Completa | `main.gd` `open_notebook` |
| Salvamento automático | Conta | Completa | `game_state.gd` `save_game` |
| Som e música | Atmosfera | Ausente | — |
| Configurações (volume, texto) | Configurações | Ausente | — |
| Seleção de capítulo, créditos | Menu | Ausente | — |
| 31 nomes dos mineiros (final secreto) | Conteúdo | Ausente | previsto no plano |
| Capítulo 1 | Conteúdo | Ausente | previsto no plano |

## Problemas de usabilidade

| # | Problema | Onde | Sev. | Esforço | Recomendação |
| --- | --- | --- | --- | --- | --- |
| 1 | Áreas de toque só mostram contorno com mouse; no celular o jogador não sabe o que é tocável | `theme_factory.gd` estilo `Hotspot` | 3 | Baixo | Feedback visual ao tocar + opção "Mostrar áreas de toque" nas configurações |
| 2 | Botão "voltar" do Android fecha o jogo sem aviso | `project.godot` (`quit_on_go_back` padrão = sim) | 3 | Baixo | Desligar e tratar: fecha o painel aberto ou abre o menu de pausa |
| 3 | Item novo aparece só numa mensagem de 6 s; fácil de perder | `logic.gd` (`say`) | 3 | Médio | Tela de item novo com imagem grande; tela de examinar ao tocar de novo no item |
| 4 | Relógio da arte marca 3h00, mas o código da mala é 317 | `assets/art/estacao_1924.jpg` | 3 | Baixo | Corrigir a arte (prompt enviado) |
| 5 | Sem som: o gênero depende de atmosfera | — | 3 | Médio | Ambiente por época, efeitos de cada ação, música do menu e controle de volume |
| 6 | "Menu" volta ao título e perde o contexto | `main.gd` `show_title` | 2 | Baixo | Menu de pausa: continuar, caderno, configurações, menu principal |
| 7 | Seleção do item em amarelo compete com o único acento da marca | `theme_factory.gd` `SelectedButton` | 2 | Baixo | Seleção em creme/sépia, com o item levemente elevado |
| 8 | Bilhete e chave continuam desenhados em 1899 depois de pegos | `scene_art.gd` | 2 | Baixo | Variantes de arte por estado (prompt enviado) |
| 9 | Troca de cena e entrada no passado sem transição | `main.gd` `refresh` | 2 | Baixo | Fade entre vistas; clarão + som ao entrar/sair da foto |
| 10 | Texto com tamanho fixo e fonte padrão do motor | `theme_factory.gd` | 2 | Baixo | Fonte serifada com cara de época e opção "texto grande" |
| 11 | Duração de 5–10 min não permite medir retenção | conteúdo | 2 | Alto | Capítulo 1 completo e nomes escondidos |

## Plano de ação

1. **Ganhos rápidos (nesta rodada):** itens 1, 2, 6, 7, 9, 10.
2. **Estruturais (nesta rodada):** itens 3, 5, 8 e menu com configurações, capítulos e créditos.
3. **Oportunidades:** Capítulo 1 completo, nomes dos mineiros como colecionáveis, verso dos documentos como pista.

## Limitações da análise

- Não foi testado em aparelho Android real; desempenho e toque foram avaliados pelo código e pela versão web.
- Leitor de tela: o Godot tem suporte limitado; não avaliado.
