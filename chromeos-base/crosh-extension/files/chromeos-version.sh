#!/bin/sh
# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

exec gawk \
  '$1 == "\"version\":" {print gensub(/[",]/, "", "g", $NF)}' \
  "$1"/nassh/manifest_v1.5.json
