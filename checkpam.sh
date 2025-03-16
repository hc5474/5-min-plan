#!/bin/bash
# Check /etc/pam.d for insecure configurations and prompt for reinstalling PAM


apt update && apt install —reinstall libpam-runtime libpam-modules


