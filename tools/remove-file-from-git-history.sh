#!/bin/bash

filename=$1
tmp_dir=/tmp/rffgh
tmp_filename=$(date +"%Y_%m_%d_%H_%M_%S")

mkdir -p ${tmp_dir}
cat ${filename} > ${tmp_dir}/${tmp_filename}
git filter-branch --index-filter "git rm -rf --cached --ignore-unmatch ${filename}" HEAD
git push --all
cat ${tmp_dir}/${tmp_filename} > ${filename}
git add ${filename}
git commit -m "Removing ${tmp_filename} from history"
git push
