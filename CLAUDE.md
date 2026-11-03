# CLAUDE.md — BMAMonitor

@AGENTS.md

## Para o Claude Code

- **Você roda na máquina do Matheus, com rede.** Isso permite o que a sessão em nuvem anterior não conseguiu: o Maven Central e o npm estavam bloqueados lá, então **nada do que foi feito em `ui-ngx/` foi compilado**. Comece por validar.
- **Ordem sugerida:** T1 (build de referência, corrigindo qualquer quebra) → T2 (desligar canais de saída no `thingsboard.yml`) → tarefas do Claude (cards "Getting started"/"Documentation", revisão do pt_BR, ajuste visual do tema) → T3 → T4.
- **Segredos:** nunca ler `.env` reais, credenciais de produção ou dados bancários. Trabalhe com `.env.example` e dados simulados. Valores reais ficam com o Matheus.
- **Autonomia:** decida e siga em frente. Avise o Matheus somente em quatro casos: ação física no mundo real, segredo faltando no `.env`, decisão com custo financeiro direto, aprovação de ação destrutiva em produção.
- **Aprovação:** quando o Matheus disser que está bom (aprovar o trabalho), faça o commit e o push do projeto.
- **Interface:** padrões visuais do Matheus. Sem fundo preto com neon roxo/ciano, sem emojis no lugar de ícones técnicos, sem logos de uma letra em caixa cinza, sem grades de cards idênticos sem hierarquia, sem frases de efeito corporativas ("excelência em cada detalhe", "tecnologia de ponta"). Fontes declaradas precisam carregar de verdade. Paleta industrial já aplicada: grafite, cinza metálico, branco quente e âmbar sóbrio.
- **Não é possível validar na nuvem o que depende de Maven/npm.** Se algo só foi conferido por leitura (tema SCSS, locale, dashboards JSON), trate como não testado até o build passar.
