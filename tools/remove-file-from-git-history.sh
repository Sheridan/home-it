#!/bin/bash

filename=$1
tmp_dir=/tmp/rffgh
tmp_filename=$(date +"%Y_%m_%d_%H_%M_%S")

mkdir -p ${tmp_dir}
cat ${filename} > ${tmp_dir}/${tmp_filename}
git rm --cached ${filename}
git commit --amend -CHEAD -m "Removing ${tmp_filename} from history"
cat ${tmp_dir}/${tmp_filename} > ${filename}
git add ${filename}
git commit --amend -CHEAD -m "Restoring ${tmp_filename}"
