ARG MYAPP_IMAGE=default
ARG DEVENVY_WORKSPACE=default
FROM $MYAPP_IMAGE

LABEL maintainer="@iwahjoedi"

ENV LANGUAGE=en_US:en
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Configure User
ARG user=devenvy
ARG group=devenvy
ARG uid=1000
ARG gid=1000

RUN groupadd -g ${gid} ${group}
RUN useradd -u ${uid} -g ${group} -s /bin/bash -m ${user}

USER ${uid}:${gid}

# Install NVM
#RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && \
#  export NVM_DIR="$HOME/.nvm" && \
#  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
#  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && \
#  nvm install --lts && \
#  npm install -g node-gyp

# Install Yarn
#RUN npm install -g yarn

WORKDIR /home/${user}

COPY ${DEVENVY_WORKSPACE} ${DEVENVY_WORKSPACE}

#VOLUME [ "/sites-public", "/build-cache" ]
VOLUME [ "${DEVENVY_WORKSPACE}", "${DEVENVY_WORKSPACE}" ]

#CMD [ "./build.sh" ]