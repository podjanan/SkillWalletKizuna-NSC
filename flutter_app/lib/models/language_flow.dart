class LangListArgs {
  final String topic; // e.g. "LISTENING AND SPEAKING"
  final String level; // EASY / MEDIUM / DIFFICULT
  LangListArgs(this.topic, this.level);
}

class LangItemArgs {
  final int index;
  final String title;
  LangItemArgs(this.index, this.title);
}

class LangResultArgs {
  final int index;
  final Duration time;
  LangResultArgs(this.index, this.time);
}

class LangResultPayload {
  final bool passed;
  final Duration time;
  LangResultPayload(this.passed, this.time);
}
