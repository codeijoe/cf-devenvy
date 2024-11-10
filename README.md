<!-- AUTO-GENERATED-CONTENT:START (STARTER) -->
<h1 align="center">
  <img alt="Logo" src="cf-devenvy.png" height="100px" />
  <br/>
  Cloudflare Development Environment
</h1>

# cf-devenvy
Cloudflare Development Environment for Docker.

You can place your codes inside workspace folder.


CAUTION!!
  -  Wrangler CLI install locally on package.json


## 🚀 Quick Start

1.  **Download this repo**

    ```sh
    git clone https://github.com/codeijoe/cf-devenvy
    ```

2.  **Create .env file from example**

    Use the `env-example` file to a create a file called `.env` in the server directory. This file contains all the necessary enviroment variables like the admin password.


3.  **Build empty environment**

    Simply run the install script in the downloaded directory.

    ```sh
    $ bash dev.sh build
    ```

4.  **Start/Stop environment**

    Simply run the install script in the downloaded directory.

    ```sh
    $ bash dev.sh start
    $ bash dev.sh stop
    ```


## 📌 Available Commands 
- [x] build
- [x] devrun
- [x] build




## 📌 Tools Available
- [x] Wrangler 
-

## 📌 ToDo

- [x] Development environment entirely on docker not on host.  
- [x] Use dynamic NodeJS version in Builder using NVM.
- [ ] Remote Deployment
- [ ] Add frontend to control sites and builds.
- [ ] Add support for other static site generators than Gatsby.
- [ ] Implement a message broker.
- [ ] Deploy status badge.
- [ ] Split server and builder into dedicated docker containers.
