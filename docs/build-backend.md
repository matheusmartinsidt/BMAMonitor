# Build de referência do backend

Data: 2026-11-03. Base: `main-apache` do BMAMonitor 4.3.1.8; branch de trabalho: `codex/backend`.

## Ambiente e comando

- JDK: Eclipse Temurin 17.0.21+9, Windows x64.
- Maven: 3.9.16.
- Comando: `mvn clean install -DskipTests -Dlicense.skip=true -Dskip.ui.build=true`.
- As ferramentas portáteis e o cache Maven ficaram fora do repositório. A execução autorizada para acesso às dependências usou `safe.directory` apenas no ambiente do processo, pois o usuário Windows dessa execução difere do proprietário do worktree criado no sandbox.

## Resultado

`BUILD SUCCESS` nos 59 módulos. Tempo informado pelo Maven: **15min18s**; tempo de parede: **15min23s**. A UI Angular não foi compilada por este comando. O módulo `msa/js-executor` instalou Node/Yarn em seu próprio `target/` para gerar seus executáveis; isso não modifica `ui-ngx/`.

## Falhas anteriores e resolução

1. Sem acesso à rede, a primeira tentativa não resolveu POMs do Maven Central (`Permission denied: getsockopt`). A execução com rede autorizada resolveu as dependências.
2. Uma tentativa passou os argumentos `-D` sem aspas no PowerShell e terminou com `Unknown lifecycle phase ".skip=true"`. Aspas nos argumentos corrigiram a invocação, sem mudar as opções do Maven.
3. A primeira compilação completa chegou a `application` e falhou no `git-commit-id-maven-plugin` 5.0.0 com `Could not get HEAD Ref`. O `.git` de um worktree é um arquivo de redirecionamento. A configuração local em `application/pom.xml` passou a usar Git nativo; `mvn -f application/pom.xml initialize` e depois o build completo passaram.

Os testes foram pulados conforme `-DskipTests`; as classes de teste ainda foram compiladas. O sucesso do build não valida a execução do servidor nem o front-end em Docker.
