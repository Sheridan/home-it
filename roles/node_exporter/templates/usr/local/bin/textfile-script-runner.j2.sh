#!/bin/bash

{{ script.command }} 1>{{ merged_vars.node_exporter.textfile_dir }}/{{ script.name }}.prom
