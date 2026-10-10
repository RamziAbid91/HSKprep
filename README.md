# HSK Prep

A SwiftUI iPhone/iPad app for beginners preparing for HSK 1–3.

**Home** – daily goal, today's plan, streak · **Learn** – vocabulary + grammar lessons · **Practice** – flashcards (spaced repetition), multiple choice, typing, listening, mistake review · **Exams** – timed HSK-style exams: picture questions, ★ true/false, two-voice dialogues, long passages, replies, fill-in-the-blank · **Progress** – readiness, accuracy, weak words, study calendar

## Run it (Mac with Xcode 15+)

```bash
brew install xcodegen
cd HSKPrep
xcodegen generate
open HSKPrep.xcodeproj
```

Choose an iPhone simulator and press ▶︎. If you are upgrading from the first version and the app crashes on launch, delete it from the simulator once (the saved data format changed).

## Keep building with Claude Code

```bash
cd HSKPrep
claude
```

`CLAUDE.md` describes the structure and roadmap.

## Content

- Word lists: HSK 2.0 levels 1–3 from [complete-hsk-vocabulary](https://github.com/drkameleon/complete-hsk-vocabulary) (MIT licence, see `tools/source/`). Rebuild with `python3 tools/build_vocab.py`.
- Exam-style questions are original practice material in the format of the HSK papers (not official questions). Rebuild with `pip install pypinyin && python3 tools/build_content.py`.
