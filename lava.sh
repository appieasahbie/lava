#!/bin/bash

echo -e "\033[0;35m"

echo "            ####         ##########  ##########  ####   #########";
echo "           ######        ###    ###  ###    ###  ####   #########";
echo "          ###  ###       ###    ###  ###    ###  ####   ##";
echo "         ##########      ##########  ##########  ####   ######";
echo "        ############     ####        ####        ####   ##";
echo "       ####      ####    ####        ####        ####   #########";
echo "      ####        ####   ####        ####        ####   #########";

echo -e '\e[36mTwitter:\e[39m' https://twitter.com/ABDERRAZAKAKRI3
echo -e '\e[36mGithub: \e[39m' https://github.com/appieasahbie
echo -e "\e[0m"

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="lava-testnet-2"
CHAIN_DENOM="ulava"
BINARY_NAME="lavad"
BINARY_VERSION_TAG="v0.21.1.2"
CHEAT_SHEET="https://github.com/appieasahbie/lava"


echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"

sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf lava
git clone https://github.com/lavanet/lava
cd lava || return
git checkout v0.21.1.2
make install
lavad version

lavad config keyring-backend test
lavad config chain-id $CHAIN_ID
lavad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/lavanet/lava-config/main/testnet-2/genesis_json/genesis.json > $HOME/.lava/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/lava-testnet/addrbook.json > $HOME/.lava/config/addrbook.json

SEEDS="3a445bfdbe2d0c8ee82461633aa3af31bc2b4dc0@testnet2-seed-node.lavanet.xyz:26656,e593c7a9ca61f5616119d6beb5bd8ef5dd28d62d@testnet2-seed-node2.lavanet.xyz:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.lava/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.lava/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.lava/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.lava/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.lava/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.025ulava"|g' $HOME/.lava/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.lava/config/config.toml

sed -i \
  -e 's/timeout_commit = ".*"/timeout_commit = "30s"/g' \
  -e 's/timeout_propose = ".*"/timeout_propose = "1s"/g' \
  -e 's/timeout_precommit = ".*"/timeout_precommit = "1s"/g' \
  -e 's/timeout_precommit_delta = ".*"/timeout_precommit_delta = "500ms"/g' \
  -e 's/timeout_prevote = ".*"/timeout_prevote = "1s"/g' \
  -e 's/timeout_prevote_delta = ".*"/timeout_prevote_delta = "500ms"/g' \
  -e 's/timeout_propose_delta = ".*"/timeout_propose_delta = "500ms"/g' \
  -e 's/skip_timeout_commit = ".*"/skip_timeout_commit = false/g' \
  -e 's/seeds = ".*"/seeds = "3a445bfdbe2d0c8ee82461633aa3af31bc2b4dc0@testnet2-seed-node.lavanet.xyz:26656,e593c7a9ca61f5616119d6beb5bd8ef5dd28d62d@testnet2-seed-node2.lavanet.xyz:26656"/g' \
  $HOME/.lava/config/config.toml

sed -i -e 's/broadcast-mode = ".*"/broadcast-mode = "sync"/g' $HOME/.lava/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/lavad.service > /dev/null << EOF
[Unit]
Description=Lava Network Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which lavad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

 cp $HOME/.lava/data/priv_validator_state.json $HOME/.lava/priv_validator_state.json.backup 

 lavad tendermint unsafe-reset-all --home $HOME/.lava --keep-addr-book 
 curl https://snapshot.lava.aknodes.net/snapshot-lava.AKNodes.lz4 | lz4 -dc - | tar -xf - -C $HOME/.lava

 mv $HOME/.lava/priv_validator_state.json.backup $HOME/.lava/data/priv_validator_state.json

sudo systemctl daemon-reload
sudo systemctl enable lavad
sudo systemctl start lavad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
