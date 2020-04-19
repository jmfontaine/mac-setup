.DEFAULT_GOAL := help
.SILENT:

# If the first argument is "setup"...
ifeq (setup,$(firstword $(MAKECMDGOALS)))
  # use the rest as tags
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  TAGS_ARG := $(if $(RUN_ARGS),--tags $(RUN_ARGS),)
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif

## Display usage
help:
	@awk '/^[a-zA-Z\-\_0-9%:\\\/]+:/ { \
	  helpMessage = match(lastLine, /^## (.*)/); \
	  if (helpMessage) { \
	    helpCommand = $$1; \
	    helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
      gsub("\\\\", "", helpCommand); \
      gsub(":+$$", "", helpCommand); \
	    printf "  \x1b[32;01m%-35s\x1b[0m %s\n", helpCommand, helpMessage; \
	  } \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u
	@printf "\n"

## Install requirements
requirements:
	echo '=== Checking requirements ==='
	echo -n '- Homebrew: '
	command -v brew >/dev/null 2>&1 && echo 'Installed' || { echo 'Please install Homebrew (https://brew.sh/) and run this command again'; false; }
	echo -n '- Ansible: '
	command -v ansible >/dev/null 2>&1 && echo 'Installed' || { echo 'Installing…'; brew install ansible; }

## Setup the local Mac. Tags can be provided: 'make setup zsh' or 'make setup zsh,dotfiles'
setup:
	echo '=== Installing Ansible Galaxy roles ==='
	ansible-galaxy install --role-file requirements.yml
	echo '=== Running Ansible playbook ==='
	ansible-playbook $(TAGS_ARG) playbook.yml

## List available tags
tags:
	ansible-playbook --list-tags playbook.yml | grep "TASK TAGS" | cut -d":" -f2 | awk '{sub(/\[/, "")sub(/\]/, "")}1' | sed -e 's/,//g' | xargs -n 1 | sort -u
