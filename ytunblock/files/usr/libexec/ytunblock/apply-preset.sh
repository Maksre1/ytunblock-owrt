#!/bin/sh
# Применение пресета: apply-preset.sh <name>

PRESET="$1"
DIR="/usr/share/ytunblock/presets"

case "$PRESET" in
	default|russia_balanced|russia_balanced_discord|russia_aggressive|lite)
		[ -x "$DIR/${PRESET}.sh" ] && exec "$DIR/${PRESET}.sh"
		;;
esac

echo "Unknown preset: $PRESET" >&2
exit 1
