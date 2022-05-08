#!/bin/bash

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "1 argument required, $# provided"

JQ=`which j_q`
[ -f $JQ ] || die "jq not found"

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
cd "$DIR"

git init --initial-branch=main .
echo node_modules >> .gitignore
echo dist >> .gitignore 

npm init -y
npm install --save-dev typescript @types/node @types/express
npx tsc --init

sed -ie '/\/\/.*/d' tsconfig.json 
sed -ie  '/^\s*\/\*.*\*\/$/d' tsconfig.json
sed -ie  's/\/\*.*\*\///g' tsconfig.json
sed -ie  '/^$/d' tsconfig.json

# NPM scripts for build and clean
jq '. * {scripts: {build: "tsc --build"}}' package.json > jq.tmp && cp jq.tmp package.json 
jq '. * {scripts: {clean: "tsc --build --clean"}}' package.json > jq.tmp && cp jq.tmp package.json 


# TSC settings for src and dist // "outDir": "./", 
jq '. + {include: ["src/**/*"]}' tsconfig.json > jq.tmp && cp jq.tmp tsconfig.json 
jq '. * {compilerOptions: {outDir: "./dist"}}' tsconfig.json > jq.tmp && cp jq.tmp tsconfig.json 


# starter script 
echo 'console.log("Hello, world!");' > src/index.ts


rm jq.tmp
rm tsconfig.jsone

git status
git add .
git commit -m 'empty project'


