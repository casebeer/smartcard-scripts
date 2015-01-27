#!/bin/bash

## gpg-agent helper functions
#
#  Functions to cleanly start and stop gpg-agent in order to toggle between using 
#  gpg-agent and ssh-agent for ssh keys. This allows using gpg-agent for SSH keys 
#  from a Gnupg smartcard while still having the option to use a non-PGP smartcard 
#  applet on the same card (for example, the Yubikey Neo's PIV-II applet). This is 
#  not otherwise possible, since gpg-agent prevents other programs from accessing 
#  the smartcard while it's running. 
#
#  Note that for each down/up cycle of gpg-agent, you'll have to re-enter your PINs/
#  passphrases, as the cached keys will be cleared.
#
#  EXAMPLE (after inserting a Yubikey Neo with keys in both the OpenPGP and PIV-II applets)
#
#  Use SSH keys from OpenPGP applet, PIV-II applet inaccessible:
# 
#  $ gpg-agent-up
#  $ ssh-add -l
#  2048 02:0d:0c:05:04:01:0f:0c:0c:06:01:0d:01:0a:07:00 cardno:000006100300 (RSA)
#  $ ssh-keygen -D /usr/local/lib/opensc-pkcs11.so 
#  no slots
#  cannot read public key from pkcs11
#
#  Use SSH keys from PIV-II applet, OpenPGP applet keys no longer available to ssh:
# 
#  $ gpg-agent-down
#  $ ssh-add -l
#  The agent has no identities.
#  $ ssh-keygen -D /usr/local/lib/opensc-pkcs11.so 
#  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4PM6kqFUBDDP3Atr511lmox6on12aBfhvVg20Jn65XWWtowuFfAIGkZa6XLMK0rCT2EJnTuhMZDV+VhbMVqtY+IAyUyOxAsWNIq9CzwveU533KTwUio5EnaBQQnrfVbIdIx5d35mHd/M9m/iE+GP2ZKEDI2Kr4LNx7n3A5H7b5Hib4Vml8o4jXFNuvhHZx0Qk/e4duqjFKaIUFbb239TTvzMHeq0TbBeTh7a5BfFy8lXgYIkK/mHVS3lm428jIjHBtx9E/FKA//wdVq2vbgHJO8wWLabLUboR0jdgshJ2tfvJPVmE43FWh2XyYY+KtJr6s5jCGMeGbHpz1CLisULp
#
#  INSTALLATION
#
#  Source this script from your ~/.bash_profile (since OS X runs ~/.bash_profile for each
#  new Terminal.app tab). Note that you'll want it in ~/.bashrc on other OSes. 
#
#  mkdir -p ~/bin/ && cp gpg-agent-functions.sh ~/bin/
#  echo source ~/bin/gpg-agent-functions.sh >> ~/.bash_profile
#
#  n.b. Mac only support for now due to the use of `launchctl getenv` 
#

export SSH_AUTH_SOCK=~/.ssh-auth-sock

function _gpg_agent_kill {
	# TODO: error out after a few tries
	STATUS=0
	while [ $STATUS -eq 0 ]; do
		pkill -U $UID gpg-agent > /dev/null
		pgrep -U $UID gpg-agent > /dev/null
		STATUS=$?
	done
}

## match symlink to gpg-agent status without starting or stopping it
function gpg-agent-noop {
	pgrep -U $UID gpg-agent > /dev/null

	if [ $? -eq 0 ]; then
		# gpg-agent running
		# symlink SSH_AUTH_SOCK to .gnupg version
		ln -fs ~/.gnupg/S.gpg-agent.ssh ~/.ssh-auth-sock
	else
		# gpg-agent not running, use system ssh-agent
		# symlink SSH_AUTH_SOCK to launchct getenv versino
		ln -fs $(launchctl getenv SSH_AUTH_SOCK) ~/.ssh-auth-sock
	fi
}

## UP
function gpg-agent-up {
	# kill old agent
	_gpg_agent_kill

	# start new agent
	ENV_VARS=$(gpg-agent --daemon -s --enable-ssh-support --use-standard-socket)

	# symlink SSH_AUTH_SOCK to .gnupg version
	ln -fs ~/.gnupg/S.gpg-agent.ssh ~/.ssh-auth-sock
}

## DOWN
function gpg-agent-down {
	# kill old agent
	_gpg_agent_kill

	# symlink SSH_AUTH_SOCK to launchct getenv versino
	ln -fs $(launchctl getenv SSH_AUTH_SOCK) ~/.ssh-auth-sock
}

gpg-agent-noop
