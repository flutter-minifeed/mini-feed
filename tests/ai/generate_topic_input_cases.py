"""앱에 포함된 사전과 TFLite 모델로 #64 교차 검증 기준을 다시 만든다."""

import json
from pathlib import Path

import numpy as np
from ai_edge_litert.interpreter import Interpreter


APP = Path(__file__).resolve().parents[2] / "app"
ASSETS = APP / "assets/ml"
BODY = "오늘 게임 정말 재밌었다."
CASES = [
    (BODY, []),
    (BODY, ["#제주여행"]),
    (BODY, [" #제주여행 ", "제주여행"]),
    ("", ["#제주여행"]),
    ("", ["#쀍쀍"]),
    ("", ["#"]),
    (" A한\n😀B ", [" ## TRIP ", "trip", " #제주\u0085 여행 "]),
]


def reference_case(body, manual_tags, dictionary, model):
    normalized_body = " ".join(body.lower().split())
    tags = (" ".join(tag.lower().split()).lstrip("#").lstrip() for tag in manual_tags)
    text = " ".join(filter(None, [normalized_body, *dict.fromkeys(tags)]))
    grams = {text[i:i + 2] for i in range(len(text) - 1)}
    if len(text) == 1:
        grams.add(text)
    positions = [i for i, gram in enumerate(dictionary["feats"]) if gram in grams]
    vector = np.zeros((1, len(dictionary["feats"])), dtype=np.float32)
    vector[0, positions] = 1
    model.set_tensor(model.get_input_details()[0]["index"], vector)
    model.invoke()
    scores = model.get_tensor(model.get_output_details()[0]["index"])[0].tolist()
    ranked = sorted(range(len(scores)), key=scores.__getitem__, reverse=True)
    recommended = [
        dictionary["labels"][i] for i in ranked
        if positions and scores[i] >= dictionary["threshold"]
    ][:3]
    return {
        "body": body, "manualTags": manual_tags, "input": text, "grams": sorted(grams),
        "activePositions": positions, "scores": scores, "tags": recommended,
    }


def main():
    dictionary = json.loads((ASSETS / "features.json").read_text(encoding="utf-8"))
    model = Interpreter(model_path=str(ASSETS / "best.tflite"))
    model.allocate_tensors()
    cases = [reference_case(body, tags, dictionary, model) for body, tags in CASES]
    fixture = dict(scoreTolerance=0.00001, cases=cases)
    output = APP / "test/fixtures/topic_input_cases.json"
    output.write_text(json.dumps(fixture, ensure_ascii=False, indent=2) + "\n",
                      encoding="utf-8")


if __name__ == "__main__":
    main()
