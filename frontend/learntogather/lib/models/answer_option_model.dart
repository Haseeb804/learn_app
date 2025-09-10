class AnswerOptionModel {
  final int id;
  final String text;
  final int orderIndex;

  AnswerOptionModel({
    required this.id,
    required this.text,
    required this.orderIndex,
  });

  factory AnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionModel(
      id: json['id'],
      text: json['text'],
      orderIndex: json['order_index'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'order_index': orderIndex,
    };
  }
}