#!/bin/bash
# Stata 19 License Initialization for Workbench
# Run this if you have the Stata license credentials.
#
# Usage: sudo bash ~/repos/workbench-examples/stata/run_stinit.sh
#
# You will be prompted for your serial number, code, and authorization.

set -e

INSTALLDIR="/home/jupyter/workspace/uploads/stata/stata19"
LOCALDIR="/tmp/stata19_stinit"

if [ ! -d "$INSTALLDIR" ]; then
    echo "ERROR: Stata installation not found at $INSTALLDIR"
    exit 1
fi

echo "=== Step 1: Copy Stata to local directory (GCS mount blocks chmod) ==="
rm -rf "$LOCALDIR"
cp -r "$INSTALLDIR" "$LOCALDIR"
cd "$LOCALDIR"
chmod +x stinit stata-mp stata-se stata 2>/dev/null || true
echo "Copied to $LOCALDIR"

echo ""
echo "=== Step 2: Run license initialization ==="
echo "You will be prompted for your serial number, code, and authorization."
echo ""
./stinit

echo ""
echo "=== Step 3: Copy license file to persistent storage ==="
if [ -f "$LOCALDIR/stata.lic" ]; then
    cp "$LOCALDIR/stata.lic" "$INSTALLDIR/stata.lic"
    echo "License file copied to $INSTALLDIR/stata.lic"
    echo ""
    echo "=== Done! ==="
    echo "In Python:"
    echo "  import stata_setup"
    echo "  stata_setup.config(\"$INSTALLDIR\", \"mp\")"
else
    echo "WARNING: stata.lic not found. License initialization may have failed."
fi
