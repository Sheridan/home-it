#!/bin/bash

echo "$@" | ansible-vault encrypt_string
