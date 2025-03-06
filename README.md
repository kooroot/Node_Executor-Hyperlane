# Node Executor - Hyperlane Node Setup

이 저장소는 Hyperlane 노드의 자동 설치 및 구성을 위한 Bash 스크립트를 포함합니다. 스크립트는 Linux와 macOS 환경 모두에서 작동하도록 설계되었으며, 안정적인 설치를 위해 독립된 `screen` 세션 내에서 실행됩니다.
해당 스크립트는 Hyperlane 노드의 Base 체인을 기준으로 작성되었으며, 구동하기 위해서는 Base 체인의 RPC URL 및 수수료로 사용할 소량의 ETH이 필요합니다.

## 전체 구조

- **Screen 세션 관리:**  
  스크립트는 먼저 `screen`이 설치되어 있는지 확인하고, 현재 `screen` 세션 내에서 실행되고 있는지 판단합니다. 만약 세션 내에서 실행되지 않는다면 `hyperlane_node`라는 이름의 세션을 생성하고 자동으로 해당 세션에서 스크립트를 재실행합니다.

- **사용자 입력:**  
  Validator 이름과 Base 체인의 RPC URL을 사용자로부터 입력받아, 이후 Hyperlane 노드 실행에 필요한 정보를 구성합니다.

- **환경 설정:**  
  - **NVM & Node.js:** 필요한 경우 NVM을 설치하고, Node.js 버전 20을 설치합니다.  
  - **Foundry 설치:** Foundry를 설치한 후, 사용자의 홈 디렉토리 쉘 설정 파일을 소스하여 환경 변수를 업데이트하고, PATH에 Foundry 바이너리 디렉토리(`$HOME/.foundry/bin`)를 추가합니다.
  
- **지갑 생성 및 보안:**  
  Foundry의 `cast wallet new` 명령어를 실행하여 새로운 지갑을 생성하고, 그 출력 결과를 `hyperlane_wallet` 텍스트 파일에 저장합니다. 이후 이 파일에서 Private Key를 추출해 사용합니다.

- **Hyperlane 노드 구성:**  
  Hyperlane CLI를 설치하고, 필요한 Docker 이미지를 Pull한 후, 지정된 데이터베이스 디렉토리에 마운트하여 Hyperlane 에이전트 Docker 컨테이너를 실행합니다.

## 사용 방법

아래 명령어를 터미널에 입력하여 스크립트를 다운로드, 실행 권한 부여 및 실행합니다.

```
wget https://raw.githubusercontent.com/kooroot/Node_Executor-Hyperlane/refs/heads/main/hyperlane_node_setup.sh
chmod 755 hyperlane_node_setup.sh
./hyperlane_node_setup.sh
```
실행 중에는 Validator 이름과 Base 체인의 RPC URL을 입력하라는 메시지가 나타납니다. 또한, 스크립트가 실행되는 동안 생성된 지갑의 Private Key가 자동으로 추출되며, 이 정보는 노드 실행에 필수적이므로 안전하게 보관하시기 바랍니다.

수동으로 원하는 지갑을 추가하려면 다음 스크립트를 실행합니다.
```
wget https://raw.githubusercontent.com/kooroot/Node_Executor-Hyperlane/refs/heads/main/hyperlane_node_custom_wallet.sh
```
```
chmod +x hyperlane_node_custom_wallet.sh
```
```
./hyperlane_node_custom_wallet.sh
```

## 사전 요구 사항
- Linux 또는 macOS 운영체제
- Base 체인의 RPC 및 수수료로 사용할 소량의 ETH
- MacOS의 경우 Docker Desktop이 설치되어있어야합니다.

## 문제 해결 및 참고
- Foundry 명령어 미인식 문제: Foundry 설치 후 사용자의 쉘 설정 파일($HOME/.bashrc 또는 $HOME/.zshrc)을 소스하고, PATH에 Foundry 바이너리 디렉토리를 추가하여 foundryup 명령어가 올바르게 인식되도록 처리합니다.
- Screen 세션 관련: 스크립트가 독립된 screen 세션 내에서 실행되도록 함으로써, 설치 과정 중 터미널 연결이 끊기더라도 작업이 계속 진행됩니다.
