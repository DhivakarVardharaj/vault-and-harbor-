 What is Vault?
Vault is a tool that keeps passwords and other secrets safe. Only people who are allowed can read them.

 Install and start Vault
First I installed Vault on my Ubuntu laptop and checked that it worked.

    vault --version

Then I made a config file at `/etc/vault.d/vault.hcl`. It tells Vault to save data in `/opt/vault/data`, run on port 8200 and turn on the web UI.

Then I started the Vault service and checked it was running.

    sudo systemctl enable --now vault
    sudo systemctl status vault

Then I initialized Vault. This gives 5 unseal keys and 1 root token. I need any 3 keys to unseal it.

    export VAULT_ADDR='http://127.0.0.1:8200'
    vault operator init -key-shares=5 -key-threshold=3

What I saw: the service was `active (running)` and `vault status` showed `Initialized true`.

(I did not put the keys or the token in this repo, because they are private.)

 Unseal Vault and set up login

Vault starts "sealed", which means locked. I used 3 different keys to unlock it.

    vault operator unseal
    vault operator unseal
    vault operator unseal
    vault status

What I saw: `Sealed false`, so Vault was unlocked.

Then I logged in with the root token and turned on the userpass login method. I also made a user called `kiaq-user`.

    vault login
    vault auth enable userpass
    vault write auth/userpass/users/kiaq-user password="(lab password)"
    vault auth list

What I saw: `userpass/` in the list, and `kiaq-user` could log in.

Turn on the KV secrets engine

KV is the place where secrets are stored. I turned it on at the path `secret/`.

    vault secrets enable -path=secret kv-v2
    vault secrets list

What I saw: `secret/` in the list with type `kv`.

Mistake I made: at first I tried in the UI with the wrong login and got "no access to sys/mounts". Only the root token can turn on engines, so I logged in with the root token.

Save and read secrets

I saved a secret called `myapp` with a username and password, then read it back.

    vault kv put secret/myapp username="admin" password="(password)"
    vault kv get secret/myapp

Then I changed the password. Vault kept the old one as version 1.

    vault kv put secret/myapp username="admin" password="(new password)"
    vault kv get -version=1 secret/myapp
    vault kv metadata get secret/myapp

What I saw: `current_version 2`, and version 1 could still be read.

Policy and access check

A policy says what a user can do. I made a policy called `myapp-read` that only lets a user read and list secrets.

    path "secret/*"                 { capabilities = ["read", "list"] }
    path "secret/data/*"            { capabilities = ["read", "list"] }
    path "secret/metadata/*"        { capabilities = ["read", "list"] }
    path "sys/internal/ui/mounts/*" { capabilities = ["read"] }

Then I gave the policy to `kiaq-user`.

    vault write auth/userpass/users/kiaq-user password="(lab password)" token_policies="myapp-read"

Then I logged in as `kiaq-user` and tested.

    vault kv get secret/myapp                     (worked, I could read it)
    vault kv put secret/myapp password="hacked"   (failed with permission denied)

What I saw: the user had policies `[default myapp-read]`. Reading worked and writing was blocked, so the policy works.

