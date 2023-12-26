# Setup your node on Lava


![63861498b497bc3d955753ba_lavanet (1)](https://user-images.githubusercontent.com/108979536/214578650-dad0f06b-2d5f-43db-a612-ca71df1eae10.jpg)



# Introduction

Lava uses a cryptoeconomic incentive framework and appchain to coordinate node runners and
applications in the trustless exchange of blockchain RPC service. Web3 must diversify its node
operators to ensure that the ecosystem can achieve censorship-resistance; Lava creates this
diversity. The Network also includes several novel innovations across its technology stack and
blockchain, including mechanisms for ensuring data integrity, scalability and privacy.


# Hardware Requirements

 ### Minimum Hardware Requirements
 
 + 4x CPUs; the faster clock speed the better

 + 8GB RAM

+ 100GB of storage (SSD or NVME)

 ### Recommended Hardware Requirements
 
 + 8x CPUs; the faster clock speed the better

+ 64GB RAM

+ 1TB of storage (SSD or NVME)

# 1-ɪɴᴛᴀʟʟᴀᴛɪᴏɴ ᴏɴᴇ ᴛɪᴍᴇ (ꜱᴄʀɪᴘᴛ ᴀᴜᴛᴏᴍᴀᴛɪᴄ ɪɴꜱᴛᴀʟʟᴀᴛɪᴏɴ)

    wget -O lava.sh https://raw.githubusercontent.com/appieasahbie/lava/main/lava.sh && chmod +x lava.sh && ./lava.sh
    
  
### post installation 

   source $HOME/.bash_profile
  
### (Check the status of your node)

   lavad status
      
### open ports and active the firewall

      sudo ufw default allow outgoing
      sudo ufw default deny incoming
      sudo ufw allow ssh/tcp
      sudo ufw limit ssh/tcp
      sudo ufw allow ${LAVA_PORT}656,${LAVA_PORT}660/tcp
      sudo ufw enable
      
###  Create wallet

  + (Please save all keys on your notepad)

        lavad keys add $WALLET
   
  + To recover your old wallet use this command
 
        lavad keys add $WALLET --recover
        
  + show keys 
  
        lavad keys list
        
   
### Fund your wallet (to create validator) Discord channel #faucet


### Create validator (after recieving of tokens and must important sync is false)

  + replace <wallet> with your wallet name and <moniker> with your validator name
  
         lavad tx staking create-validator \
          --amount=90000ulava \
          --pubkey=$(lavad tendermint show-validator) \
          --moniker="Yourvalidatorname" \
          --chain-id=lava-testnet-2 \
          --commission-rate=0.1 \
          --commission-max-rate=0.2 \
          --commission-max-change-rate=0.05 \
          --min-self-delegation=1 \
          --fees=10000ulava \
          --from=Yourwalletname \
          -y
   

 * 

  
 # Snapchot (optional auto installed with the script)
 
      sudo systemctl stop lavad

      cp $HOME/.lava/data/priv_validator_state.json $HOME/.lava/priv_validator_state.json.backup 

      lavad tendermint unsafe-reset-all --home $HOME/.lava --keep-addr-book 
      https://snapshots.aknodes.net/snapshots/lava/snapshot-lava.AKNodes.lz4 | lz4 -dc - | tar -xf - -C $HOME/.lava

      mv $HOME/.lava/priv_validator_state.json.backup $HOME/.lava/data/priv_validator_state.json 

      sudo systemctl start lavad
      sudo journalctl -u lavad -f --no-hostname -o cat
      
      
      
# State sync 


      sudo systemctl stop lavad
      cp $HOME/.lava/data/priv_validator_state.json $HOME/.lava/priv_validator_state.json.backup
      lavad tendermint unsafe-reset-all --home $HOME/.lava


      STATE_SYNC_RPC=https://rpc.lava.aknodes.net:443
      STATE_SYNC_PEER=3306e10f1635f71e1d93219a369f4907ec062ad5@167.235.14.83:17656
      LATEST_HEIGHT=$(curl -s $STATE_SYNC_RPC/block | jq -r .result.block.header.height)
      SYNC_BLOCK_HEIGHT=$(($LATEST_HEIGHT - 1000))
      SYNC_BLOCK_HASH=$(curl -s "$STATE_SYNC_RPC/block?height=$SYNC_BLOCK_HEIGHT" | jq -r .result.block_id.hash)

      sed -i \
        -e "s|^enable *=.*|enable = true|" \
        -e "s|^rpc_servers *=.*|rpc_servers = \"$STATE_SYNC_RPC,$STATE_SYNC_RPC\"|" \
        -e "s|^trust_height *=.*|trust_height = $SYNC_BLOCK_HEIGHT|" \
        -e "s|^trust_hash *=.*|trust_hash = \"$SYNC_BLOCK_HASH\"|" \
        -e "s|^persistent_peers *=.*|persistent_peers = \"$STATE_SYNC_PEER\"|" \
        $HOME/.lava/config/config.toml

      mv $HOME/.lava/priv_validator_state.json.backup $HOME/.lava/data/priv_validator_state.json

      sudo systemctl start lavad && sudo journalctl -u lavad -f --no-hostname -o cat
 
 
 
 # Cheat Sheet
### Delegate to yourself

      lavad tx staking delegate $(lavad keys show wallet --bech val -a) 1000000ulava --from wallet --chain-id lava-testnet-2 --gas-prices 0.1ulava --gas-adjustment 1.5 --gas auto -y 
      
 
 ### Redelegate
 
      lavad tx staking redelegate $(lavad keys show wallet --bech val -a) 1000000ulava --from wallet --chain-id lava-testnet-2 --gas-prices 0.1ulava --gas-adjustment 1.5 --gas auto -y  
     
 ### Get Validator Info

     lavad status 2>&1 | jq .ValidatorInfo

### Get Catching Up

     lavad status 2>&1 | jq .SyncInfo.catching_up
 
### Get Latest Height

     lavad status 2>&1 | jq .SyncInfo.latest_block_height

## Get Peer

     echo $(lavad tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.lavad/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')

### Reset Node

    lavad tendermint unsafe-reset-all --home $HOME/.lavad --keep-addr-book

### Remove Node

    sudo systemctl stop lavad && sudo systemctl disable lavad && sudo rm /etc/systemd/system/lavad.servi
     
###  Run Service

    sudo systemctl start lavad

### Stop Service

    sudo systemctl stop lavad

### Restart Service

    sudo systemctl restart lavad

### Check Service Status

    sudo systemctl status lavad

### Check Service Logs

      sudo journalctl -u lavad -f --no-hostname -o cat     
 
### Edit validator
 
      lavad tx staking edit-validator \
        --new-moniker="XXXXXXXXXXXXXX" \
        --identity=XXXXXXXXXXXX \
        --details="xxxxxxxxxx" \
        --chain-id=lava-testnet-2 \
        --from=wallet \
        --fees=5000ulava \
        -y

### Delete the node 

    sudo systemctl stop lavad
    sudo systemctl disable lavad
    sudo rm /etc/systemd/system/lava* -rf
    sudo rm $(which lavad) -rf
    sudo rm $HOME/.lavad* -rf
    sudo rm $HOME/lavad -rf
    sed -i '/LAVA_/d' ~/.bash_profile
    rm -rf lava 
    rm -rf .lava


    
[buy me a cup of coffe ](https://www.paypal.com/paypalme/AbdelAkridi?country.x=NL&locale.x=en_US) 






