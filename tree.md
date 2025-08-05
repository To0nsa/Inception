# Directory structure

.
├── .gitignore
├── .vscode
│   └── settings.json
├── Makefile
├── README.md
├── secrets
│   ├── certs
│   │   └── myCert.crt
│   ├── mysql_root_password.txt
│   ├── mysql_user_password.txt
│   ├── private
│   │   └── myKey.key
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs
    ├── .env
    ├── .env.example
    ├── docker-compose.yml
    └── requirements
        ├── mariadb
        │   ├── Dockerfile
        │   ├── conf
        │   │   └── 50-server.cnf
        │   └── entrypoint.sh
        ├── nginx
        │   ├── Dockerfile
        │   └── conf
        │       └── default.conf
        └── wordpress
            ├── Dockerfile
            └── entrypoint.sh
