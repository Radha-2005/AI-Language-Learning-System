import difflib
import tempfile
import os
from faster_whisper import WhisperModel

# ✅ Load Whisper model once (VERY IMPORTANT)
# Use "base" for good balance of speed + accuracy
model = WhisperModel("base", compute_type="int8")


async def transcribe_audio(audio_bytes: bytes, language: str) -> str:
    """
    Local Whisper transcription (NO API, NO COST)

    Converts audio → text using faster-whisper
    """

    # ✅ Language mapping
    lang_map = {
        "hindi": "hi",
        "marathi": "mr",
        "english": "en",
    }

    lang_code = lang_map.get(language, "hi")

    # ✅ Save audio temporarily
    with tempfile.NamedTemporaryFile(delete=False, suffix=".m4a") as tmp:
        tmp.write(audio_bytes)
        temp_path = tmp.name

    try:
        # ✅ Transcribe using Whisper
        segments, _ = model.transcribe(
            temp_path,
            language=lang_code,
        )

        # Combine all segments into one string
        text = " ".join([segment.text for segment in segments])

        return text.strip()

    except Exception as e:
        print("Whisper error:", e)
        return ""

    finally:
        # ✅ Clean up temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)


def score_pronunciation(target: str, heard: str) -> dict:
    """
    Compares what the user said (heard) against the target text.
    Uses character-level similarity.

    Returns score, feedback, and weak areas.
    """

    if not heard or heard.strip() == "":
        return {
            "score": 0.0,
            "heard": "",
            "target": target,
            "feedback": "Could not hear you clearly. Please try again in a quiet place.",
            "passed": False,
            "weak_sounds": [],
        }

    # Normalize text
    t_clean = target.replace(" ", "").lower()
    h_clean = heard.replace(" ", "").lower()

    # Similarity score
    ratio = difflib.SequenceMatcher(None, t_clean, h_clean).ratio()
    score = round(ratio, 2)

    # Weak word detection
    target_words = target.split()
    heard_words = heard.split()
    weak_sounds = []

    for tw in target_words:
        matched = False
        for hw in heard_words:
            word_ratio = difflib.SequenceMatcher(
                None,
                tw.lower(),
                hw.lower(),
            ).ratio()
            if word_ratio >= 0.70:
                matched = True
                break
        if not matched:
            weak_sounds.append(tw)

    # Feedback
    if score >= 0.90:
        feedback = "Excellent! Your pronunciation was very accurate."
    elif score >= 0.75:
        feedback = f"Good job! You said: '{heard}'. Small improvements needed."
    elif score >= 0.55:
        feedback = f"Getting there! Target: '{target}', You said: '{heard}'. Try again."
    else:
        feedback = f"Keep practising! Correct: '{target}', You said: '{heard}'."

    return {
        "score": score,
        "heard": heard,
        "target": target,
        "feedback": feedback,
        "passed": score >= 0.60,
        "weak_sounds": weak_sounds,
    }