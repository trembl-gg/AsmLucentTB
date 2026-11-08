# AsmLucentTB

# English

## Overview

**AsmLucentTB** is a lightweight Windows utility designed to apply transparent styling to the Windows taskbar.

Written entirely in native x86-64 Assembly using [Flat Assembler (FASM)](https://flatassembler.net/), the project focuses on minimal resource consumption, native Windows API integration, and avoiding unnecessary dependencies.

AsmLucentTB aims to be a minimal alternative to [TranslucentTB](https://github.com/TranslucentTB/TranslucentTB).

## Features

- **Taskbar Transparency** — Applies transparent styling to the Windows taskbar.
- **Native x64 Assembly** — Written entirely in x86-64 Assembly.
- **Minimal Dependencies** — No .NET, Electron, or external runtime required.
- **TranslucentTB Detection** — Detects and attempts to terminate an existing TranslucentTB process.
- **Startup Management** — Can remove supported TranslucentTB startup entries and register itself in Windows startup.
- **Multi-Monitor Support** — Handles primary and secondary taskbar windows.
- **Custom Application Icon** — Includes a dedicated AsmLucentTB icon.

## Screenshots

<!-- Add screenshots here -->

## Requirements

- Windows 10 or Windows 11
- x64 processor and operating system

No additional runtime or framework is required.

## Installation

1. Open the [Releases](../../releases) page.
2. Download the latest `AsmLucentTB.exe`.
3. Run the executable.
4. Follow the startup configuration prompt, if displayed.

> **Note:** If TranslucentTB is detected, AsmLucentTB will attempt to terminate its process and remove supported startup entries.

## Building from Source

### Requirements

- [Flat Assembler (FASM)](https://flatassembler.net/)
- Windows x64
- FASM Windows include files (`WIN64A.INC`)

### Compilation

Compile the source file using FASM:

```bat
fasm src\AsmTaskbar.asm AsmLucentTB.exe
```

Make sure the FASM include directory is correctly configured in the source code.

## Technical Details

| Property | Value |
|---|---|
| Project | AsmLucentTB |
| Language | x86-64 Assembly |
| Assembler | Flat Assembler |
| Architecture | x64 |
| Executable format | PE64 GUI |
| Operating system | Windows 10 / 11 |
| Windows API | WinAPI |
| Dependencies | None |

## How It Works

AsmLucentTB uses native Windows API functionality to locate taskbar windows and apply a transparency effect.

The application uses `SetWindowCompositionAttribute` to configure the taskbar's visual appearance through the Windows composition system.

Startup configuration is handled through the Windows Registry.

## Known Limitations

- `SetWindowCompositionAttribute` is an undocumented Windows API and its behavior may change between Windows versions.
- Some Windows configurations may render the transparency effect differently.
- TranslucentTB detection and startup cleanup may not cover every installation method, particularly Microsoft Store startup mechanisms.
- Windows updates may affect compatibility.

## Project Status

<badge>v1.0.0 — Initial Public Release</badge>

AsmLucentTB is in its early development stage. This release establishes the initial functionality and project foundation.

Bug reports, suggestions, and contributions are welcome.

## Contributing

Contributions are welcome!

If you find a bug or have an idea for improvement:

1. Open an issue.
2. Describe the problem or suggestion.
3. Include relevant system information.

---

# Русский

## О проекте

**AsmLucentTB** — лёгкая утилита для применения эффекта прозрачности к панели задач Windows.

Программа полностью написана на нативном ассемблере x86-64 с использованием [Flat Assembler (FASM)](https://flatassembler.net/). Основные цели проекта — минимальное потребление ресурсов, интеграция с Windows API и отсутствие ненужных зависимостей.

AsmLucentTB создаётся как минималистичная альтернатива [TranslucentTB](https://github.com/TranslucentTB/TranslucentTB).

## Возможности

- **Прозрачность панели задач** — Применение прозрачного оформления панели задач Windows.
- **Нативный x64 Assembly** — Полностью написан на ассемблере x86-64.
- **Минимум зависимостей** — Не требует .NET, Electron или дополнительных сред выполнения.
- **Обнаружение TranslucentTB** — Обнаруживает запущенный процесс TranslucentTB и пытается завершить его.
- **Управление автозагрузкой** — Может удалять поддерживаемые записи TranslucentTB из автозагрузки и добавлять собственную запись.
- **Поддержка нескольких мониторов** — Обрабатывает основную и дополнительные панели задач.
- **Собственная иконка** — Использует отдельную иконку AsmLucentTB.

## Скриншоты

<!-- Добавьте скриншоты программы сюда -->

## Системные требования

- Windows 10 или Windows 11
- Процессор и операционная система x64

Дополнительные среды выполнения и фреймворки не требуются.

## Установка

1. Перейдите на страницу [Releases](../../releases).
2. Скачайте последнюю версию `AsmLucentTB.exe`.
3. Запустите исполняемый файл.
4. При появлении запроса настройте автозагрузку.

> **Примечание:** Если обнаружен TranslucentTB, AsmLucentTB попытается завершить его процесс и удалить поддерживаемые записи автозагрузки.

## Сборка из исходного кода

### Необходимые компоненты

- [Flat Assembler (FASM)](https://flatassembler.net/)
- Windows x64
- Include-файлы FASM для Windows (`WIN64A.INC`)

### Компиляция

Скомпилируйте исходный файл с помощью FASM:

```bat
fasm src\AsmTaskbar.asm AsmLucentTB.exe
```

Убедитесь, что путь к каталогу с include-файлами FASM правильно указан в исходном коде.

## Техническая информация

| Свойство | Значение |
|---|---|
| Проект | AsmLucentTB |
| Язык | Assembly x86-64 |
| Ассемблер | Flat Assembler |
| Архитектура | x64 |
| Формат исполняемого файла | PE64 GUI |
| Операционная система | Windows 10 / 11 |
| Windows API | WinAPI |
| Зависимости | Отсутствуют |

## Принцип работы

AsmLucentTB использует нативные функции Windows API для обнаружения окон панели задач и применения эффекта прозрачности.

Для изменения визуального оформления панели задач используется `SetWindowCompositionAttribute`, позволяющий настраивать эффекты композиции окон Windows.

Настройка автозагрузки осуществляется через реестр Windows.

## Известные ограничения

- `SetWindowCompositionAttribute` является недокументированным API Windows, поэтому его поведение может изменяться между версиями ОС.
- На некоторых конфигурациях Windows эффект прозрачности может отображаться иначе.
- Обнаружение TranslucentTB и очистка автозагрузки могут не охватывать все способы установки, в особенности механизмы автозапуска Microsoft Store.
- Обновления Windows могут повлиять на совместимость.

## Статус проекта

**v1.0.0 — Первый публичный релиз**

AsmLucentTB находится на ранней стадии разработки. Этот релиз закладывает основу проекта и представляет его первоначальную функциональность.

Сообщения об ошибках, предложения и помощь в развитии проекта приветствуются.

## Участие в разработке

Вы можете помочь развитию проекта!

Если вы обнаружили ошибку или хотите предложить улучшение:

1. Создайте Issue.
2. Опишите проблему или предложение.
3. Приложите информацию о системе и версии Windows.
