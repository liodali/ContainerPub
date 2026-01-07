---
title: CI/CD Integration
description: Integrate dart_cloud_deploy with CI/CD pipelines for automated deployments
---

# CI/CD Integration

This guide covers integrating the Backend Deploy CLI with various CI/CD platforms for automated deployments.

## Overview

The `dart_cloud_deploy` CLI is designed to work seamlessly in CI/CD environments:

- **Non-interactive mode** - All options can be passed via command line
- **Exit codes** - Proper exit codes for pipeline status
- **Secrets handling** - Support for environment variables and secret managers
- **Dry run** - Preview deployments before executing

## GitHub Actions

### Basic Deployment Workflow

```yaml
name: Deploy Backend

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Dart
        uses: dart-lang/setup-dart@v1
        with:
          sdk: "3.10.4"

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install Deploy CLI
        run: |
          cd tools/dart_packages/dart_cloud_deploy_cli
          dart pub get
          dart pub global activate --source path .

      - name: Initialize Environment
        run: dart_cloud_deploy init

      - name: Setup SSH Key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.SERVER_HOST }} >> ~/.ssh/known_hosts

      - name: Create Config
        run: |
          cat > deploy.yaml << EOF
          name: dart_cloud_backend
          environment: production
          project_path: .
          env_file_path: .env

          container:
            runtime: podman
            compose_file: docker-compose.yml
            project_name: dart_cloud
            services:
              backend: dart_cloud_backend
              postgres: dart_cloud_postgres

          host:
            host: ${{ secrets.SERVER_HOST }}
            port: 22
            user: ${{ secrets.SERVER_USER }}
            ssh_key_path: ~/.ssh/id_rsa

          ansible:
            extra_vars:
              app_dir: /opt/dart_cloud
          EOF

      - name: Create .env file
        run: |
          cat > .env << EOF
          DATABASE_URL=${{ secrets.DATABASE_URL }}
          JWT_SECRET=${{ secrets.JWT_SECRET }}
          API_KEY=${{ secrets.API_KEY }}
          EOF

      - name: Deploy
        run: dart_cloud_deploy deploy-dev --skip-secrets

    environment:
      name: production
      url: https://api.example.com
```

### Multi-Environment Workflow

```yaml
name: Deploy

on:
  push:
    branches:
      - main
      - develop
  workflow_dispatch:
    inputs:
      environment:
        description: "Environment to deploy"
        required: true
        default: "dev"
        type: choice
        options:
          - dev
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest

    env:
      ENVIRONMENT: ${{ github.event.inputs.environment || (github.ref == 'refs/heads/main' && 'production' || 'dev') }}

    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install CLI
        run: |
          cd tools/dart_packages/dart_cloud_deploy_cli
          dart pub get
          dart pub global activate --source path .

      - name: Initialize
        run: dart_cloud_deploy init

      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa

      - name: Deploy to Dev
        if: env.ENVIRONMENT == 'dev'
        run: dart_cloud_deploy deploy-dev -c deploy-dev.yaml --skip-secrets
        env:
          SERVER_HOST: ${{ secrets.DEV_SERVER_HOST }}

      - name: Deploy to Staging
        if: env.ENVIRONMENT == 'staging'
        run: dart_cloud_deploy deploy-dev -c deploy-staging.yaml --skip-secrets
        env:
          SERVER_HOST: ${{ secrets.STAGING_SERVER_HOST }}

      - name: Deploy to Production
        if: env.ENVIRONMENT == 'production'
        run: dart_cloud_deploy deploy-dev -c deploy-prod.yaml --skip-secrets
        env:
          SERVER_HOST: ${{ secrets.PROD_SERVER_HOST }}
```

### Deployment with Approval

```yaml
name: Production Deploy

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and test
        run: |
          dart pub get
          dart test

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://api.example.com

    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install and Deploy
        run: |
          cd tools/dart_packages/dart_cloud_deploy_cli
          dart pub get
          dart pub global activate --source path .
          dart_cloud_deploy init
          dart_cloud_deploy deploy-dev -c deploy-prod.yaml --skip-secrets
```

## GitLab CI/CD

### Basic Pipeline

