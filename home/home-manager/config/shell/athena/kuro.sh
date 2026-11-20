#!/usr/bin/env bash
# Bootstrap entry point for building the current Home Manager generation when
# the installed kuro command is stale or cannot find the local flake.
exec bash "$(dirname "$0")/kuro-rs/bootstrap.sh" "$@"
