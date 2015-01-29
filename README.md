# Smart card helper scripts

## gpg-agent-functions.sh

Source this script from `~/.bash_profile` (Mac only for now, due to use of `launchctl getenv` to get the default value of `$SSH_AUTH_SOCK`). This will set your `$SSH_AUTH_SOCK` to `~/.ssh_auth_sock`, then create a symlink from `~/.ssh_auth_sock` to either your normal `ssh-agent` or to `gpg-agent`, if `gpg-agent` is running: 

    mkdir -p ~/bin && cp gpg-agent-functions.sh ~/bin/ && echo source ~/bin/gpg-agent-functions.sh >> ~/.bash_profile

The functions `gpg-agent-up` and `gpg-agent-down` then start and stop `gpg-agent` then re-link the `~/.ssh_auth_socket` symlink as appropriate. For example, to bring the agent up:

    $ gpg-agent-up
    $ gpg-agent-status
    gpg-agent is running.
    $ ssh-add -l
    2048 02:0d:0c:05:04:01:0f:0c:0c:06:01:0d:01:0a:07:00 cardno:000006100300 (RSA)
    $ ssh-keygen -D /usr/local/lib/opensc-pkcs11.so 
    no slots
    cannot read public key from pkcs11

Note that a smart-card–based gpg key is available to ssh, but ssh is unable to access keys via PKCS #11. Now, to use SSH keys from the Yubikey's PIV-II applet using PKCS #11, bring `gpg-agent` down:
    
    $ gpg-agent-down
    $ gpg-agent-status
    gpg-agent is not running.
    $ ssh-add -l
    The agent has no identities.
    $ ssh-keygen -D /usr/local/lib/opensc-pkcs11.so 
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4PM6kqFUBDDP3Atr511lmox6on12aBfhvVg20Jn65XWWtowuFfAIGkZa6XLMK0rCT2EJnTuhMZDV+VhbMVqtY+IAyUyOxAsWNIq9CzwveU533KTwUio5EnaBQQnrfVbIdIx5d35mHd/M9m/iE+GP2ZKEDI2Kr4LNx7n3A5H7b5Hib4Vml8o4jXFNuvhHZx0Qk/e4duqjFKaIUFbb239TTvzMHeq0TbBeTh7a5BfFy8lXgYIkK/mHVS3lm428jIjHBtx9E/FKA//wdVq2vbgHJO8wWLabLUboR0jdgshJ2tfvJPVmE43FWh2XyYY+KtJr6s5jCGMeGbHpz1CLisULp

#### Use case

`gpg-agent` will cache your OpenPGP smart card PIN while it remains running in daemon mode. This is particularly useful when using `gpg-agent` with `--enable-ssh-support` for ssh authentication. 

However, while `gpg-agent` is in daemon mode, other programs cannot access the smart card reader. This blocks, for instance, `ssh` from accessing the PIV-II applet on a Yubikey Neo. `gpg-agent` also frequently requires restarts due to hangs or glitches. These restarts make correctly managing the `$SSH_AUTH_SOCK` environment variable very difficult, especially across many open shells. 

Starting and stopping `gpg-agent` on demand only, for instance only when running `ssh`, prevents caching the smart card PIN. 

`gpg-agent-up` and `gpg-agent-down` allow easy manual control of the `gpg-agent` daemon, either to toggle between gpg and PIV smart card access, or to reset `gpg-agent`, without breaking the `$SSH_AUTH_SOCKET` variable. 

#### Limitations and improvements

- Linux support will require figuring out the correct default value of `$SSH_AUTH_SOCK` in place of the call to `launchctl getenv SSH_AUTH_SOCK`
- This script won't work at all if another user is running a `gpg-agent` process. 

## convert.sh

`convert.sh` takes an OpenSSL PEM-encoded RSA private key file as its only argument, generates a self signed certificate, then loads both the private key and the certificate to the Yubico Neo's PIV-II applet using the `yubico-piv-tool`.

This allows, for example, loading a pre-existing SSH private key into the PIV applet:

    $ bash convert.sh ~/.ssh/id_rsa

Note that you'll need to enter both the PIN for the PIV-II applet on the Yuibkey Neo and the passphrase for the PEM RSA private key file. 

