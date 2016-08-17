#!/bin/bash

# TODO: Incorporate ideas from: https://github.com/necolas/dotfiles

if [ -z "$HOME" ]; then
    echo "ERROR: 'HOME' environment variable is not set!"
    exit 1
fi
# Source https://github.com/bash-origin/bash.origin
if [ -z "${BO_LOADED}" ]; then
    if [ ! -f "$HOME/.bash.origin" ]; then
        curl -s -o ".bash.origin" "https://raw.githubusercontent.com/bash-origin/bash.origin/master/bash.origin"
        chmod u+x ./.bash.origin
        export BO_VERBOSE=1
        ./.bash.origin BO install
    fi
    . "$HOME/.bash.origin"
fi
function init {
    eval BO_SELF_BASH_SOURCE="$BO_READ_SELF_BASH_SOURCE"
    BO_deriveSelfDir ___TMP___ "$BO_SELF_BASH_SOURCE"
    local __BO_DIR__="$___TMP___"


    local IS_SOURCING="${BO_IS_SOURCING}"


    function BO_Provision_OSX_ensureBaseTools {

        # Xcode command-line tools
        # @see http://osxdaily.com/2014/02/12/install-command-line-tools-mac-os-x/
        xcode-select --install
    }

    function BO_Provision_OSX_Brew_Caskroom_ensure {
        # Homebrew
        # @see http://brew.sh
        if ! BO_has brew ; then
            url="https://raw.githubusercontent.com/Homebrew/install/master/install"
            BO_log "$VERBOSE" "Install Homebrew from '$url'"
            ruby -e "$(curl -fsSL $url)"
            unset url
        fi
        # Cask
        # @see http://caskroom.io
        BO_log "$VERBOSE" "Ensuring 'cask' for Homebrew"
        # TODO: Detect if installed without calling install.
        brew tap caskroom/cask

        BO_log "$VERBOSE" "Ensuring '$1' is installed using Homebrew Caskroom"
        brew cask install "$1"
    }


    # Installs an editor that can be used to edit provisioning scripts.
    function BO_Provision_ensureEditor {

        # TODO: Support operating systems other than OSX
        # @see https://atom.io
        BO_Provision_OSX_Brew_Caskroom_ensure “atom”
    }



    function BO_Provision_ensureTopLevelDirectory {
        if [ ! -e "$1" ]; then
            echo "Using [sudo] to create path at '$1' accessible by '$USER'"
            sudo mkdir "$1"
            sudo chown "$USER:staff" "$1"
        fi
    }

    function BO_Provision_ensureGitWorkingRepositoryAt {
        if [ ! -e "$1/.git" ]; then
            echo "Cloning '$2' into '$1'"
            if [ ! -e "$1" ]; then
                git clone "$2" "$1"
            else
                if [ "$(ls -A $1)" ]; then
                    echo "ERROR: Cannot clone into directory '$1' because it is not empty!"
                    exit 1
                else
                    git clone "$2" "$1/.bo_tmp_clone"
                    mv -f "$1/.bo_tmp_clone/".* "$1/" || true
                    mv -f "$1/.bo_tmp_clone/"* "$1/" || true
                    rm -Rf "$1/.bo_tmp_clone"
                fi
            fi
        fi
    }

    function Provision_OSX {
        BO_format "$VERBOSE" "HEADER" "Provision OSX ..."

        local topLevelDirectory="$1"
        local topLevelRepository="$2"

        if [ -z "$topLevelDirectory" ]; then
            echo "ERROR: 'topLevelDirectory' not specified using first argument!"
            exit 1
        fi
        if [ -z "$topLevelRepository" ]; then
            echo "ERROR: 'topLevelRepository' not specified using second argument!"
            exit 1
        fi

        BO_Provision_OSX_ensureBaseTools
        BO_Provision_ensureEditor

        BO_Provision_ensureTopLevelDirectory "$topLevelDirectory"
        BO_Provision_ensureGitWorkingRepositoryAt "$topLevelDirectory" "$topLevelRepository"

        BO_format "$VERBOSE" "FOOTER"
    }


    if [ -z "${IS_SOURCING}" ]; then
        # TODO: Support operating systems other than OSX
        Provision_OSX "$@"
    fi
}
init $@
