job "hyperbeam-dev" {
  datacenters = ["ator-fin"]
  type = "service"
  namespace = "dev-services"

  group "hyperbeam-group-dev" {
    count = 1

    network {
      mode = "bridge"

      port "hyperbeam" {
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
        force_pull = true
        image_pull_timeout = "15m"
        command = "rebar3"
        args = [
          "shell", "--eval",
          "hb:start_mainnet(#{ port => ${NOMAD_PORT_hyperbeam}, mode => debug, priv_key_location => <<\"/app/wallet.json\">>, bundler_ans104 => <<\"https://ar.anyone.tech/bundler:443\">>, faff_allow_list => [<<\"jp0QaS_Zai2hGaB-yRvAIMEtodmH_iHr0drpZxAZQtU\">>], routes => [#{<<\"template\">> => <<\"/process/.*\">>, <<\"node\">> => #{ <<\"prefix\">> => <<\"http://${NOMAD_ADDR_localcu}\">> } }, #{ <<\"template\">> => <<\"/result/.*\">>, <<\"node\">> => #{ <<\"prefix\">> => <<\"http://${NOMAD_ADDR_localcu}\">> } }, #{ <<\"template\">> => <<\"/graphql\">>, <<\"nodes\">> => [ #{ <<\"prefix\">> => <<\"https://arweave-search.goldsky.com\">>, <<\"opts\">> => #{ http_client => httpc, protocol => http2 } }, #{ <<\"prefix\">> => <<\"https://arweave.net\">>, <<\"opts\">> => #{ http_client => gun, protocol => http2 } } ] }, #{ <<\"template\">> => <<\"/raw\">>, <<\"node\">> => #{ <<\"prefix\">> => <<\"https://arweave.net\">>, <<\"opts\">> => #{ http_client => gun, protocol => http2 } } } ] })."
        ]
        volumes = [ "secrets/wallet.json:/app/wallet.json" ]
      }

      resources {
        cpu = 4096
        memory = 4096
      }

      vault {
        role = "any1-nomad-workloads-controller"
      }

      identity {
        name = "vault_default"
        aud  = [ "any1-infra" ]
        ttl  = "1h"
      }

      template {
        data = "{{ with secret `kv/dev-services/hyperbeam-dev` }}{{ base64Decode .Data.data.WALLET_KEY_BASE64 }}{{ end }}"
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
        role = "any1-nomad-workloads-controller"
      }

      identity {
        name = "vault_default"
        aud  = ["any1-infra"]
        ttl  = "1h"
      }

      template {
        data = "{{ with secret `kv/dev-services/hyperbeam-dev` }}{{ base64Decode .Data.data.WALLET_KEY_BASE64 }}{{ end }}"
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
