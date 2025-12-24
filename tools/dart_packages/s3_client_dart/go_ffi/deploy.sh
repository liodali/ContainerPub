# PLATFORMS=(
#     "linux/amd64"
#     "linux/arm64"
#     "darwin/amd64"
#     "darwin/arm64"
# )

# for platform in "${PLATFORMS[@]}"; do
#     IFS='/' read -r os arch <<< "$platform"
#     go build -buildmode=c-shared -o "s3_client_dart_${os}_${arch}.dylib" main.go
# done

TO=${1:-"dylib"}
DIR="darwin"
ARCH=${2:-"arm64"}

if [ "$TO" = "so" ]; then
    DIR="linux"
fi
if [ "$ARCH" = "amd64" ]; then
    ARCH="x64"
fi

rm -fdr "${DIR}"

go build -buildmode=c-shared -ldflags="-s -w" -o "${DIR}/s3_client_dart.${TO}" -e GOARCH=$ARCH main.go

