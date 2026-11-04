# Build do front-end (ui-ngx)

Resultado da tarefa T1a, em 2026-11-03, na branch `claude/u1-dashboards-ptbr` (commit base `302c1bbd95`).

## Resultado

`yarn build:prod` passou sem erro de compilação. O SCSS do tema (`theme.scss`, `constants.scss`) e o locale pt_BR compilaram sem alteração. O bundle inicial tem 6,95 MB (1,15 MB transferido). Os únicos avisos são de peer dependency do `ngx-hm-carousel` (declara Angular 19, o projeto usa 20), que já vêm do upstream e não afetam o build.

## Versões

| Item | Versão |
|---|---|
| Node | 22.23.4 (imagem `node:22-bookworm-slim`; é a versão fixada em `ui-ngx/pom.xml`) |
| Yarn | 1.22.22 (o `yarn.lock` é do yarn v1) |
| Angular | 20.3.34 (CLI 20.3.41) |
| TypeScript | ~5.9.3 |

Um `yarn install` no Windows com Node 24.18.1 também concluiu, mas o build de referência é o do container, em Node 22.

## Como buildar (Docker)

Os comandos rodam dentro de `ui-ngx/`. Não é preciso instalar Node nem yarn no host. A imagem precisa do `git`, porque o `yarn install` busca uma dependência por repositório git.

Build de produção (cerca de 6 min; usa cache nas vezes seguintes):

```bash
docker build -f Dockerfile.build --target build -t bmamonitor-ui-build .
```

Copiar o resultado para o host, em `ui-ngx/target/generated-resources/public` (pasta gerada, ignorada pelo git):

```bash
docker build -f Dockerfile.build --target dist --output type=local,dest=./target/generated-resources/public .
```

Alternativa pelo compose (funciona, mas leva cerca de 22 min no Windows por causa da pasta montada):

```bash
docker compose -f docker-compose.build.yml run --rm build
```

Pré-visualização estática do build de produção, em `http://localhost:4200`, sem backend (mostra a tela de login e o tema; testado). Exige o resultado do build em `ui-ngx/target/generated-resources/public`:

```bash
docker compose -f docker-compose.build.yml up -d ui-preview
```

Dev server do Angular (`ui-dev`), com o backend do host em `BACKEND_URL` (padrão `http://host.docker.internal:8080`). **Não funcionou nesta máquina:** o container é encerrado por falta de memória (`OOMKilled`, código 137), mesmo com heap de 4 GB, porque o Docker Desktop tem só 6 GB. Para usá-lo é preciso aumentar a memória do Docker Desktop (Configurações, Resources) para uns 10 GB ou mais:

```bash
docker compose -f docker-compose.build.yml up ui-dev
```

Os serviços `build` e `ui-dev` dividem o volume `ui-node-modules` e não devem rodar ao mesmo tempo.

## Arquivos

Em `ui-ngx/`: `Dockerfile.build`, `docker-compose.build.yml`, `.dockerignore`, `proxy.conf.docker.js`, `nginx.preview.conf`. O `proxy.conf.js` original não foi alterado.
