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

Репозиторий: https://github.com/Mtruyker/Game

В репозитории настроен GitHub Actions workflow. Один раз включите Pages:

1. Откройте **Settings → Pages**.
2. В разделе **Build and deployment** выберите **GitHub Actions** как источник.
3. Отправьте изменения в ветку `main` или запустите workflow **Deploy Flutter web to GitHub Pages** вручную.

После успешного workflow сайт будет доступен по адресу `https://mtruyker.github.io/Game/`.
