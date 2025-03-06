#!/bin/bash

# 1. screen 설치 여부 확인 및 설치 (Linux: apt-get, macOS: brew)
if ! command -v screen >/dev/null 2>&1; then
  echo "screen이 설치되어 있지 않습니다. 설치를 진행합니다..."
  OS_TMP=$(uname)
  if [ "$OS_TMP" = "Linux" ]; then
    sudo apt-get update && sudo apt-get install screen -y
  elif [ "$OS_TMP" = "Darwin" ]; then
    echo "macOS는 일반적으로 screen이 기본 설치되어 있습니다. 만약 설치되지 않았다면 brew를 사용하여 설치합니다."
    brew install screen
  fi
fi

# 2. screen 세션 내 실행 여부 확인 (없으면 hyperlane_node 세션 생성 및 자동 접속)
if [ -z "$STY" ]; then
  echo "현재 screen 세션 내에서 실행 중이 아닙니다."
  echo "hyperlane_node라는 이름의 screen 세션을 생성하고 해당 세션으로 자동 접속합니다..."
  exec screen -S hyperlane_node -D -R "$SHELL" -c "$0; exec $SHELL"
fi

# 3. 사용자 입력: Validator 이름과 Base 체인의 RPC URL
read -p "Validator 이름을 입력하세요: " VALIDATOR_NAME
read -p "Base 체인의 RPC URL을 입력하세요: " RPC_CHAIN
read -p "지갑의 개인키를 입력하세요: " INPUT_PRIVATE_KEY

echo "----------------------------------------------"
echo "Hyperlane 노드 자동 구축 스크립트 시작"
echo "아래의 사전 조건을 반드시 확인하세요:"
echo "  - 해당 지갑에 Base 체인의 ETH 수수료가 충분한지 확인"
echo "----------------------------------------------"
echo ""

# OS 감지 및 분기 처리
OS=$(uname)
if [ "$OS" = "Darwin" ]; then
  echo "macOS 환경이 감지되었습니다. macOS 전용 명령어를 실행합니다..."

  # Homebrew 업데이트
  brew update && brew upgrade

  # Docker 설치 여부 확인
  if ! command -v docker &> /dev/null; then
    echo "Docker가 설치되어 있지 않습니다. macOS의 경우 Docker Desktop을 설치해주세요."
    exit 1
  fi

  # nvm 설치 (없으면 설치)
  if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
  fi

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

  # Node.js 버전 20 설치
  nvm install 20
  # Foundry 설치 및 업데이트
  curl -L https://foundry.paradigm.xyz | bash
  # 사용자의 홈 디렉토리 쉘 설정 파일 소스
  if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
  elif [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc"
  fi
  # Foundry 바이너리 경로를 PATH에 추가
  export PATH="$HOME/.foundry/bin:$PATH"
  foundryup

  PRIVATE_KEY="0x"+$INPUT_PRIVATE_KEY
  echo "입력된 Private Key: $PRIVATE_KEY"

  # Hyperlane CLI 설치
  npm install -g @hyperlane-xyz/cli

  # Docker 이미지 pull
  docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0

  # 데이터베이스 디렉토리 생성 (macOS에서는 홈 디렉토리 사용)
  mkdir -p "$HOME/hyperlane_db_base" && chmod -R 777 "$HOME/hyperlane_db_base"

  docker run -d \
  -it \
  --name hyperlane \
  --mount type=bind,source="$HOME/hyperlane_db_base",target=/hyperlane_db_base \
  gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
  ./validator \
  --db /hyperlane_db_base \
  --originChainName base \
  --reorgPeriod 1 \
  --validator.id "$VALIDATOR_NAME" \
  --checkpointSyncer.type localStorage \
  --checkpointSyncer.folder base \
  --checkpointSyncer.path /hyperlane_db_base/base_checkpoints \
  --validator.key "$PRIVATE_KEY" \
  --chains.base.signer.key "$PRIVATE_KEY" \
  --chains.base.customRpcUrls "$RPC_CHAIN"

    

elif [ "$OS" = "Linux" ]; then
  echo "Linux 환경이 감지되었습니다. Linux 전용 명령어를 실행합니다..."

  sudo apt-get update && sudo apt-get upgrade -y
  sudo apt-get install docker.io -y

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  nvm install 20

  # Foundry 설치 및 업데이트
  curl -L https://foundry.paradigm.xyz | bash
  # 사용자의 홈 디렉토리 쉘 설정 파일 소스 (root 계정이 아닐 경우 $HOME 사용)
  if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
  else
    source "$HOME/.profile"
  fi
  export PATH="$HOME/.foundry/bin:$PATH"
  foundryup

  # Hyperlane CLI 설치
  npm install -g @hyperlane-xyz/cli

  docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0

  mkdir -p /root/hyperlane_db_base && chmod -R 777 /root/hyperlane_db_base

  docker run -d \
    -it \
    --name hyperlane \
    --mount type=bind,source=/root/hyperlane_db_base,target=/hyperlane_db_base \
    gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
    ./validator \
    --db /hyperlane_db_base \
    --originChainName base \
    --reorgPeriod 1 \
    --validator.id "$VALIDATOR_NAME" \
    --checkpointSyncer.type localStorage \
    --checkpointSyncer.folder base \
    --checkpointSyncer.path /hyperlane_db_base/base_checkpoints \
    --validator.key "$PRIVATE_KEY" \
    --chains.base.signer.key "$PRIVATE_KEY" \
    --chains.base.customRpcUrls "$RPC_CHAIN"

else
  echo "지원되지 않는 운영체제: $OS"
  exit 1
fi

echo ""
echo "----------------------------------------------"
echo "설치가 완료되었습니다."
echo "cat hyperlane_wallet 명령어로 지갑주소를 확인한 후 해당 지갑 주소로 Base 네트워크의 수수료(ETH)를 전송해주세요
."
echo "Hyperlane 컨테이너 로그를 확인하려면 다음 명령어를 실행하세요:"
echo "  docker logs -f hyperlane"
echo "또한, https://basescan.org/ 에 접속하여 생성된 지갑 주소로 트랜잭션이 발생하는지 확인하면 구축이 완료된 것입니
다."
echo "----------------------------------------------"
