# Plano do fork — plataforma IoT própria (base ThingsBoard v4.3.1.8, Apache 2.0)

## Regras do fork (valem para todos os agentes)

1. **Base**: tag `v4.3.1.8`. Licença Apache 2.0. Manter o arquivo `LICENSE` e os cabeçalhos de copyright dos arquivos originais.
2. **Nunca fazer merge de `master`, `lts-4.4` ou `release-4.4`.** A partir da 4.4 o código é BUSL 1.1 e contaminaria o fork. Correções de segurança entram só de `lts-4.3` / `release-4.3` (cherry-pick ou merge dessas branches).
3. **Marca**: o código pode ser rebrandizado, mas o nome e o logo "ThingsBoard" são marca registrada deles. O produto tem nome próprio; citar "baseado em ThingsBoard" nos créditos é o seguro.
4. **Mudanças pequenas no núcleo.** Preferir configuração, tema e arquivos novos a editar classes existentes. Cada edição no núcleo encarece o merge das correções de segurança.
5. Cada agente só mexe no seu diretório (tabela abaixo). Arquivos compartilhados (`pom.xml` da raiz, `LICENSE`, este plano) só mudam com combinado prévio.

## Divisão de trabalho

| Frente | Dono | Diretórios |
|---|---|---|
| Interface, marca, idioma | Claude | `ui-ngx/` |
| Backend, implantação, build | Codex | `application/`, `common/`, `dao/`, `rule-engine/`, `transport/`, `docker/`, `msa/`, `packaging/` |

## Etapas

**0. Preparar o fork (Matheus).** Fazer o fork no GitHub, criar uma branch a partir da tag `v4.3.1.8` (por exemplo `main-apache`) e torná-la a branch padrão. Adicionar o upstream como remoto para buscar `lts-4.3`.

**1. Build de referência (Codex ou máquina do Matheus).** Compilar o backend (`mvn clean install -DskipTests`, Java 17) e o front-end. Só com isso verde começamos a customizar. *Obs.: o ambiente em nuvem do Claude não alcança o Maven Central, então esta etapa não pôde ser validada lá.*

**2. Marca e idioma (Claude).**
- Trocar `ui-ngx/src/assets/logo_white.svg` e `logo_title_white.svg` (usados em `home.component.ts`, `logo.component.ts` e no dashboard).
- Título da aba em `ui-ngx/src/index.html` (hoje `<title>ThingsBoard</title>`).
- Cores e tema em `ui-ngx/src/theme.scss` e `theme-overwrites.scss`.
- Português do Brasil como idioma padrão (`locale.constant-pt_BR.json` já existe; revisar termos).

**3. Implantação (Codex).** Subir a stack a partir de `docker/` (há compose com Postgres, Kafka e Valkey), proxy reverso com TLS, backup do banco e variáveis de ambiente por ambiente.

**4. Modelo de clientes (Codex + Matheus).** Um **tenant por cliente**, com um **tenant profile** definindo limites (dispositivos, regras, armazenamento), e os usuários finais do cliente como *customers* dentro do tenant. Validar os campos de limite do tenant profile na versão 4.3.1.8 antes de montar planos comerciais.

**5. Depois.** Domínio e e-mails próprios, monitoramento, cobrança (fora do ThingsBoard) e avaliação de migrar para licença comercial da 4.4+ se o negócio pedir Reporting e integrações prontas.

## Pendências em aberto

- Nome do produto e identidade visual.
- Onde hospedar (VPS, nuvem) e quantos dispositivos por cliente se espera no começo.
