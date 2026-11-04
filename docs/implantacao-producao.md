# Implantação de produção inicial

Stack de um nó em `docker/production/compose.yaml`: BMAMonitor monolítico, PostgreSQL 16, Valkey 8.0, Caddy e backup periódico. A configuração antiga em `docker/` é uma stack de microserviços e não deve ser combinada com esta.

## Artefato do servidor

`docker/production/Dockerfile.server` exige `application/target/*-boot.jar` gerado com os recursos do front. O build de referência com `-Dskip.ui.build=true` valida o backend, mas pula o boot JAR. O front é compilado no Docker a partir dos arquivos da branch `claude/u1-dashboards-ptbr`; não é necessário instalar Node ou yarn no host. Depois que essa branch estiver integrada ao checkout, execute na raiz do repositório:

```sh
docker build -f ui-ngx/Dockerfile.build --target build -t bmamonitor-ui-build ui-ngx
docker build -f ui-ngx/Dockerfile.build --target dist --output type=local,dest=./ui-ngx/target/generated-resources/public ui-ngx
mvn package -pl ui-ngx,application -am -DskipTests -Dlicense.skip=true -Dskip.ui.build=true -Dpkg.skip.bootjar=false -Dpkg.skip.deb=true -Dpkg.skip.rpm=true -Dpkg.skip.zip=true
```

O segundo comando gera `ui-ngx/target/generated-resources/public`. O `ui-ngx/pom.xml` inclui `target/generated-resources` no JAR da UI, dependência de runtime de `application`; o terceiro comando empacota esse JAR e habilita somente o boot JAR. **Não use `mvn clean` depois de extrair o front**, pois ele apaga o diretório gerado. Esses comandos de integração ainda precisam de execução conjunta com a branch do Claude. O diretório gerado não deve ser commitado. Publique a imagem do fork como `BMAMONITOR_IMAGE`; não use uma imagem da ThingsBoard upstream para esta stack.

O comando de construção da imagem, após obter o boot JAR, é:

```sh
docker build -f docker/production/Dockerfile.server -t bmamonitor/server:4.3.1.8 .
```

Não coloque a stack em produção antes de verificar que a imagem contém o front e que o instalador do banco conclui.

## Configuração

Copie `docker/production/.env.example` para um arquivo **fora do checkout**, por exemplo `/etc/bmamonitor/production.env`, e substitua domínio, e-mail e senhas por valores reais. Restrinja a leitura do arquivo ao operador que executa Docker. Não use `docker/.env` da stack antiga nem comite o arquivo real.

No host de produção, aponte o DNS de `BMAMONITOR_DOMAIN` para o servidor e libere as portas TCP 80 e 443. Caddy obtém e renova o certificado TLS e encaminha para `server:8080`. O CORS do servidor aceita apenas `https://BMAMONITOR_DOMAIN` com credenciais; não use `*` em `TB_CORS_ALLOWED_ORIGIN_PATTERNS`.

Com o arquivo real preparado e a imagem disponível:

```sh
docker compose --env-file /etc/bmamonitor/production.env -f docker/production/compose.yaml config --quiet
docker compose --env-file /etc/bmamonitor/production.env -f docker/production/compose.yaml run --rm -e INSTALL_TB=true server
docker compose --env-file /etc/bmamonitor/production.env -f docker/production/compose.yaml up -d
```

Execute o instalador apenas na implantação inicial de um banco vazio. O acesso público é somente HTTPS pelo Caddy. PostgreSQL, Valkey e a porta HTTP interna do servidor não são publicados no host. MQTT e CoAP não são expostos por esta stack inicial; a telemetria HTTP passa pelo HTTPS do Caddy. A publicação desses protocolos exige uma configuração de TLS própria antes de abrir portas externas.

## Backup e recuperação

O serviço `backup` faz um `pg_dump` no formato customizado ao iniciar e depois a cada `BACKUP_INTERVAL_SECONDS` (padrão 24 horas). O arquivo parcial só recebe extensão `.dump` após sucesso. A retenção local padrão é 14 dias. Os dumps ficam no volume `backup_data`, separado de `postgres_data`. Copie os backups periodicamente para armazenamento fora do host e faça testes de restauração; um volume no mesmo host não protege contra perda do host.

Para conferir os arquivos:

```sh
docker compose --env-file /etc/bmamonitor/production.env -f docker/production/compose.yaml exec backup ls -lh /backups
```

Restauração é uma ação destrutiva no banco de destino. Faça-a apenas após aprovação, em uma janela controlada, com o servidor parado e usando `pg_restore` em um banco preparado. Não restaure por cima de dados de produção sem backup recente verificado.

## Saída de rede

O servidor, PostgreSQL, Valkey e backup estão somente na rede Docker `private` com `internal: true`. Essa regra bloqueia **toda saída à Internet** desses containers, incluindo `updates.thingsboard.io`, `license.thingsboard.io`, `iot-hub.thingsboard.io` e demais `*.thingsboard.io`; Caddy fica também na rede `edge` para emitir certificados. Esta política é mais restrita que uma lista DNS e evita falhas de bloqueio quando os endereços do domínio mudam.

Integrações que exigem chamadas externas do servidor, como webhooks ou SMTP, não funcionam nessa configuração. Antes de habilitá-las, desenhe uma saída controlada que continue negando `*.thingsboard.io` e teste a política no host. O Compose foi validado sintaticamente com `.env.example`; a política de rede e o TLS ainda exigem teste no host de produção.

## Validação local

Em 2026-11-03, `docker compose --env-file docker/production/.env.example -f docker/production/compose.yaml config --quiet` passou, o Caddyfile passou em `caddy validate`, e ambos os scripts passaram em `sh -n`. A imagem do servidor não foi construída porque o build de referência sem UI não gera `application/target/*-boot.jar`, e a branch `claude/u1-dashboards-ptbr` ainda não estava disponível no remoto deste checkout na última verificação. O arquivo `Dockerfile.server.dockerignore` limita o contexto de construção ao boot JAR e ao script de inicialização, sem enviar o checkout ou arquivos `.env` ao daemon Docker.
