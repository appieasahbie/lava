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
    
    ###  Post installation

      source $HOME/.bash_profile
      
### (Check the status of your node)

      okp4d status 2>&1 | jq .SyncInfo
      
### open ports and active the firewall

      sudo ufw default allow outgoing
      sudo ufw default deny incoming
      sudo ufw allow ssh/tcp
      sudo ufw limit ssh/tcp
      sudo ufw allow ${OKP4_PORT}656,${OKP4_PORT}660/tcp
      sudo ufw enable
      
###  Create wallet

  + (Please save all keys on your notepad)

        okp4d keys add $WALLET
   
  + To recover your old wallet use this command
 
        okp4d keys add $WALLET --recover
        
  + show keys 
  
        okp4d keys list
        
### Add wallet and valoper address and load variables into the system

        OKP4_WALLET_ADDRESS=$(okp4d keys show $WALLET -a)
        OKP4_VALOPER_ADDRESS=$(okp4d keys show $WALLET --bech val -a)
        echo 'export OKP4_WALLET_ADDRESS='${OKP4_WALLET_ADDRESS} >> $HOME/.bash_profile
        echo 'export OKP4_VALOPER_ADDRESS='${OKP4_VALOPER_ADDRESS} >> $HOME/.bash_profile
        source $HOME/.bash_profile
        
   
### Fund your wallet (to create validator) [link faucet](https://faucet.okp4.network)


### Create validator (after recieving of tokens and must important sync is false)

  + replace <wallet> with your wallet name and <moniker> with your validator name
  

         okp4d tx staking create-validator \
         --amount 100000uknow \
         --from WALLETNAME \
         --commission-max-change-rate "0.01" \
         --commission-max-rate "0.2" \
         --commission-rate "0.05" \
         --min-self-delegation "1" \
         --pubkey  $(okp4d tendermint show-validator) \
         --moniker NODENAME \
         --chain-id okp4-nemeton
  
  
 # Snapchot optional 
 
    cp $HOME/.lava/data/priv_validator_state.json $HOME/.lava/priv_validator_state.json.backup
    lavad tendermint unsafe-reset-all --home $HOME/.lava --keep-addr-book

    SNAP_NAME=$(curl -s https://snapshot.lava.aknodes.net/snapshot-lava-01-24.tar.lz4 | egrep -o ">lava-testnet-1.*\.tar.lz4" | tr -d ">")
    curl https://snapshot.lava.aknodes.net/snapshot-lava-01-24.tar.lz4${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.lava

    mv $HOME/.lava/priv_validator_state.json.backup $HOME/.lava/data/priv_validator_state.json

    sudo systemctl restart lavad
    sudo journalctl -u lavad -f --no-hostname -o cat
 



### Delegate to yourself

      lavad tx staking delegate $(okp4d keys show wallet --bech val -a) 1000000uknow --from wallet --chain-id $LAVA_CHAIN_ID --gas-prices 0.1uknow --gas-adjustment 1.5 --gas auto -y 
      
 
 ### Redelegate
 
      lavad tx staking redelegate $(okp4d keys show wallet --bech val -a) <TO_VALOPER_ADDRESS> 1000000uknow --from wallet --chain-id $LAVA_CHAIN_ID --gas-prices 0.1uknow --gas-adjustment 1.5 --gas auto -y 
     
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

### Delete the node 

    sudo systemctl stop lavad
    sudo systemctl disable lavad
    sudo rm /etc/systemd/system/lava* -rf
    sudo rm $(which lavad) -rf
    sudo rm $HOME/.lavad* -rf
    sudo rm $HOME/lavad -rf
    sed -i '/LAVA_/d' ~/.bash_profile


    
[buy me a cup of coffe ](https://www.paypal.com/paypalme/AbdelAkridi?country.x=NL&locale.x=en_US) 






