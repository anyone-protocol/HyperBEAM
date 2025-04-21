job "hyperbeam-dev" {
  datacenters = ["ator-fin"]
  type = "service"

  group "hyperbeam-group-dev" {
    count = 1

    network {
      mode = "bridge"

      port "hyperbeam" {
        to = 10000
        host_network = "wireguard"
      }

      port "localcu" {
        host_network = "wireguard"
      }
    }

    task "hyperbeam-task-dev" {
      driver = "docker"

      config {
        image = "ghcr.io/anyone-protocol/hyperbeam:latest"
        command = "rebar3"
        args = ["shell"]
        volumes = [
          "local/config.flat:/app/config.flat",
          "secrets/wallet.json:/app/wallet.json"
        ]
      }

      resources {
        cpu = 4096
        memory = 4096
      }

      vault {
	      policies = ["ario-bundler-any1"]
	    }

      template {
        data = <<-EOF
        port: 10000
        priv_key_location: /app/wallet.json
        bundler_ans104: "https://ar.anyone.tech/bundler:443"
        EOF
        destination = "local/config.flat"
      }

      template {
        data = "{{ with secret `kv/ario-bundler` }}{{ base64Decode .Data.data.BUNDLER_KEY_BASE64 }}{{ end }}"
        destination = "secrets/wallet.json"
      }

      service {
        name = "hyperbeam-dev"
        port = "hyperbeam"
        tags = [
          "traefik-ec.enable=true",
          "traefik-ec.http.routers.hyperbeam-dev.entrypoints=https",
          "traefik-ec.http.routers.hyperbeam-dev.tls=true",
          "traefik-ec.http.routers.hyperbeam-dev.tls.certresolver=anyoneresolver",
          "traefik-ec.http.routers.hyperbeam-dev.rule=Host(`hyperbeam-dev.ec.anyone.tech`)"
        ]

        check {
          name = "hyperbeam-dev-check"
          type = "http"
          port = "hyperbeam"
          path = "/~meta@1.0/info"
          interval = "10s"
          timeout  = "10s"
        }
      }
    }

    task "local-cu-dev" {
      lifecycle {
        hook = "poststart"
        sidecar = true
      }

      driver = "docker"

      config {
        image = "ghcr.io/anyone-protocol/local-cu:latest"
        volumes = [
          "secrets/wallet.json:/usr/app/wallet.json"
        ]
      }

      env {
        UNIT_MODE="hbu"
        HB_URL="http://${NOMAD_ADDR_hyperbeam}"
        PORT="${NOMAD_PORT_localcu}"
        WALLET_FILE="/usr/app/wallet.json"
        NODE_CONFIG_ENV="development"
        UPLOADER_URL="https://ar.anyone.tech/bundler"
      }

      vault {
	      policies = ["ario-bundler-any1"]
	    }

      template {
        data = "{{ with secret `kv/ario-bundler` }}{{ base64Decode .Data.data.BUNDLER_KEY_BASE64 }}{{ end }}"
        destination = "secrets/wallet.json"
      }

      service {
        name = "localcu-dev"
        port = "localcu"
        tags = [
          "traefik-ec.enable=true",
          "traefik-ec.http.routers.localcu-dev.entrypoints=https",
          "traefik-ec.http.routers.localcu-dev.tls=true",
          "traefik-ec.http.routers.localcu-dev.tls.certresolver=anyoneresolver",
          "traefik-ec.http.routers.localcu-dev.rule=Host(`localcu-dev.ec.anyone.tech`)"
        ]

        check {
          name = "localcu-dev-check"
          type = "http"
          port = "localcu"
          path = "/"
          interval = "10s"
          timeout  = "10s"
        }
      }
    }
  }
}
