#!/bin/bash
set -eu

export DEBIAN_FRONTEND=noninteractive

function install_dependencies {
  curl https://pkgs.tailscale.com/stable/ubuntu/bionic.gpg | sudo apt-key add -
  curl https://pkgs.tailscale.com/stable/ubuntu/bionic.list | sudo tee /etc/apt/sources.list.d/tailscale.list

  apt-get update -y  
  apt-get install -y curl unzip socat tailscale docker.io
}

function install_consul {
  mkdir -p /tmp/consul
  pushd /tmp/consul

  curl -Os https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

  unzip consul_${CONSUL_VERSION}_linux_amd64.zip >/dev/null
  mv consul /usr/local/bin/

  useradd --system --home /etc/consul.d --shell /bin/false consul

  mkdir --parents /opt/consul
  mkdir --parents /etc/consul.d

  tee /etc/consul.d/consul.hcl >/dev/null <<EOF
datacenter    = "dc1"
bind_addr     = "{{ GetInterfaceIP \"tailscale0\" }}"
data_dir      = "/opt/consul"
retry_join    = [ "${CONSUL_SERVER}" ]
EOF

  chmod 640 /etc/consul.d/consul.hcl
  chown --recursive consul:consul /opt/consul
  chown --recursive consul:consul /etc/consul.d

  cat - > /etc/systemd/system/consul.service <<'EOF'
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target tailscaled.service
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
ExecStop=/usr/local/bin/consul leave
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
  chmod 0600 /etc/systemd/system/consul.service

  systemctl enable consul.service

  popd
  rm -rf /tmp/consul
}


function install_nomad {

  mkdir /tmp/nomad
  pushd /tmp/nomad

  curl -Os https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip

  unzip nomad_${NOMAD_VERSION}_linux_amd64.zip >/dev/null
  mv nomad /usr/local/bin/

  mkdir --parents /opt/nomad
  mkdir --parents /etc/nomad.d

  tee /etc/nomad.d/nomad.hcl >/dev/null <<EOF
bind_addr = "{{ GetInterfaceIP \"tailscale0\" }}"
data_dir  = "/opt/nomad"

client {
  enabled           = true
  node_class        = "${NODE_CLASS}"
  network_interface = "tailscale0"
  network_speed     = 1000
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}
EOF

  chmod 640 /etc/nomad.d/nomad.hcl

  cat - > /etc/systemd/system/nomad.service <<'EOF'
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target consul.service

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF
  chmod 0600 /etc/systemd/system/nomad.service

  systemctl enable nomad.service

  popd
  rm -rf /tmp/nomad

}

function join_tailscale {
  tailscale up --authkey ${TAILSCALE_AUTH_KEY}
  sleep 5
}

function start_consul {
  systemctl start consul
}

function start_nomad {
  systemctl start nomad
}

install_dependencies
install_consul
install_nomad

join_tailscale
start_consul
start_nomad
