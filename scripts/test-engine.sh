#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
build_dir=$(mktemp -d /tmp/isueca-engine.XXXXXX)
swiftc -module-cache-path "$build_dir/cache" iSueca/Models/Card.swift iSueca/Models/Player.swift iSueca/Models/Trick.swift iSueca/Engine/*.swift iSueca/AI/*.swift Tests/EngineChecks.swift -o "$build_dir/checks"
"$build_dir/checks"
