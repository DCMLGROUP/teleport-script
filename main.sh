#!/bin/bash

# Source variables file
if [ -f "variables.sh" ]; then
    source variables.sh
else
    echo "Le fichier variables.sh est manquant. Veuillez le créer avec les variables requises."
    exit 1
fi

# Fonction pour détecter la distribution
detect_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        echo "Impossible de détecter la distribution"
        exit 1
    fi
}

# Installation des dépendances selon la distribution
install_dependencies() {
    case $OS in
        "Debian GNU/Linux"|"Ubuntu")
            apt update
            apt install -y curl wget gnupg2
            ;;
        "Fedora")
            dnf update -y
            dnf install -y curl wget gnupg2
            ;;
        "Raspbian GNU/Linux")
            apt update
            apt install -y curl wget gnupg2
            ;;
        *)
            echo "Distribution non supportée"
            exit 1
            ;;
    esac
}

# Installation de Teleport selon la distribution
install_teleport() {
    case $OS in
        "Debian GNU/Linux"|"Ubuntu")
            curl https://deb.releases.teleport.dev/teleport-pubkey.asc | apt-key add -
            add-apt-repository 'deb https://deb.releases.teleport.dev/ stable main'
            apt update
            apt install -y teleport
            ;;
        "Fedora")
            curl https://rpm.releases.teleport.dev/teleport-pubkey.asc > /tmp/teleport-pubkey.asc
            rpm --import /tmp/teleport-pubkey.asc
            yum-config-manager --add-repo https://rpm.releases.teleport.dev/teleport.repo
            yum install -y teleport
            ;;
        "Raspbian GNU/Linux")
            curl https://deb.releases.teleport.dev/teleport-pubkey.asc | apt-key add -
            add-apt-repository 'deb https://deb.releases.teleport.dev/ stable main'
            apt update
            apt install -y teleport
            ;;
    esac
}

# Configuration de Teleport
configure_teleport() {
    # Génération du fichier de configuration
    cat > /etc/teleport.yaml <<EOF
teleport:
  nodename: $TELEPORT_NODE_NAME
  data_dir: /var/lib/teleport
  log:
    output: stderr
    severity: INFO
    format:
      output: text
  ca_pin: ""
  diag_addr: ""

auth_service:
  enabled: "yes"
  listen_addr: 0.0.0.0:3025
  cluster_name: $CLUSTER_NAME
  tokens:
    - proxy,node,app:$AUTH_TOKEN

ssh_service:
  enabled: "yes"
  commands:
  - name: hostname
    command: [hostname]
    period: 1m0s

proxy_service:
  enabled: "yes"
  listen_addr: 0.0.0.0:3023
  web_listen_addr: 0.0.0.0:3080
  tunnel_listen_addr: 0.0.0.0:3024
EOF

    # Configuration des permissions
    chmod 600 /etc/teleport.yaml
    
    # Démarrage et activation du service
    systemctl enable teleport
    systemctl start teleport
}

# Exécution principale
echo "Début de l'installation de Teleport..."

detect_distribution
install_dependencies
install_teleport
configure_teleport

echo "Installation et configuration terminées!"
echo "Vous pouvez maintenant accéder à Teleport via https://$DOMAIN_NAME:3080"
echo "Utilisez 'tctl users add' pour créer votre premier utilisateur"
