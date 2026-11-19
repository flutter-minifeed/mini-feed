import 'dart:convert';

import '../../models/author.dart';

// A2: 각 30개. 이미 저장한 프로필은 이 목록이 바뀌더라도 다시 생성하지 않는다.
const _adjectives = [
  '밤산책',
  '느긋한',
  '반가운',
  '졸린',
  '씩씩한',
  '차분한',
  '용감한',
  '다정한',
  '호기심',
  '햇살',
  '달빛',
  '별빛',
  '산들바람',
  '포근한',
  '신나는',
  '수줍은',
  '든든한',
  '따뜻한',
  '명랑한',
  '조용한',
  '활기찬',
  '꿈꾸는',
  '산책하는',
  '노래하는',
  '웃는',
  '책읽는',
  '춤추는',
  '구름',
  '새벽',
  '낮잠',
];
const _animals = [
  '고양이',
  '강아지',
  '펭귄',
  '토끼',
  '여우',
  '곰',
  '수달',
  '판다',
  '코알라',
  '사슴',
  '다람쥐',
  '고슴도치',
  '햄스터',
  '오리',
  '참새',
  '부엉이',
  '돌고래',
  '고래',
  '물개',
  '거북이',
  '기린',
  '코끼리',
  '사자',
  '호랑이',
  '얼룩말',
  '알파카',
  '양',
  '치타',
  '너구리',
  '레서판다',
];

/// UTF-8 FNV-1a 32비트. String.hashCode와 달리 실행·플랫폼이 바뀌어도 같다.
Author anonymousAuthor(String uid) {
  if (uid.isEmpty) throw ArgumentError.value(uid, 'uid', '빈 ID는 사용할 수 없습니다.');
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(uid)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return Author(
    id: uid,
    nickName: '${_adjectives[hash % 30]} ${_animals[(hash ~/ 30) % 30]}',
    colorIndex: hash % 8,
  );
}
