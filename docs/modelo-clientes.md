# Modelo de clientes no BMAMonitor 4.3.1.8

## Estrutura

Crie **um tenant por cliente contratante da BM Automach**. Atribua a ele um
`TenantProfile` próprio ou um perfil compartilhado por plano. O perfil limita o
consumo agregado do tenant; seus limites não são independentes por customer.

Dentro do tenant, crie um `Customer` para cada grupo que precise enxergar apenas
os dispositivos, ativos e painéis atribuídos a ele. Uma pessoa que acessa esse
grupo é um `User` com `authority: "CUSTOMER_USER"`, ligado ao `tenantId` e ao
`customerId`. O `Customer` é a entidade de escopo, não a conta de login. Se um
cliente contratante precisar de vários grupos ou unidades com acesso separado,
crie vários customers no mesmo tenant.

| Papel | Autoridade | Vínculo obrigatório |
| --- | --- | --- |
| Operador da plataforma | `SYS_ADMIN` | Sem tenant ou customer |
| Administrador do cliente contratante | `TENANT_ADMIN` | Tenant, sem customer |
| Usuário final | `CUSTOMER_USER` | Tenant e customer do mesmo tenant |

O `UserDataValidator` rejeita um usuário final sem ambos os vínculos ou com um
customer de outro tenant. `CustomerDataValidator` exige tenant existente.

## Limites que existem nesta versão

Os nomes abaixo são campos JSON em `profileData.configuration`, do tipo
`DEFAULT` em `common/data/src/main/java/org/thingsboard/server/common/data/tenant/profile/DefaultTenantProfileConfiguration.java`.

| Categoria | Campos |
| --- | --- |
| Quantidade de entidades | `maxDevices`, `maxAssets`, `maxCustomers`, `maxUsers`, `maxDashboards`, `maxRuleChains`, `maxEdges` |
| Arquivos e pacotes | `maxResourcesInBytes`, `maxOtaPackagesInBytes`, `maxResourceSize` |
| Mensagens e processamento | `maxTransportMessages`, `maxTransportDataPoints`, `maxREExecutions`, `maxJSExecutions`, `maxTbelExecutions`, `maxRuleNodeExecutionsPerMessage` |
| Outros consumos e recursos | `maxDPStorageDays`, `maxDebugModeDurationMinutes`, `maxEmails`, `smsEnabled`, `maxSms`, `maxCreatedAlarms` |
| Transporte por tenant | `transportTenantMsgRateLimit`, `transportTenantTelemetryMsgRateLimit`, `transportTenantTelemetryDataPointsRateLimit` |
| Transporte por dispositivo | `transportDeviceMsgRateLimit`, `transportDeviceTelemetryMsgRateLimit`, `transportDeviceTelemetryDataPointsRateLimit` |
| Transporte por gateway | `transportGatewayMsgRateLimit`, `transportGatewayTelemetryMsgRateLimit`, `transportGatewayTelemetryDataPointsRateLimit`, `transportGatewayDeviceMsgRateLimit`, `transportGatewayDeviceTelemetryMsgRateLimit`, `transportGatewayDeviceTelemetryDataPointsRateLimit` |
| Importação, exportação e notificações | `tenantEntityExportRateLimit`, `tenantEntityImportRateLimit`, `tenantNotificationRequestsRateLimit`, `tenantNotificationRequestsPerRuleRateLimit` |
| API REST e WebSocket | `tenantServerRestLimitsConfiguration`, `customerServerRestLimitsConfiguration`, `maxWsSessionsPerTenant`, `maxWsSessionsPerCustomer`, `maxWsSessionsPerRegularUser`, `maxWsSessionsPerPublicUser`, `wsMsgQueueLimitPerSession`, `maxWsSubscriptionsPerTenant`, `maxWsSubscriptionsPerCustomer`, `maxWsSubscriptionsPerRegularUser`, `maxWsSubscriptionsPerPublicUser`, `wsUpdatesPerSessionRateLimit` |
| Retenção em dias | `defaultStorageTtlDays`, `alarmsTtlDays`, `rpcTtlDays`, `queueStatsTtlDays`, `ruleEngineExceptionsTtlDays` |
| Edge | `edgeEventRateLimits`, `edgeEventRateLimitsPerEdge`, `edgeUplinkMessagesRateLimits`, `edgeUplinkMessagesRateLimitsPerEdge` |
| Campos calculados | `maxCalculatedFieldsPerEntity`, `maxArgumentsPerCF`, `minAllowedScheduledUpdateIntervalInSecForCF`, `maxRelationLevelPerCfArgument`, `maxRelatedEntitiesToReturnPerCfArgument`, `maxDataPointsPerRollingArg`, `maxStateSizeInKBytes`, `maxSingleValueArgumentSizeInKBytes`, `minAllowedDeduplicationIntervalInSecForCF`, `minAllowedAggregationIntervalInSecForCF`, `intermediateAggregationIntervalInSecForCF`, `cfReevaluationCheckInterval`, `alarmsReevaluationInterval` |
| Cassandra, quando usado | `cassandraReadQueryTenantCoreRateLimits`, `cassandraWriteQueryTenantCoreRateLimits`, `cassandraReadQueryTenantRuleEngineRateLimits`, `cassandraWriteQueryTenantRuleEngineRateLimits` |

