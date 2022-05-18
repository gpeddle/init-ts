#!/bin/bash

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "1 argument required, $# provided. Exiting."

command -v jq >/dev/null 2>&1 || die "jq required but not installed. Exiting."

PROJECT=$1

if test -d "$PROJECT"; then
    echo "$PROJECT already exists."
    exit;
fi

echo "Setting up new TS project '$PROJECT'"

DIR="./$PROJECT"

mkdir "$DIR" 
mkdir "$DIR/src" 
mkdir "$DIR/dist" 
mkdir "$DIR/docs" 
mkdir "$DIR/.vscode" 
cd "$DIR"

git init --initial-branch=main .

cat > .gitignore <<- EOM
node_modules
dist
EOM

npm init -y
npm install --save-dev typescript @types/node
npm install --save-dev concurrently ts-node nodemon
npm install dotenv tslog

cat > tsconfig.json <<- EOM
{
  "compilerOptions": {
    "target": "es2016",
    "module": "commonjs",
    "rootDir": "src", 
    "outDir": "dist",                                        
    "forceConsistentCasingInFileNames": true,            
    "strict": true,                                      
    "skipLibCheck": true,  
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": [
    "node_modules", 
    "**/*.test.ts"]
}
EOM

# NPM package.json customization
npm set-script build "tsc --build"
npm set-script clean "tsc --build --clean"
npm set-script debug "nodemon --inspect src/index.ts"

# JQ needed here
jq '. * {main: "dist/index.js"}' package.json > jq.tmp && cp jq.tmp package.json 


# starter script 
cat > src/index.ts <<- EOM
// example application
import dotenv from 'dotenv';
import { Logger } from "tslog";

dotenv.config();

const log: Logger = new Logger();

log.info("Hello, $PROJECT");

EOM

# ESLint
cat > .eslint <<- EOM
{
    "root": true,
    "parser": "@typescript-eslint/parser",
    "plugins": [
        "@typescript-eslint"
    ],
    "extends": [
        "eslint:recommended",
        "plugin:@typescript-eslint/eslint-recommended",
        "plugin:@typescript-eslint/recommended"
    ],
    "rules": { 
        "no-console": 2
    }
}
EOM

# ESLint ignore
cat > .eslintignore <<- EOM
node_modules
dist
EOM

# vscode settings
cat > .vscode/settings.json <<- EOM
{}
EOM

cat > .vscode/launch.json <<- EOM
{
    "version": "0.2.0",
    "configurations": [
        {
            "console": "integratedTerminal",
            "internalConsoleOptions": "neverOpen",
            "name": "nodemon",
            "program": "${workspaceFolder}/src/index.ts",
            "request": "launch",
            "restart": true,
            "runtimeExecutable": "nodemon",
            "skipFiles": [
                "<node_internals>/**"
            ],
            "type": "node"
        },
    ]
}
EOM

# cleanup
rm jq.tmp
rm tsconfig.jsone

git status
git add .
git commit -m 'empty project'

echo "Project '$PROJECT' created."
