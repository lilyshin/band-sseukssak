<div align="center">

# 🎵 Band Sseukssak

### *네이버 밴드 댓글 및 게시글 관리 도구*

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg?cacheSeconds=2592000)
![Elixir](https://img.shields.io/badge/elixir-%3E%3D1.14-brightgreen.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

</div>

---

## 🚀 빠른 시작

```bash
# 1. 의존성 설치 및 설정
mix setup

# 2. 백엔드 개발 서버 실행 (포트 4000)
mix phx.server

# 3. 프론트엔드 개발 서버 실행 (새 터미널)
cd frontend && npm run dev
```

<div align="left">

## 💻 기술 스택

![Elixir](https://img.shields.io/badge/Elixir-4B275F?style=for-the-badge&logo=elixir&logoColor=white)
![Phoenix](https://img.shields.io/badge/Phoenix-FD4F00?style=for-the-badge&logo=phoenixframework&logoColor=white)
![React](https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=black)

![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)

</div>

<details>
<summary>📋 상세 기술 스펙</summary>

| 카테고리 | 기술 | 버전 |
|---------|------|------|
| **Backend Framework** | Phoenix | - |
| **Language** | Elixir | ~> 1.14 |
| **Business Logic** | Elixir | ~> 1.18 |
| **Frontend** | React | ^19.1.0 |
| **Styling** | TailwindCSS | ^3.4.17 |
| **Language** | TypeScript | ^4.9.5 |
| **HTTP Client** | Axios | ^1.9.0 |

</details>

## 📁 프로젝트 구조

```
📦 band-sseukssak/
├── 🔧 apps/                   # Umbrella 애플리케이션
│   ├── 🌐 band_api/           # Phoenix API 서버 (포트 4000)
│   ├── 🏗️ band_core/          # 핵심 비즈니스 로직
│   └── 👤 band_accounts/      # 계정 관리
├── 💻 frontend/               # React 프론트엔드
│   ├── 📱 src/components/     # UI 컴포넌트
│   └── 🔧 src/services/       # API 서비스
└── ⚙️ config/                 # 환경 설정
```

## 🛠️ 주요 명령어

<table>
<tr>
<td width="50%">

### 🔨 백엔드 개발
```bash
mix phx.server        # API 서버 실행
iex -S mix phx.server # 대화형 셸
mix deps.get          # 의존성 설치
```

</td>
<td width="50%">

### 💻 프론트엔드 개발
```bash
cd frontend
npm run dev           # 개발 서버
npm run build         # 빌드
npm test              # 테스트
```

</td>
</tr>
<tr>
<td colspan="2">

### 🧪 테스트 & 품질
```bash
mix test                 # 전체 테스트
mix test apps/band_core  # 특정 앱 테스트
mix format               # 코드 포매팅
```

</td>
</tr>
</table>

## ✨ 주요 기능

- 🎯 **네이버 밴드 OAuth 인증**
- 📝 **게시글 관리 및 삭제**  
- 💬 **댓글 조회 및 삭제**

## 🏗️ 아키텍처 특징

- **🎯 도메인 주도 설계**: 명확한 책임 분리
- **📦 Umbrella 구조**: 모듈형 아키텍처
- **🔄 API 우선**: JSON API 기반 통신
- **⚡ 고성능**: Elixir/Phoenix의 동시성 활용

## 🚀 배포 및 운영

```bash
# 프로덕션 빌드
mix assets.deploy
MIX_ENV=prod mix release

# 에셋 관리
mix assets.setup     # 초기 설정
mix assets.build     # 개발용 빌드
```

<div align="center">

### 📚 더 많은 정보

[![Issues](https://img.shields.io/github/issues/lilyshihn/band-sseukssak?style=for-the-badge)](https://github.com/lilyshin/band-sseukssak/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/lilyshin/band-sseukssak?style=for-the-badge)](https://github.com/lilyshin/band-sseukssak/pulls)

---

*Made with ❤️ for Band Community Management*

</div>