`warnThreshold` também existe para alertas de consumo. Os limites de contagem
de entidades são verificados no momento da criação; para essa categoria, valor
menor ou igual a zero significa sem limite (`DefaultApiLimitService`).
`maxDPStorageDays` é uma medida de consumo em dias de pontos de dados, não uma
quota de armazenamento em bytes. Para a stack PostgreSQL, os limites Cassandra
não têm aplicação. Revise os formatos de campos de taxa e REST no perfil padrão
retornado pela própria instalação antes de ajustá-los; preserve os demais campos
do perfil ao criar uma variante.

## Provisionamento via REST

Execute as chamadas na URL HTTPS da instalação, com
`X-Authorization: Bearer <JWT>` e `Content-Type: application/json`. Obtenha o
JWT por `POST /api/auth/login` ou pela sessão administrativa; não salve senhas,
JWTs ou links de ativação no repositório ou em histórico compartilhado.

1. Como `SYS_ADMIN`, obtenha `GET /api/tenantProfiles?pageSize=100&page=0` e
   escolha o perfil padrão. Consulte o objeto completo em
   `GET /api/tenantProfile/<profileId>`.
2. Copie esse JSON para criar um perfil do plano. Remova `id` e `createdTime`;
   defina `name`, `description`, `default: false` e
   `isolatedTbRuleEngine: false`. Em `profileData.configuration`, preserve
   `type: "DEFAULT"` e os campos existentes, alterando somente os limites
   planejados. Mantenha `profileData.queueConfiguration` se presente. Envie o
   objeto inteiro a `POST /api/tenantProfile` como `SYS_ADMIN` e guarde o
   `id.id` retornado. A validação exige `name` e a configuração do perfil; só
   pode haver um perfil padrão.
3. Como `SYS_ADMIN`, crie o tenant com `POST /api/tenant`:

   ```json
   {
     "title": "Cliente Exemplo",
     "tenantProfileId": { "id": "<UUID_DO_PERFIL>" }
   }
   ```

   Guarde o `id.id` retornado. Não reutilize tenant entre clientes
   contratantes.
4. Ainda como `SYS_ADMIN`, crie a conta administrativa com
   `POST /api/user?sendActivationMail=false`:

   ```json
   {
     "email": "admin@cliente.example",
     "authority": "TENANT_ADMIN",
     "tenantId": { "id": "<UUID_DO_TENANT>" }
   }
   ```

5. Autentique-se como esse `TENANT_ADMIN` e crie o grupo de acesso com
   `POST /api/customer` e corpo `{"title":"Unidade Exemplo"}`. O controlador
   preenche o `tenantId` com o tenant do administrador. Guarde o `id.id` do
   customer. Crie outros customers se houver grupos com visibilidade distinta.
6. Como `TENANT_ADMIN`, crie cada pessoa com
   `POST /api/user?sendActivationMail=false`:

   ```json
   {
     "email": "usuario@cliente.example",
     "authority": "CUSTOMER_USER",
     "customerId": { "id": "<UUID_DO_CUSTOMER>" }
   }
   ```

   O controlador preenche `tenantId` a partir da sessão. Atribua os dispositivos,
   ativos e painéis ao customer correspondente para que o usuário final possa
   acessá-los.
7. Para ativar uma conta sem SMTP, como `SYS_ADMIN` ou `TENANT_ADMIN` autorizado,
   consulte `GET /api/user/<userId>/activationLink` e entregue o link ao próprio
   usuário por um canal privado. Trate o link como credencial temporária.
8. Confira o tenant e o perfil retornados pela API, entre como administrador do
   tenant e depois como usuário final para verificar o escopo. Teste o limite do
   plano em ambiente de homologação antes de atribuí-lo a clientes reais.

Alterar o perfil de um tenant muda os limites aplicáveis ao tenant. Antes de
reduzir um limite, compare-o ao consumo atual para evitar bloquear novas
criações ou mensagens.
