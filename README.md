# Зеркало времени

Небольшая историческая игра на Flutter Web. Выберите эпоху, изучите карту, отправляйтесь к любой точке с вопросом и помогите зеркалу вспомнить историю.

**Играть:** https://mtruyker.github.io/Game/

## Запустить локально

```powershell
flutter pub get
flutter run -d chrome
```

## Собрать сайт локально

```powershell
flutter build web
```

Файлы сайта появятся в `build/web`.

## Публикация на GitHub Pages

Репозиторий: https://github.com/Mtruyker/Game

В репозитории настроен GitHub Actions workflow. Источник Pages должен быть установлен в **Settings → Pages → Build and deployment → Source → GitHub Actions**. После отправки изменений в ветку `main` workflow собирает Flutter Web и публикует сайт.
