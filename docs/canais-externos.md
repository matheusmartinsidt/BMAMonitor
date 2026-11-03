# Canais de saída para ThingsBoard

Na configuração padrão de `application/src/main/resources/thingsboard.yml`, `UPDATES_ENABLED` e `COMMUNITY_GRANT_ENABLED` agora assumem `false`. Um operador ainda pode habilitar cada recurso explicitamente por variável de ambiente.

## Verificação do código

- `DefaultUpdateService.init()` sempre cria um `UpdateMessage` inicial, então `checkUpdates()` continua retornando um valor. Com `updates.enabled=false`, o bloco que cria `.instance_id` e agenda `checkUpdatesRunnable` não é executado. Essa é a única rotina da classe que chama `updates.thingsboard.io`.
- O fluxo do community grant consulta `community-grant.enabled`; com o valor `false` no YAML, o fluxo não inicia e o cliente do portal não faz chamadas a `license.thingsboard.io`.
- `IotHubRestClient.initRestClient()` cria o `RestTemplate` sem validar `iot-hub.base-url`, mas cada operação concatena a URL base com um caminho `/api/...`. Uma base vazia produziria um caminho relativo que não representa o destino esperado e faria as operações do IoT Hub falharem. Por isso a URL padrão foi mantida. O bloqueio de saída no firewall da implantação deve cobrir `iot-hub.thingsboard.io` e os demais subdomínios `*.thingsboard.io`.

Essas conclusões são da inspeção dos caminhos de execução e do build Maven. O bloqueio de rede precisa ser aplicado e testado no host de produção; a mudança de configuração, isoladamente, não o substitui.

Validação de build em 2026-11-03: `mvn package -pl application -am -DskipTests -Dlicense.skip=true -Dskip.ui.build=true` concluiu com `BUILD SUCCESS` nos 36 módulos selecionados em 7min48s. Esse comando não inicia a aplicação; o comportamento em execução acima foi confirmado por inspeção do código.
