# AGENTS.md — BMAMonitor

Plataforma IoT própria da BM Automach, fork da ThingsBoard **v4.3.1.8 (Apache 2.0)**, para hospedar clientes com marca própria.
Leia também `FORK-PLAN.md`. Este arquivo é o contrato de trabalho dos agentes.
Claude Code e Codex trabalham **de forma independente, sem orquestrador**, cada um na sua branch e na sua cópia de trabalho (`git worktree`), em diretórios diferentes do projeto. Um não edita o diretório do outro.

## Regras inegociáveis

1. **Nunca fazer merge de `master`, `lts-4.4` ou `release-4.4` do upstream.** A partir da 4.4 o código é BUSL 1.1 e contaminaria o fork. Correções de segurança só de `lts-4.3` / `release-4.3` (cherry-pick ou merge dessas branches).
2. Manter o `LICENSE` (Apache 2.0) e os cabeçalhos `SPDX`/copyright dos arquivos originais. Não remover.
3. "ThingsBoard" é marca registrada deles. O produto se chama **BMAMonitor**. Créditos como "baseado em ThingsBoard" são aceitáveis.
4. **Mudanças pequenas no núcleo.** Preferir configuração, variáveis de ambiente e arquivos novos a editar classes existentes. Cada edição no núcleo encarece o merge das correções de segurança.
5. Nenhum segredo, senha ou chave no repositório. Valores sensíveis entram por variável de ambiente.
6. Não fazer `push --force`. Não dar push em `main-apache` sem aprovação do Matheus.

## Divisão de diretórios

| Frente | Dono padrão | Diretórios |
|---|---|---|
| Interface, marca, idioma, tema | Claude Code | `ui-ngx/` |
| Backend, implantação, build, segurança | Codex | `application/`, `common/`, `dao/`, `rule-engine/`, `transport/`, `docker/`, `msa/`, `packaging/` |

Cada agente edita só o seu diretório. Se precisar de uma mudança no diretório do outro, registre em `docs/pedidos-entre-agentes.md` (arquivo novo, uma seção por pedido) em vez de editar. Documentação nova vai em `docs/`, em arquivos novos, para evitar conflito.

Arquivos compartilhados (`pom.xml` da raiz, `LICENSE`, `AGENTS.md`, `FORK-PLAN.md`) só mudam com combinado prévio.

## Fluxo de trabalho

- Uma branch por tema, a partir de `main-apache`: `codex/<tema>` para o Codex, `claude/<tema>` para o Claude.
- Commits pequenos, mensagem no formato `tipo: descrição` (`feat`, `fix`, `docs`, `chore`, `ui`).
- Antes de dar o trabalho por pronto: o build relevante precisa estar verde e o resultado registrado na descrição.

## Como compilar

- Backend: JDK 17 (alvo do projeto; o 21 também compila). `mvn clean install -DskipTests -Dlicense.skip=true`
- Front-end: `cd ui-ngx && yarn install && yarn build:prod` (usa Node e ~4 GB de heap; confirmar a versão de Node exigida pelo Angular 20).
- Servidor de desenvolvimento do front: `yarn start` em `ui-ngx/`.
- Stack completa: ver `docker/README.md` (`DATABASE=postgres`, `CACHE=valkey` no `.env`).

## Tarefas do Codex (backend e implantação)

**T1. Build de referência do backend.** Compilar com `mvn clean install -DskipTests -Dlicense.skip=true -Dskip.ui.build=true` (o build do front é do Claude Code) e registrar versão do JDK, tempo e qualquer erro. O ambiente em nuvem do Claude não alcança o Maven Central, então esta etapa nunca foi validada.

**T2. Desligar canais de saída para a ThingsBoard por padrão** (`application/src/main/resources/thingsboard.yml`):
- `updates.enabled`: `${UPDATES_ENABLED:true}` → padrão `false`. Hoje envia plataforma, versão e um identificador da instalação para `updates.thingsboard.io`.
- `community-grant.enabled`: `${COMMUNITY_GRANT_ENABLED:true}` → padrão `false`. Fluxo que conversa com `license.thingsboard.io` e roda um verificador assinado contra o banco.
- `iot-hub.base-url` (`https://iot-hub.thingsboard.io`): não há chave de desligar. Verificar se `IotHubRestClient` tolera URL vazia sem quebrar; se não tolerar, manter e documentar o bloqueio por firewall.
- Confirmar que nada quebra com `updates` desligado (`DefaultUpdateService`).

**T3. Stack de produção** (a partir de `docker/`):
- Compose com Postgres e Valkey, variáveis em arquivo `.env` fora do Git, volumes persistentes e backup agendado do banco.
- Proxy reverso com TLS na frente (Caddy ou nginx).
- Restringir o CORS: o `thingsboard.yml` avisa que o padrão aceita requisições de qualquer origem com credenciais.
- Firewall de saída bloqueando `*.thingsboard.io`.

**T4. Modelo de clientes.** Um **tenant por cliente**, com um **tenant profile** definindo limites, e usuários finais como *customers* do tenant. Verificar em `common/data/.../TenantProfile*` quais limites existem na 4.3.1.8 e documentar como criar tenant e profile (passo a passo e/ou script via REST API).

## Tarefas do Claude (interface)

- **T1a. Build de referência do front-end** (`cd ui-ngx && yarn install && yarn build:prod`): corrigir qualquer quebra do tema SCSS, do locale e dos dashboards, que nunca foram compilados.
- Remover os cards "Getting started" e "Documentation" dos painéis iniciais (`ui-ngx/src/assets/dashboard/*.json`), que apontam para a documentação da ThingsBoard.
- Revisar o pt_BR: ~465 chaves ausentes e ~450 idênticas ao inglês.
- Ajustes visuais do tema depois do build de referência.

## Já feito (branch `main-apache`)

- pt_BR como idioma de último recurso (`defaultUserLang`); inglês segue como reserva.
- Marca BMAMonitor: título, `appTitle`, logo, favicon, strings visíveis, nome do emissor no 2FA.
- Removidos: selo do GitHub, card "Version" do painel do administrador do sistema, item "IoT Hub" do menu.
- Tema industrial (grafite, cinza metálico, âmbar sóbrio) e fundo branco quente.
