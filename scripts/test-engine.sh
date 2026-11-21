#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
build_dir=$(mktemp -d /tmp/isueca-engine.XXXXXX)
swiftc -module-cache-path "$build_dir/cache" iVidiSueca/Models/Card.swift iVidiSueca/Models/Player.swift iVidiSueca/Models/Trick.swift iVidiSueca/Engine/*.swift iVidiSueca/AI/*.swift Tests/EngineChecks.swift -o "$build_dir/checks"
"$build_dir/checks"
