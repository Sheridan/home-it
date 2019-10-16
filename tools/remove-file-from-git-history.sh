#!/bin/bash

filename=$1
tmp_dir=/tmp/rffgh
tmp_filename=$(date +"%Y_%m_%d_%H_%M_%S")

mkdir -p ${tmp_dir}
cat ${filename} > ${tmp_dir}/${tmp_filename}
git update-ref -d refs/original/refs/heads/master
git filter-branch --index-filter "git rm -rf --cached --ignore-unmatch ${filename}" HEAD
git push --force
mkdir -p $(dirname "${filename}")
cat ${tmp_dir}/${tmp_filename} > ${filename}
git add ${filename}
git commit -m "✖ Removing \`${filename}\` from history"
git push
