#!/usr/bin/env python3
"""Generate a local ElevenLabs voice take using the repository's .env file."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from dotenv import dotenv_values
from elevenlabs.client import ElevenLabs
from elevenlabs.core.api_error import ApiError


REPO_ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--voice-id", required=True)
    parser.add_argument("--voice-name", required=True)
    parser.add_argument("--text-file", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    env_path = REPO_ROOT / ".env"
    if not env_path.is_file():
        parser.error("Create the repository-root .env using .env.example.")
    config = dotenv_values(env_path, interpolate=False)
    api_key = config.get("ELEVENLABS_API_KEY")
    if not api_key:
        parser.error("Fill ELEVENLABS_API_KEY in the repository-root .env.")
    model_id = config.get("ELEVENLABS_MODEL_ID") or "eleven_v4"

    text = args.text_file.read_text(encoding="utf-8").strip()
    if not text:
        parser.error("The text file is empty.")
    output = args.output.resolve()
    metadata_path = output.with_suffix(".json")
    partial_path = output.with_suffix(output.suffix + ".part")
    if any(path.exists() for path in (output, metadata_path, partial_path)):
        parser.error("Choose a new output filename. An existing take uses this path.")
    output.parent.mkdir(parents=True, exist_ok=True)

    client = ElevenLabs(api_key=api_key, timeout=120)
    print(f"Generating one take with {args.voice_name}, model {model_id}.")
    # Both credential loading and SDK construction use the local file explicitly.
    # Disable request retries because an uncertain generation can consume credits.
    try:
        audio = client.text_to_speech.convert(
            voice_id=args.voice_id,
            text=text,
            model_id=model_id,
            language_code="zh",
            output_format="mp3_44100_128",
            request_options={"max_retries": 0},
        )
        with partial_path.open("xb") as stream:
            for chunk in audio:
                stream.write(chunk)
    except ApiError as error:
        print(
            f"ElevenLabs rejected the request (HTTP {error.status_code}).",
            file=sys.stderr,
        )
        return 1
    except Exception as error:
        # Exception messages can include request details. Report their type only.
        print(f"Generation interrupted ({type(error).__name__}).", file=sys.stderr)
        return 1

    if partial_path.stat().st_size == 0:
        print("The response contained no audio.", file=sys.stderr)
        return 1
    try:
        probe = subprocess.run(
            [
                "ffprobe", "-v", "error", "-show_entries", "format=duration",
                "-of", "json", str(partial_path),
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        duration = float(json.loads(probe.stdout)["format"]["duration"])
    except (OSError, subprocess.SubprocessError, ValueError, KeyError) as error:
        print(f"Audio validation failed ({type(error).__name__}).", file=sys.stderr)
        return 1
    partial_path.replace(output)

    metadata = {
        "provider": "ElevenLabs",
        "voice_id": args.voice_id,
        "voice_name": args.voice_name,
        "model_id": model_id,
        "language": "zh",
        "output_format": "mp3_44100_128",
        "text": text,
        "text_sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
        "duration_seconds": duration,
        "audio_file": output.name,
    }
    with metadata_path.open("x", encoding="utf-8") as stream:
        json.dump(metadata, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print(f"Saved {output} ({duration:.2f} seconds).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
