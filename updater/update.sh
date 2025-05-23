#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash nixVersions.nix_2_24 coreutils jq python3 diffutils git

set -e

# TODO: The nix expressions in this script are very bad and need to be cleaned up

SCRIPTPATH=$(dirname $(realpath -s $0))
TMPDIR=$(mktemp -d)

python -c "print(open('$SCRIPTPATH/bare-flake.nix').read().replace('{/*inputs*/}', open('$SCRIPTPATH/../inputs.nix').read()))" > "$SCRIPTPATH/flake.nix"

echo "Updating inputs"
nix --extra-experimental-features nix-command --extra-experimental-features flakes flake update --flake "path:$SCRIPTPATH"

if cmp -s "$SCRIPTPATH/../resolved-flake.lock" "$SCRIPTPATH/flake.lock"; then
    echo "flake.lock has not changed, no updates needed!"
    exit 0
fi

cp "$SCRIPTPATH/flake.lock" "$SCRIPTPATH/../resolved-flake.lock"

echo "Resolving dependencies"
inputs_json=$(nix eval --impure --json --expr "let lib = (import <nixpkgs> {}).lib; inputs = (builtins.getFlake \"path:$SCRIPTPATH\").inputs; fixInputs = i: builtins.mapAttrs (n: v: { follows = \"dep-\${lib.removePrefix \"/nix/store/\" v.outPath}\"; }) i; getInputs = i: lib.flatten (lib.attrsets.mapAttrsToList (n: v: lib.optionals (v ? outPath) [ { \"dep-\${lib.removePrefix \"/nix/store/\" (builtins.unsafeDiscardStringContext v.outPath)}\" = { flake = v ? _type && v._type == \"flake\"; url = v.outPath; inputs = if v ? inputs then fixInputs v.inputs else {}; }; } ] ++ lib.optionals (v ? inputs) (getInputs v.inputs)) i); in (builtins.foldl' (a: b: a // b) {} (getInputs inputs))" | tee $TMPDIR/inputs.json)


echo "Saving dependencies"
mkdir -p "$SCRIPTPATH/../deps/"
rm -rf "$SCRIPTPATH/../deps/"*
for key in $(echo "$inputs_json" | jq -r 'keys[]'); do
    value=$(echo "$inputs_json" | jq -r ".\"$key\".url")
    cp -a "$value" "$SCRIPTPATH/../deps/$key"
done
git -C "$SCRIPTPATH/.." add -N deps

echo "Generating output flake.nix"
nix eval --raw --impure --expr "let lib = (import <nixpkgs> {}).lib; toNix = x: if builtins.isString x then \"\\\"\${x}\\\"\" else if x == true then \"true\" else if x == false then \"false\" else if builtins.isAttrs x then \"{\" + lib.strings.concatStrings (lib.attrsets.mapAttrsToList (n: v: \"\\\"\${n}\\\" = \${toNix v};\") x) + \"}\" else builtins.throw \"cannot handle type\"; fixInputs = i: f: builtins.mapAttrs (n: v: { \${if f then \"follows\" else \"url\"} = \"\${if !f then \"./deps/\" else \"\"}dep-\${lib.removePrefix \"/nix/store/\" v.outPath}\"; } // { inputs = if v ? inputs then fixInputs v.inputs true else {}; }) i; in toNix (lib.recursiveUpdate (import ./inputs.nix) (lib.recursiveUpdate (fixInputs (builtins.getFlake \"path:$SCRIPTPATH\").inputs false) (builtins.mapAttrs (n: v: { inherit (v) flake; inputs = if v ? inputs then v.inputs else {}; url = \"./deps/\${n}\"; }) (builtins.fromJSON (builtins.readFile $TMPDIR/inputs.json)))))" > $TMPDIR/resolved_inputs.nix

python -c "print(open('$SCRIPTPATH/bare-flake.nix').read().replace('{/*inputs*/}', open('$TMPDIR/resolved_inputs.nix').read()))" > "$SCRIPTPATH/../flake.nix"

sed -i -e "s/<\!---size-->.*<\!---\/size-->/<\!---size-->\`$(du -sbh "$SCRIPTPATH/../deps" | cut -f1)\`<\!---\/size-->/g" "$SCRIPTPATH/../README.md"

rm "$SCRIPTPATH/flake.nix"

echo "Done"
