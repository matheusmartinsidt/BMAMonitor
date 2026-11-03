// SPDX-FileCopyrightText: Copyright The Thingsboard Authors
// SPDX-License-Identifier: Apache-2.0
// Variante de proxy.conf.js para o dev server rodando em container: o backend está no host.
const forwardUrl = process.env.BACKEND_URL || "http://host.docker.internal:8080";
const wsForwardUrl = forwardUrl.replace(/^http/, "ws");

const PROXY_CONFIG = {
  "/api": { "target": forwardUrl, "secure": false },
  "/static/rulenode": { "target": forwardUrl, "secure": false },
  "/static/widgets": { "target": forwardUrl, "secure": false },
  "/oauth2": { "target": forwardUrl, "secure": false },
  "/login/oauth2": { "target": forwardUrl, "secure": false },
  "/api/ws": { "target": wsForwardUrl, "ws": true, "secure": false },
};

module.exports = PROXY_CONFIG;
