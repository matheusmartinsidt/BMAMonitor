#!/bin/sh
# SPDX-FileCopyrightText: Copyright The Thingsboard Authors
# SPDX-License-Identifier: Apache-2.0
set -eu

if [ "${INSTALL_TB:-false}" = "true" ]; then
  exec java -cp /opt/bmamonitor/server.jar \
    -Dloader.main=org.thingsboard.server.ThingsboardInstallApplication \
    -Dinstall.load_demo=false \
    -Dinstall.upgrade=false \
    org.springframework.boot.loader.launch.PropertiesLauncher
fi

exec java -cp /opt/bmamonitor/server.jar \
  -Dloader.main=org.thingsboard.server.ThingsboardServerApplication \
  org.springframework.boot.loader.launch.PropertiesLauncher
