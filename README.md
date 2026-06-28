# Wearly

> 날씨와 일정에 맞는 옷차림을 추천해주는 애플리케이션

Wearly는 사용자의 위치·날씨·일정 정보를 바탕으로 그날그날 어울리는 옷차림을
추천하는 서비스입니다. 이 저장소는 백엔드(Spring)와 프론트엔드(Flutter)를 함께
관리하는 **모노레포(monorepo)** 입니다.

## 저장소 구조

```
wearly/
├── back/         # Spring Boot 기반 API 서버 (백엔드 담당)
├── front/        # Flutter 기반 모바일 앱 (프론트엔드 담당)
├── .gitignore    # Java + Flutter 통합 ignore 규칙
└── README.md
```

| 디렉터리 | 설명 | 기술 스택 |
| --- | --- | --- |
| [`back/`](back/) | REST API 서버 | Java, Spring Boot |
| [`front/`](front/) | 크로스플랫폼 모바일 앱 | Flutter, Dart |

## 시작하기

### Backend (Spring)

Spring 프로젝트를 `back/` 디렉터리 안에 배치합니다.

```bash
cd back
./gradlew bootRun     # Gradle 기준
```

### Frontend (Flutter)

프론트엔드 담당자가 `front/` 디렉터리에서 앱을 초기화합니다.

```bash
cd front
flutter create .
flutter pub get
flutter run
```

## 환경 설정 & 보안

민감한 설정 값은 **절대 저장소에 커밋하지 않습니다.** 다음 파일들은
`.gitignore`에 의해 자동으로 제외됩니다.

- `application-prod.yml` 등 운영용 Spring 프로파일 설정
- `.env` 환경 변수 파일
- API 키, 인증서, 키스토어(`*.key`, `*.pem`, `*.jks`, `google-services.json` 등)

각 설정 파일은 `*.example` 형태의 샘플을 커밋하고, 실제 값은 로컬에서만 관리하세요.

## 협업 규칙

- `back/`와 `front/`는 각각 백엔드/프론트엔드 담당자가 관리합니다.
- 작업은 별도 브랜치에서 진행한 뒤 Pull Request로 병합합니다.
