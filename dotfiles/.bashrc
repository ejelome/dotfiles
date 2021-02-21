#!/bin/bash
#
# ~/.bashrc

# homebrew
export PATH="/opt/homebrew/bin:$PATH"

# starship
eval "$(starship init bash)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh" # This loads nvm
[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && . "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# auto nvm-use
find-up() {
    path=$(pwd)

    while [[ "$path" != "" && ! -e "$path/$1" ]]; do
        path=${path%/*}
    done

    echo "$path"
}
#
cdnvm() {
    cd "$@";
    nvm_path=$(find-up .nvmrc | tr -d '\n')

    # If there are no .nvmrc file, use the default nvm version
    if [[ ! $nvm_path = *[^[:space:]]* ]]; then

        declare default_version;
        default_version=$(nvm version default);

        # If there is no default version, set it to `node`
        # This will use the latest version on your machine
        if [[ $default_version == "N/A" ]]; then
            nvm alias default node;
            default_version=$(nvm version default);
        fi

        # If the current version is not the default version, set it to use the default version
        if [[ $(nvm current) != "$default_version" ]]; then
            nvm use default;
        fi

    elif [[ -s $nvm_path/.nvmrc && -r $nvm_path/.nvmrc ]]; then
        declare nvm_version
        nvm_version=$(<"$nvm_path"/.nvmrc)

        declare locally_resolved_nvm_version
        # `nvm ls` will check all locally-available versions
        # If there are multiple matching versions, take the latest one
        # Remove the `->` and `*` characters and spaces
        # `locally_resolved_nvm_version` will be `N/A` if no local versions are found
        locally_resolved_nvm_version=$(nvm ls --no-colors "$nvm_version" | tail -1 | tr -d '\->*' | tr -d '[:space:]')

        # If it is not already installed, install it
        # `nvm install` will implicitly use the newly-installed version
        if [[ "$locally_resolved_nvm_version" == "N/A" ]]; then
            nvm install "$nvm_version";
        elif [[ $(nvm current) != "$locally_resolved_nvm_version" ]]; then
            nvm use "$nvm_version";
        fi
    fi
}
#
alias cd='cdnvm'
#
cd $PWD

# emacs in terminal
export PATH="~/bin:$PATH"
export ALTERNATE_EDITOR=""
export EDITOR=emacsclient
#
alias emacs='ec -nw'

# shutdown
function shutdown_() {
    [[ -d ~/.emacs.d/.cache/ ]] && rm -rf ~/.emacs.d/.cache/
    [[ -d ~/.cache/Cypress/ ]] && rm -rf ~/.cache/!Cypress/
    [[ -f ~/.bash_history ]] && rm ~/.bash_history
    history -c
    shutdown "$@"
}
#
alias shutdown='shutdown_'
