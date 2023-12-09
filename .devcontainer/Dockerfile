#
# https://github.com/pgit/cpp-devcontainer/
#
FROM docker.io/psedoc/cpp-devcontainer:ltest

#
# enable persistent bash history in container (needs custom volume, see devcontainer.json)
#
# https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
#
ARG USERNAME=vscode
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

SHELL ["/bin/bash", "-c"]