```yaml
stages:
  - build
  - deploy

variables:
  DART_VERSION: "3.10.4"

build:
  stage: build
  image: dart:$DART_VERSION
  script:
    - dart pub get
    - dart test
  only:
    - main
    - develop

deploy_dev:
  stage: deploy
  image: dart:$DART_VERSION
  before_script:
    - apt-get update && apt-get install -y python3 python3-venv openssh-client
    - cd tools/dart_packages/dart_cloud_deploy_cli
    - dart pub get
    - dart pub global activate --source path .
    - export PATH="$PATH:$HOME/.pub-cache/bin"
  script:
    - dart_cloud_deploy init
    - mkdir -p ~/.ssh
    - echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - ssh-keyscan -H $SERVER_HOST >> ~/.ssh/known_hosts
    - dart_cloud_deploy deploy-dev -c deploy-dev.yaml --skip-secrets
  environment:
    name: development
    url: https://dev-api.example.com
  only:
    - develop

deploy_prod:
  stage: deploy
  image: dart:$DART_VERSION
  before_script:
    - apt-get update && apt-get install -y python3 python3-venv openssh-client
    - cd tools/dart_packages/dart_cloud_deploy_cli
    - dart pub get
    - dart pub global activate --source path .
    - export PATH="$PATH:$HOME/.pub-cache/bin"
  script:
    - dart_cloud_deploy init
    - mkdir -p ~/.ssh
    - echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - ssh-keyscan -H $SERVER_HOST >> ~/.ssh/known_hosts
    - dart_cloud_deploy deploy-dev -c deploy-prod.yaml --skip-secrets
  environment:
    name: production
    url: https://api.example.com
  only:
    - main
  when: manual
```

## Jenkins

### Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        DART_HOME = tool 'dart-sdk'
        PATH = "${DART_HOME}/bin:${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup') {
            steps {
                sh '''
                    cd tools/dart_packages/dart_cloud_deploy_cli
                    dart pub get
                    dart pub global activate --source path .
                '''
            }
        }

        stage('Initialize') {
            steps {
                sh 'dart_cloud_deploy init'
            }
        }

        stage('Deploy to Dev') {
            when {
                branch 'develop'
            }
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'deploy-ssh-key', keyFileVariable: 'SSH_KEY'),
                    string(credentialsId: 'dev-server-host', variable: 'SERVER_HOST')
                ]) {
                    sh '''
                        mkdir -p ~/.ssh
                        cp $SSH_KEY ~/.ssh/id_rsa
                        chmod 600 ~/.ssh/id_rsa
                        ssh-keyscan -H $SERVER_HOST >> ~/.ssh/known_hosts
                        dart_cloud_deploy deploy-dev -c deploy-dev.yaml --skip-secrets
                    '''
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            input {
                message "Deploy to production?"
                ok "Deploy"
            }
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'deploy-ssh-key', keyFileVariable: 'SSH_KEY'),
                    string(credentialsId: 'prod-server-host', variable: 'SERVER_HOST')
                ]) {
                    sh '''
                        mkdir -p ~/.ssh
                        cp $SSH_KEY ~/.ssh/id_rsa
                        chmod 600 ~/.ssh/id_rsa
                        ssh-keyscan -H $SERVER_HOST >> ~/.ssh/known_hosts
                        dart_cloud_deploy deploy-dev -c deploy-prod.yaml --skip-secrets
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
```

## CircleCI

### config.yml

```yaml
version: 2.1

orbs:
  dart: circleci/dart@2.0

jobs:
  build:
    docker:
      - image: dart:3.10.4
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: dart pub get
      - run:
          name: Run tests
          command: dart test

  deploy:
    docker:
      - image: dart:3.10.4
    parameters:
      environment:
        type: string
        default: "dev"
    steps:
      - checkout
      - run:
          name: Install system dependencies
          command: apt-get update && apt-get install -y python3 python3-venv openssh-client
      - run:
          name: Install Deploy CLI
          command: |
            cd tools/dart_packages/dart_cloud_deploy_cli
            dart pub get
            dart pub global activate --source path .
      - run:
          name: Initialize
          command: dart_cloud_deploy init
      - run:
          name: Setup SSH
          command: |
            mkdir -p ~/.ssh
            echo "$SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa
            chmod 600 ~/.ssh/id_rsa
            ssh-keyscan -H $SERVER_HOST >> ~/.ssh/known_hosts
      - run:
          name: Deploy
          command: dart_cloud_deploy deploy-dev -c deploy-<< parameters.environment >>.yaml --skip-secrets

workflows:
  build-and-deploy:
    jobs:
      - build
      - deploy:
          name: deploy-dev
          environment: dev
          requires:
            - build
          filters:
            branches:
              only: develop
      - deploy:
          name: deploy-prod
          environment: prod
          requires:
            - build
          filters:
            branches:
              only: main
```

## Best Practices

### 1. Use Environment-Specific Configs

Create separate configuration files for each environment:

```
deploy-local.yaml
deploy-dev.yaml
deploy-staging.yaml
deploy-prod.yaml
```

### 2. Store Secrets Securely

Never commit secrets to version control. Use:

- **GitHub Actions**: Repository secrets
- **GitLab CI**: CI/CD variables (masked)
- **Jenkins**: Credentials plugin
- **CircleCI**: Environment variables

### 3. Use Dry Run for Testing

Always test with `--dry-run` first:

```yaml
- name: Dry Run
  run: dart_cloud_deploy deploy-dev --dry-run

- name: Deploy
  run: dart_cloud_deploy deploy-dev
```

### 4. Add Health Checks

Verify deployment success:

```yaml
- name: Deploy
  run: dart_cloud_deploy deploy-dev

- name: Health Check
  run: |
    sleep 30
    curl -f https://api.example.com/health || exit 1
```

### 5. Use Deployment Environments

Configure environments for approval workflows:

```yaml
environment:
  name: production
  url: https://api.example.com
```

### 6. Cache Dependencies

Speed up pipelines by caching:

```yaml
- name: Cache Dart packages
  uses: actions/cache@v3
  with:
    path: ~/.pub-cache
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}

- name: Cache Python venv
  uses: actions/cache@v3
  with:
    path: .venv
    key: ${{ runner.os }}-venv-${{ hashFiles('**/requirements.txt') }}
```

### 7. Rollback Strategy

Implement rollback capability:

```yaml
- name: Deploy
  id: deploy
  run: dart_cloud_deploy deploy-dev
  continue-on-error: true

- name: Rollback on Failure
  if: steps.deploy.outcome == 'failure'
  run: |
    echo "Deployment failed, rolling back..."
    dart_cloud_deploy deploy-dev -e app_version=${{ env.PREVIOUS_VERSION }}
```

## Secrets Management

### Using OpenBao in CI/CD

If you have OpenBao/Vault available in your CI environment:

```yaml
- name: Setup OpenBao Token
  run: |
    mkdir -p ~/.openbao
    echo "${{ secrets.OPENBAO_TOKEN }}" > ~/.openbao/token

- name: Deploy with Secrets
  run: dart_cloud_deploy deploy-dev # Will fetch secrets automatically
```

### Manual .env Generation

For environments without OpenBao:

```yaml
- name: Create .env
  run: |
    cat > .env << EOF
    DATABASE_URL=${{ secrets.DATABASE_URL }}
    JWT_SECRET=${{ secrets.JWT_SECRET }}
    REDIS_URL=${{ secrets.REDIS_URL }}
    EOF

- name: Deploy
  run: dart_cloud_deploy deploy-dev --skip-secrets
```

## Troubleshooting CI/CD

### SSH Connection Issues

```yaml
- name: Debug SSH
  run: |
    ssh -vvv -i ~/.ssh/id_rsa $USER@$HOST echo "Connection successful"
```

### Ansible Verbose Output

```yaml
- name: Deploy with Debug
  run: dart_cloud_deploy deploy-dev -v
```

### Check Exit Codes

```yaml
- name: Deploy
  run: |
    dart_cloud_deploy deploy-dev
    echo "Exit code: $?"
```

## Next Steps

- Review [Commands Reference](./commands.md) for all options
- Check [Quick Start](./quickstart.md) for local testing
- See [Overview](./index.md) for architecture details
