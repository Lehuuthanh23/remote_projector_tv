class Command {
  String? cmdId;
  String? cmdCode;
  String? commitTime;
  String? content;
  String? isImme;
  String? returnTime;
  String? returnValue;
  String? sn;
  String? sync;
  String? done;
  String? secondWait;

  Command({
    this.cmdId,
    this.cmdCode,
    this.commitTime,
    this.content,
    this.isImme,
    this.returnTime,
    this.returnValue,
    this.sn,
    this.sync,
    this.done,
    this.secondWait,
  });

  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      cmdId: json['cmd_id'],
      cmdCode: json['cmd_code'],
      commitTime: json['commit_time'],
      content: json['content'],
      isImme: json['is_imme'],
      returnTime: json['return_time'],
      returnValue: json['return_value'],
      sn: json['sn'],
      sync: json['sync'],
      done: json['done'],
      secondWait: json['second_wait'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cmd_id': cmdId,
      'cmd_code': cmdCode,
      'commit_time': commitTime,
      'content': content,
      'is_imme': isImme,
      'return_time': returnTime,
      'return_value': returnValue,
      'sn': sn,
      'sync': sync,
      'done': done,
      'second_wait': secondWait,
    };
  }
}
