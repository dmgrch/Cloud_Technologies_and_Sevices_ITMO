# Лабораторная работа 3: CI/CD Гуд и Бэд practices

## БЭД CI/CD файл

```
name: Bad CI/CD Pipeline

on: push

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Install dependencies
        run: npm install
      
      - name: Run tests
        continue-on-error: true
        run: npm test
      
      - name: Build application
        run: npm run build
      
      - name: Deploy to production
        run: |
          echo "Deploying to server..."
          API_KEY="hardcoded-secret-key-12345"
          SERVER_PASSWORD="prod_password"
          echo "Using hardcoded API key: $API_KEY"
          echo "Deployment simulation completed"
```

## ГУД CI/CD файл

```
name: Good CI/CD Pipeline

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test

  build:
    needs: test
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build application
        run: npm run build
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: build-artifacts
          path: dist/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
      - name: Download build artifacts
        uses: actions/download-artifact@v4
        with:
          name: build-artifacts
          path: dist/
      
      - name: Deploy to production
        env:
          API_KEY: ${{ secrets.DEPLOY_API_KEY }}
          SERVER_PASSWORD: ${{ secrets.SERVER_PASSWORD }}
        run: |
          echo "Deploying to server..."
          echo "Using API key starting with: ${API_KEY:0:4}..."
          echo "Deployment simulation completed"
```

## Описание БЭД практик и их fixes

### БЭД practice 1 - secrets

```
API_KEY="hardcoded-secret-key-12345"
SERVER_PASSWORD="prod_password"
```

**Почему плохо:**
- секретные ключи и пароли хранятся прямо в коде (невозможно менять секреты без изменения кода)
- любой, кто имеет доступ к репозиторию, может их увидеть
- не безопасносно


**ГУД файл:**
```
env:
  API_KEY: ${{ secrets.DEPLOY_API_KEY }}
  SERVER_PASSWORD: ${{ secrets.SERVER_PASSWORD }}
```

**Влияние:**
- Секреты хранятся в настройках GitHub
- Секреты не отображаются в логах pipeline (безопасный доступ только во время выполнения пайплайна)
- можно легко изменить секреты без изменения кода
- повышается безопасность


### БЭД practice 2 - continue-on-error для тестов

```
- name: Run tests
  continue-on-error: true
  run: |
    npm test
```

**Почему плохо:**
- pipeline продолжает работу, даже если тесты провалились
- баги могут попасть в production
- нельзя гарантировать качество кода

**ГУД файл:**

- удален `continue-on-error: true`
- тесты выполняются в отдельном джобе test
```
jobs:
  test:
```
- сборка зависит от успешного прохождения тестов
```
build:
    needs: test
```

**Влияние:**
- pipeline останавливается при падении тестов (в deploy идет проверенный код)
- раннее обнаружение ошибок
- хорошая последовательность: тест-build-deploy



### БЭД practice 3 - отсутствие кэширования зависимостей

```
- name: Install dependencies
  run: |
    npm install
```

**Почему плохо:**
- каждый раз зависимости загружаются заново
- медленная установка зависимостей, неэффективность
- используется `npm install` вместо `npm ci` (нестабильно)

**ГУД файл:**
```
- name: Setup Node.js
  uses: actions/setup-node@v3
  with:
    node-version: '18'
    cache: 'npm'

- name: Install dependencies
  run: npm ci
```

**Влияние:**
- зависимости кэшируются между запусками
- ускорение выполнения
- используется `npm ci` для воспроизводимых, нужных сборок



### Как еще улучшили файл?

**Разделили на отдельные jobs:**

В БЭД файле: один джоб `build-and-deploy`, который делает все

В ГУД файле:
- тесты, сборка и деплой выполняются отдельно
- легче понять, на каком этапе произошла ошибка
- можно запускать только нужные этапы


**Использовали стратегии для запуска:**

В БЭД файле: `on: push`

Почему плохо: pipeline запускается на каждый пуш в любую ветку, возможный деплой нестабильного кода

В ГУД файле:

```
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
```
- pipeline запускается только для main
- нет лишних запусков


**Защита production деплоя:**

В БЭД файле: деплой выполняется всегда

В ГУД файле:
```
if: github.ref == 'refs/heads/main'
environment: production
```
- деплой происходит только из main
- используется environment для дополнительных проверок


## Что получилось?

фото 1

фото 2

## Выводы
В ходе лабораторной работы мы написали 2 CI/CD файла - хороший и плохой, выявили и исправили ошибки написания этих файлов.
