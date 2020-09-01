job "autoscaler" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${node.class}"
    value     = "hashistack-rpi"
  }

  group "autoscaler" {
    count = 1

    network {
      dns {
        servers = ["8.8.8.8", "8.8.4.4"]
      }
    }

    task "autoscaler" {
      driver = "exec"

      vault {
        policies = ["autoscaler"]
      }

      artifact {
        source = "https://releases.hashicorp.com/nomad-autoscaler/0.1.0/nomad-autoscaler_0.1.0_linux_arm64.zip"
      }

      config {
        command = "nomad-autoscaler"

        args = [
          "agent",
          "-config",
          "${NOMAD_TASK_DIR}/config.hcl",
          "-http-bind-address",
          "0.0.0.0",
          "-policy-dir",
          "${NOMAD_TASK_DIR}/policies/",
        ]
      }

      template {
        data = <<EOF
nomad {
  address = "http://{{env "attr.unique.network.ip-address" }}:4646"
}

apm "prometheus" {
  driver = "prometheus"
  config = {
    address = "http://{{ range service "prometheus" }}{{ .Address }}:{{ .Port }}{{ end }}"
  }
}

{{ with secret "kv/data/autoscaler" }}
target "aws-asg" {
  driver = "aws-asg"
  config = {
    aws_region = "eu-central-1"
    aws_access_key_id = "{{ .Data.data.aws_access_key_id }}"
    aws_secret_access_key = "{{ .Data.data.aws_secret_access_key }}"
  }
}
{{ end }}

strategy "target-value" {
  driver = "target-value"
}
EOF

        destination = "${NOMAD_TASK_DIR}/config.hcl"
      }

      template {
        data = <<EOF
enabled = true
min     = 1
max     = 5

policy {

  cooldown            = "2m"
  evaluation_interval = "1m"

  check "cpu_allocated_percentage" {
    source = "prometheus"
    query  = "scalar(sum(nomad_client_allocated_cpu{node_class=\"hashistack-aws\"}*100/(nomad_client_unallocated_cpu{node_class=\"hashistack-aws\"}+nomad_client_allocated_cpu{node_class=\"hashistack-aws\"}))/count(nomad_client_allocated_cpu{node_class=\"hashistack-aws\"}))"

    strategy "target-value" {
      target = 70
    }
  }

  check "mem_allocated_percentage" {
    source = "prometheus"
    query  = "scalar(sum(nomad_client_allocated_memory{node_class=\"hashistack-aws\"}*100/(nomad_client_unallocated_memory{node_class=\"hashistack-aws\"}+nomad_client_allocated_memory{node_class=\"hashistack-aws\"}))/count(nomad_client_allocated_memory{node_class=\"hashistack-aws\"}))"

    strategy "target-value" {
      target = 70
    }
  }

  target "aws-asg" {
    dry-run             = "false"
    node_class          = "hashistack-aws"
    node_drain_deadline = "5m"
    aws_asg_name        = "hashistack-clients"
  }
  
}
EOF

        destination = "${NOMAD_TASK_DIR}/policies/hashistack.hcl"
      }

      resources {
        cpu    = 50
        memory = 128

        network {
          mbits = 10
          port "http" {
            static = 8080
          }
        }
      }

      service {
        name = "autoscaler"
        port = "http"

        check {
          type     = "http"
          path     = "/v1/health"
          interval = "5s"
          timeout  = "2s"
        }
      }
    }
  }
}