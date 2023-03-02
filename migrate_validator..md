# Migrate your validator to another machine

### 1. install the testnet on your new server

### 2. Confirm that you have the recovery seed phrase information for the active key running on the old machine

#### backup your key
```
lavad keys export mykey
```
> _This prints the private key that you can then paste into the file `mykey.backup`_

#### get list of keys
```
lavad keys list
```

### 3. Recover the active key of the old machine on the new machine

#### This can be done with the mnemonics
```
lavad keys add mykey --recover
```

#### Or with the backup file `mykey.backup` from the previous step
```
lavad keys import mykey mykey.backup
```

### 4. Wait for the new full node on the new machine to finish catching-up

#### To check synchronization status
```
lavad status 2>&1 | jq .SyncInfo
```
> _`catching_up` should be equal to `false`_

### 5. After the new node has caught-up, stop the validator node

> _To prevent double signing, you should stop the validator node before stopping the new full node to ensure the new node is at a greater block height than the validator node_
> _If the new node is behind the old validator node, then you may double-sign blocks_

#### Stop and disable service on old machine
```
sudo systemctl stop lavad
sudo systemctl disable lavad
```
> _The validator should start missing blocks at this point_

### 6. Stop service on new machine
```
sudo systemctl stop lavad
```

### 7. Move the validator's private key from the old machine to the new machine
#### Private key is located in: `~/.lavad/config/priv_validator_key.json`

> _After being copied, the key `priv_validator_key.json` should then be removed from the old node's config directory to prevent double-signing if the node were to start back up_
```
sudo mv ~/.lavad/config/priv_validator_key.json ~/.lavad/bak_priv_validator_key.json
```

### 8. Start service on a new validator node
```
sudo systemctl start lavad
```
> _The new node should start signing blocks once caught-up_

### 9. Make sure your validator is not jailed
#### To unjail your validator
```
lavad tx slashing unjail --chain-id $LAVA_CHAIN_ID --from mykey --gas=auto -y
```
