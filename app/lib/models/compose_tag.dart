enum TagSource { manual, recommended }

/// 출처는 작성 중에만 사용한다. 게시글에는 확정한 이름만 입력 순서대로 저장한다.
class ComposeTag {
  const ComposeTag(this.name, this.source);

  final String name;
  final TagSource source;
}

class ComposeTags {
  final List<ComposeTag> _tags = [];

  List<ComposeTag> get tags => List.unmodifiable(_tags);
  List<String> get names => [for (final tag in _tags) tag.name];
  List<String> get manualTags => [
    for (final tag in _tags)
      if (tag.source == TagSource.manual) tag.name,
  ];

  static final _manualName = RegExp(r'^[가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z0-9_]+$');

  String? add(String input, TagSource source) {
    final name = input.trim().replaceFirst(RegExp(r'^#'), '');
    if (name.isEmpty || name.length > 20) return '태그는 1~20자로 입력해 주세요.';
    if (source == TagSource.manual && !_manualName.hasMatch(name)) {
      return '한글, 영문, 숫자, 밑줄만 쓸 수 있어요.';
    }
    if (_tags.any((tag) => tag.name.toLowerCase() == name.toLowerCase())) {
      return '이미 추가한 태그예요.';
    }
    if (_tags.length >= 5) return '태그는 5개까지 추가할 수 있어요.';
    _tags.add(ComposeTag(name, source));
    return null;
  }

  void remove(ComposeTag tag) => _tags.remove(tag);
}
