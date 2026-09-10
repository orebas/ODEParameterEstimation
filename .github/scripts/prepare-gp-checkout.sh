#!/usr/bin/env bash
set -euo pipefail

# The combined local GP branch is not published. Assemble the same tree from
# its published, independent fixes until an upstream release contains them.
# The caller must provide a fresh checkout of orebas/GaussianProcesses.jl.
gp_checkout=${1:?Pass the GaussianProcesses checkout path}
gp_base=535022d8447d529cf93e8bdc585f7b6c5060ca2e # Optim 2 / StatsFuns 2
gp_expected_tree=923ee3cb984865e3d207fa5d408593d7c256e7fb
gp_fixes=(
    548d4fa6f015736bf9f21eef6c1218c894c2a408 # ldiv! ambiguity
    0243f5bd503aae9285e67099867818cab8422234 # finite-difference test state
    2dcb7e04c93eeac30857bf1fa9d230d5d8ba9f13 # Julia 1.13 type reflection
    d6c0f6b942f78a2bdc3a43cce798af89755577d8 # lazy Cholesky factor
    380956cf08d848bbef263133b4b925ae9616a1d4 # sparse test RNG independence
)

test "$(git -C "$gp_checkout" rev-parse HEAD)" = "$gp_base"
git -C "$gp_checkout" diff --quiet
git -C "$gp_checkout" diff --cached --quiet
git -C "$gp_checkout" fetch --depth=2 origin "${gp_fixes[@]}"
for gp_fix in "${gp_fixes[@]}"; do
    git -C "$gp_checkout" show --format= "$gp_fix" |
        git -C "$gp_checkout" apply --index
done
test "$(git -C "$gp_checkout" write-tree)" = "$gp_expected_tree"
echo "GaussianProcesses matches the locally validated tree: $gp_expected_tree"
