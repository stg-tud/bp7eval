# Run Chrome Headless in a container
#
# What was once a container using the experimental build of headless_shell from
# tip, this container now runs and exposes stable Chrome headless via
# google-chome --headless.
#
# What's New
#
# 1. Pulls from Chrome Stable
# 2. You can now use the ever-awesome Jessie Frazelle seccomp profile for Chrome.
#     wget https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json -O ~/chrome.json
#
#
# To run (without seccomp):
# docker run -d -p 9222:9222 --cap-add=SYS_ADMIN justinribeiro/chrome-headless
#
# To run a better way (with seccomp):
# docker run -d -p 9222:9222 --security-opt seccomp=$HOME/chrome.json justinribeiro/chrome-headless
#
# Basic use: open Chrome, navigate to http://localhost:9222/
#

# Base docker image
FROM debian:stretch-slim
LABEL name="bp7 eval" \
	maintainer="Lars Baumgaertner <baumgaertner@cs.tu-darmstadt.de>" \
	version="0.1" \
	description="Google Chrome Headless in a container for Bundle Protocol 7 evaluation"

# Install deps + add Chrome Stable + purge all the things
RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg \
	--no-install-recommends \
	&& curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
	&& echo "deb https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
	&& apt-get update && apt-get install -y \
	google-chrome-stable \
	fontconfig \
	fonts-ipafont-gothic \
	fonts-wqy-zenhei \
	fonts-thai-tlwg \
	fonts-kacst \
	fonts-symbola \
	fonts-noto \
	ttf-freefont \
	curl \
	psmisc \
	build-essential \
	libssl-dev \
	pkg-config \
	tmux \
	gatling \ 
	screen \
	vim \
	git \
	--no-install-recommends \
	&& rm -rf /var/lib/apt/lists/*

# Add Chrome as a user
RUN groupadd -r chrome && useradd -r -g chrome -G audio,video chrome \
	&& mkdir -p /home/chrome && chown -R chrome:chrome /home/chrome \
	&& mkdir -p /opt/google/chrome && chown -R chrome:chrome /opt/google/chrome

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

RUN echo 'source $HOME/.cargo/env' >> $HOME/.bashrc
RUN bash -c "source $HOME/.cargo/env && rustup target add wasm32-unknown-unknown"
RUN bash -c "source $HOME/.cargo/env && cargo install sccache"
RUN bash -c "source $HOME/.cargo/env && export RUSTC_WRAPPER=sccache && cargo install wasm-bindgen-cli"
RUN bash -c "source $HOME/.cargo/env && export RUSTC_WRAPPER=sccache && cargo install basic-http-server"
RUN bash -c "source $HOME/.cargo/env && export RUSTC_WRAPPER=sccache && cargo install cargo-web"

# Get Go

RUN wget https://dl.google.com/go/go1.12.9.linux-amd64.tar.gz && \
	tar -xf go1.12.9.linux-amd64.tar.gz && \
	mv go /usr/local && \
	ln -s /usr/local/go/bin/go /usr/local/bin/go &&\
	rm go1.12.9.linux-amd64.tar.gz

#COPY bp7wasm /bp7wasm
#COPY /Users/lab/LocalCode/dtn7/dtn7 /dtn7

# Prepare eval software

RUN mkdir /src

COPY bp7wasm /src/bp7wasm
RUN cd /src && git clone https://github.com/dtn7/dtn7-go dtn7-go-v0.1 && cd dtn7-go-v0.1 && git checkout v0.1.0
COPY bp7go-v0.1 /src/dtn7-go-v0.1/tests
RUN cd /src && git clone https://github.com/dtn7/dtn7-go dtn7-go-v0.2 && cd dtn7-go-v0.2 && git checkout v0.2.0
COPY bp7go-v0.2 /src/dtn7-go-v0.2/tests



#RUN sed -i.bak 's/dtn7-go/dtn7/' /src/dtn7-go/go.mod
COPY build.sh /
COPY eval.sh / 

RUN bash -c "export RUSTC_WRAPPER=sccache && /build.sh"

COPY storagetest /src/storagetest

# Run Chrome non-privileged
#USER chrome

# Expose port 9222
EXPOSE 9222
EXPOSE 4000 

VOLUME /output
# Autorun chrome headless with no GPU
#ENTRYPOINT [ "google-chrome" ]
#CMD [ "--headless", "--disable-gpu", "--remote-debugging-address=0.0.0.0", "--remote-debugging-port=9222" ]
ENTRYPOINT [ "/bin/bash" ]