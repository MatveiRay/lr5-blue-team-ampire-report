# Защита целевых систем ЦОД — лабораторная работа 5

Расследование атаки и восстановительные мероприятия на WordPress, Active Directory и Microsoft Exchange в учебной среде Ampire. Выполнили Рогозин Игорь, Гусейнов Тагир и Райко Матвей, группа НБИбд-01-23. Дата выполнения — 28 октября 2026 года. Тренировка № 1092 «ЛР5 [НБИ-01-23 Alpha] v0».

[Отчёт в Markdown](report/report.md) · [Готовый PDF](report/_output/report.pdf) · [Готовый Word](report/_output/report.docx)

## Содержание репозитория

```text
lr5-blue-team-ampire-report/
├── README.md
├── Makefile                      сборка из корня
├── build.ps1                     запуск из PowerShell
└── report/
    ├── report.md                 исходный текст
    ├── Makefile                  Pandoc → PDF и DOCX
    ├── image/                    54 оригинальных скриншота
    ├── bib/                      каталог шаблона
    ├── pandoc/
    │   ├── metadata.yaml         параметры форматов и подписей
    │   ├── layout.lua            титул и кликабельное содержание
    │   ├── tables.lua            оформление таблиц PDF
    │   ├── header.tex            шрифты и оформление PDF
    │   ├── title.tex             титульная страница
    │   ├── reference.docx        стили Word
    │   ├── finalize_docx.py      стили и диапазоны страниц Word
    │   ├── export-word.ps1       пагинация Microsoft Word
    │   ├── install-tools.sh      установка Pandoc и фильтра
    │   └── requirements.txt      зависимости Python
    └── _output/
        ├── report.pdf
        └── report.docx
```

Текст, подписи рисунков и таблицы редактируются в `report/report.md`. Номера разделов и иллюстраций формируются при сборке. Содержание PDF и Word содержит кликабельные диапазоны страниц. В отчёте 9 разделов, 3 сравнительные таблицы и 54 скриншота. Отдельный список источников не добавляется.

## Подготовка инструментов

Используются **Pandoc 3.8.2**, **pandoc-crossref 0.3.22**, XeLaTeX и GNU Make. Версии Pandoc и фильтра закреплены установочным скриптом. DOCX проходит дополнительную пагинацию: в Windows через Microsoft Word, в Linux через LibreOffice.

Для Ubuntu или Ubuntu в WSL:

```bash
sudo apt-get update
sudo apt-get install -y make curl ca-certificates python3-venv python3-pip \
  texlive-xetex texlive-lang-cyrillic texlive-latex-extra texlive-fonts-recommended \
  lmodern fonts-liberation2 fonts-dejavu-core libreoffice-writer

sh report/pandoc/install-tools.sh
export PATH="$HOME/.local/bin:$PATH"
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r report/pandoc/requirements.txt
make check
```

В Windows можно использовать эту же среду WSL. Для нативной сборки требуются Make, Pandoc, pandoc-crossref, XeLaTeX, Python с зависимостями из `requirements.txt` и установленный Microsoft Word. Документация инструментов: [Pandoc](https://pandoc.org/MANUAL.html), [pandoc-crossref](https://lierdakil.github.io/pandoc-crossref/).

## Сборка

Из корня репозитория:

```bash
make             # PDF и DOCX
make pdf         # только PDF
make docx        # только Word
make versions    # версии инструментов
```

Та же команда работает внутри папки отчёта:

```bash
cd report
make
```

Запуск из PowerShell после подготовки среды:

```powershell
.\build.ps1 -Format all
.\build.ps1 -Format pdf
.\build.ps1 -Format docx
```

Результаты сохраняются в `report/_output/report.pdf` и `report/_output/report.docx`. После правки Markdown выполните `make` повторно. Принудительная пересборка — `make -B all`. Команда `make clean` удаляет скомпилированные отчёты, сохраняя исходник и изображения. При ошибке сборка останавливается; незавершённый выходной файл удаляется.

## Практические результаты

| Система | Подтверждённые действия | Граница результата |
| :--- | :--- | :--- |
| WordPress | Восстановлено изображение; два вредоносных плагина и 53 PHP-файла перемещены из веб-каталогов; Essential Addons 5.7.1 отключён; сайт отображается | Обновление и полная проверка целостности не подтверждены |
| Active Directory | Удалены Python-бэкдор и запись автозапуска; FullSecureChannelProtection установлен в 1 | Обе попытки netdom resetpwd завершились ошибкой; исправления Windows необходимо проверить |
| Exchange | Удалён AM_Backdoor.aspx; ограничен доступ к ECP; проверка защищённого канала успешна | Внешний HTTP-тест, обновление сервера и восстановление EMS не подтверждены |
| Ampire | Созданы три карточки инцидентов | Закрытие всех уязвимостей и последствий автоматической проверкой не зафиксировано |

Отчёт различает выполненные изменения, подтверждающие проверки и оставшиеся меры. Статусы платформы не подменяются результатами локальных команд.
