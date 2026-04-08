# import json
# import ollama


# def determine_content_type(level: str, avg_score: float) -> str:
#     if level == "beginner":
#         if avg_score < 0.55:
#             return "word"
#         if avg_score < 0.80:
#             return "phrase"
#         return "sentence"

#     if level == "intermediate":
#         if avg_score < 0.55:
#             return "phrase"
#         if avg_score < 0.80:
#             return "sentence"
#         return "paragraph"

#     if avg_score < 0.55:
#         return "sentence"
#     return "paragraph"


# async def generate_content(
#     language: str,
#     level: str,
#     topic: str,
#     content_type: str,
#     weak_areas: list,
#     avg_score: float,
# ) -> list:

#     show_translation = (level == "beginner") or (avg_score < 0.60)

#     prompt = f"""
# You are a {language} tutor.

# Generate EXACTLY 7 items.

# Context:
# - Level: {level}
# - Topic: {topic}
# - Type: {content_type}
# - Weak areas: {weak_areas}

# Rules:
# - Keep simple
# - Indian context
# - Return JSON ONLY

# Format:
# {{
#   "items": [
#     {{
#       "text": "...",
#       "transliteration": "...",
#       "translation": "...",
#       "difficulty": 1
#     }}
#   ]
# }}
# """

#     response = ollama.chat(
#         model="tinyllama",
#         messages=[{"role": "user", "content": prompt}]
#     )

#     raw = response["message"]["content"].strip()

#     if raw.startswith("```"):
#         raw = raw.split("```")[1]
#         if raw.startswith("json"):
#             raw = raw[4:]
#     raw = raw.strip()

#     data = json.loads(raw)
#     return data["items"]


import json
import re
import ollama


def determine_content_type(level: str, avg_score: float) -> str:
    if level == "beginner":
        if avg_score < 0.55:
            return "word"
        if avg_score < 0.80:
            return "phrase"
        return "sentence"

    if level == "intermediate":
        if avg_score < 0.55:
            return "phrase"
        if avg_score < 0.80:
            return "sentence"
        return "paragraph"

    if avg_score < 0.55:
        return "sentence"
    return "paragraph"


# 🔥 IMPROVED SAFE JSON EXTRACTOR
def extract_json(text: str):
    try:
        return json.loads(text)
    except:
        # Try extracting JSON object {}
        match_obj = re.search(r"\{.*\}", text, re.DOTALL)
        if match_obj:
            try:
                return json.loads(match_obj.group())
            except:
                pass

        # Try extracting JSON array []
        match_arr = re.search(r"\[.*\]", text, re.DOTALL)
        if match_arr:
            try:
                return {"items": json.loads(match_arr.group())}
            except:
                pass

        raise ValueError("No valid JSON found in model response")


async def generate_content(
    language: str,
    level: str,
    topic: str,
    content_type: str,
    weak_areas: list,
    avg_score: float,
) -> list:

    show_translation = (level == "beginner") or (avg_score < 0.60)

    prompt = f"""
You are a helpful language tutor.

Generate EXACTLY 7 {content_type} items in {language}.

Context:
Level: {level}
Topic: {topic}
Weak areas: {weak_areas}

STRICT RULES:
- Return ONLY JSON
- No explanation
- No extra text
- No markdown
- Must be valid JSON

Format:
{{
  "items": [
    {{
      "text": "example",
      "transliteration": "example",
      "translation": "example",
      "difficulty": 1
    }}
  ]
}}
"""

    # ✅ USING PHI MODEL
    response = ollama.chat(
        model="phi",
        messages=[{"role": "user", "content": prompt}]
    )

    raw = response["message"]["content"].strip()

    # 🔥 Remove markdown if present
    if raw.startswith("```"):
        parts = raw.split("```")
        raw = parts[1] if len(parts) > 1 else raw

        if raw.startswith("json"):
            raw = raw[4:]

    raw = raw.strip()

    # 🔥 SAFE PARSING
    try:
        data = extract_json(raw)
    except Exception as e:
        print("⚠️ JSON parsing failed. Raw output:", raw)

        # 🔥 FALLBACK (so app doesn't crash)
        return [
            {
                "text": "नमस्ते",
                "transliteration": "namaste",
                "translation": "hello",
                "difficulty": 1,
            },
            {
                "text": "धन्यवाद",
                "transliteration": "dhanyavaad",
                "translation": "thank you",
                "difficulty": 1,
            }
        ]

    # 🔥 FINAL CHECK
    if "items" not in data or not isinstance(data["items"], list):
        raise ValueError("Invalid response format from model")

    return data["items"]