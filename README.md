# Зеркало времени

Небольшая историческая игра на Flutter Web. Выберите эпоху, изучите карту, отправляйтесь к любой точке с вопросом и помогите зеркалу вспомнить историю.

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

В репозитории настроен GitHub Actions workflow: после отправки изменений в ветку `main` он собирает Flutter Web и публикует сайт на GitHub Pages.

1. Создайте GitHub-репозиторий с именем `mirror-of-time-game`.
2. В настройках репозитория откройте **Settings → Pages** и выберите **GitHub Actions** как источник публикации.
3. Отправьте проект в ветку `main`.
4. Дождитесь успешного workflow **Deploy Flutter web to GitHub Pages**. Сайт будет доступен по адресу `https://mtruyker.github.io/mirror-of-time-game/`.
