#!/bin/bash

GREEN="\e[32m"
LIGHT_GREEN="\e[92m"
YELLOW="\e[33m"
DEFAULT="\e[39m"

function install_node {
   echo "*********************"
   echo -e "\e[1m\e[33m	WARNING!!!! THIS NODE IS INSTALLED IN PORT 14657!!!!\e[0m"
   echo "*********************"
   echo -e "\e[1m\e[32m	Enter your Node Name:\e[0m"
   echo "_|-_|-_|-_|-_|-_|-_|"
   read MONIKER
   echo "_|-_|-_|-_|-_|-_|-_|"
   echo export MONIKER=${MONIKER} >> $HOME/.bash_profile
   source ~/.bash_profile


    echo "Installing Depencies..."
    sudo apt update
    sudo apt install curl tar wget tmux htop net-tools clang pkg-config libssl-dev jq build-essential git make ncdu -y
    
    echo "Installing GO..."
	sudo rm -rf /usr/local/go
	curl -Ls https://go.dev/dl/go1.19.5.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
	eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
	eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
    
    echo "Downloading and building binaries..."
   cd $HOME
   rm -rf $HOME/lava
   git clone https://github.com/lavanet/lava.git
   cd lava
   
 
    echo "Build binaries.."
    git checkout v0.5.2
    make build

# Create service
sudo tee /etc/systemd/system/lavad.service > /dev/null <<EOF
[Unit]
Description=lava
After=network-online.target
[Service]
User=$USER
ExecStart=$(which lavad) start --home $HOME/.lava
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable planqd

    # Create application symlinks
    sudo ln -s $HOME/.planqd/cosmovisor/genesis $HOME/.planqd/cosmovisor/current
    sudo ln -s $HOME/.planqd/cosmovisor/current/bin/planqd /usr/local/bin/planqd
    
    echo "Configuring Node..."
    # Set node configuration
   lavad config node tcp://localhost:${LAVA_PORT}657
   lavad config keyring-backend test
   lavad config chain-id $LAVA_CHAIN_ID
   
   
   # Initialize the node
   lavad init $MONIKER --chain-id $LAVA_CHAIN_ID

   # Download genesis and addrbook
   curl https://raw.githubusercontent.com/K433QLtr6RA9ExEq/GHFkqmTzpdNLDd6T/main/testnet-1/genesis_json/genesis.json > ~/.lava/config/genesis.json
   curl https://files.itrocket.net/testnet/lava/addrbook.json > ~/.lava/config/addrbook.json


   # Add seeds
SEEDS="3a445bfdbe2d0c8ee82461633aa3af31bc2b4dc0@prod-pnet-seed-node.lavanet.xyz:26656,e593c7a9ca61f5616119d6beb5bd8ef5dd28d62d@prod-pnet-seed-node2.lavanet.xyz:26656"
PEERS="3693ea5a8a9c0590440a7d6c9a98a022ce3b2455@lava-testnet-peer.itrocket.net:443"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.lava/config/config.toml
   
   # Set minimum gas price and timeout commit and peers
   sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0ulava"/g' $HOME/.lava/config/app.toml
   sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.lava/config/config.toml
	
   # Set Indexer Null
   indexer="null" && \
   sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.lava/config/config.toml
   
   # Set pruning
   sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.lava/config/app.toml
   sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.lava/config/app.toml
   sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.lava/config/app.toml

   # Set custom ports
   sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${LAVA_PORT}658\"%; 
   s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${LAVA_PORT}657\"%; 
   s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${LAVA_PORT}060\"%;
   s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${LAVA_PORT}656\"%;
   s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${LAVA_PORT}656\"%;
   s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${LAVA_PORT}660\"%" $HOME/.lava/config/config.toml

   echo "Starting Node..."
   sudo systemctl start lavad && journalctl -u lavad -f --no-hostname -o cat

}

function check_logs {

    sudo journalctl -fu lavad -o cat
}

function create_wallet {
    echo "Creating your wallet.."
    sleep 2
    
    lavad keys add wallet
    
    sleep 3
    echo "SAVE YOUR MNEMONIC!!!"


}

function state_sync {
   echo " SOON... "
 
}

function sync_snapshot {
sudo systemctl stop lavad
cp $HOME/.lava/data/priv_validator_state.json $HOME/.lavad/priv_validator_state.json.backup
rm -rf $HOME/.lava/data

curl https://snapshot.lava.aknodes.net/snapshot-lava-02-20.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.lava
mv $HOME/.lava/priv_validator_state.json.backup $HOME/.lava/data/priv_validator_state.json 

sudo systemctl restart lavad && journalctl -u lavad -f --no-hostname -o cat

}

function delete_node {
echo "BACKUP YOUR NODE!!!"
echo "Deleting node in 3 seconds"
sleep 3
cd $HOME
sudo systemctl stop lavad
sudo systemctl disable lavad
sudo rm /etc/systemd/system/lavad.service
sudo systemctl daemon-reload
sudo rm -rf $(which lavad) 
sudo rm -rf $HOME/.lava
sudo rm -rf $HOME/lava
echo "Node has been deleted from your machine :)"
sleep 3
}

function select_option {
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

function print_logo {
    echo -e "\033[0;35m"
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++";
    echo "            ####         ##########  ##########  ####   #########";
    echo "           ######        ###    ###  ###    ###  ####   #########";
    echo "          ###  ###       ###    ###  ###    ###  ####   ##";
    echo "         ##########      ##########  ##########  ####   ######";
    echo "        ############     ####        ####        ####   ##";
    echo "       ####      ####    ####        ####        ####   #########";
    echo "      ####        ####   ####        ####        ####   #########";
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++";
    echo -e '\e[36mTwitter:\e[39m' https://twitter.com/ABDERRAZAKAKRI3
    echo -e '\e[36mGithub: \e[39m' https://github.com/appieasahbie
    echo -e "\e[0m"
}

function main {
    cd $HOME

    print_logo

    echo "Appieasahbie Node Installer CLI (Lava Mainnet Port 14)"
    echo "Choose the command you want to use:"

    options=(
        "Install Lava Node Port 14"
        "Check Logs"
        "Create wallet"
        "Sync Via State-sync (X) "
        "Sync Via Snapshot   (✓) "
        "Delete Node"
        "Exit"
    )

    select_option "${options[@]}"
    choice=$?
    clear

    case $choice in
        0)
            install_node
            ;;
        1)
            check_logs
            ;;
        2)
            create_wallet
            ;;    
        3)
            state_sync
            ;;
        4)
            sync_snapshot
            ;;
        5)
            delete_node
            ;;    
        6)
            exit 0
            ;;
    esac

    echo -e $DEFAULT
}

main
