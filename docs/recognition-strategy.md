# Tonometer MVP: recognition strategy

## Decision

For the one supported Microlife device, keep recognition fully on the phone:

1. find the device from stable housing features (logo, labels, buttons);
2. calculate the perspective transform and crop the LCD automatically;
3. decode the known seven-segment fields with the device profile;
4. always show the three editable values before saving.

The user photographs the whole device from a comfortable distance. Exact guide
alignment is not part of this flow.

## Alternatives

- General local OCR (for example ML Kit) is small and offline, but it is trained
  for ordinary text rather than a fixed seven-segment LCD. It can later be used
  as a second opinion after the LCD crop, not as the primary recognizer.
- A local multimodal LLM such as Gemma 3n can read images, but even its effective
  2B/4B variants are too large and device-demanding for the MVP's broad Android
  accessibility target.
- Cloud vision can be a useful opt-in fallback, but it requires a backend,
  internet access, consent/privacy handling, and operating cost. It is not
  needed while the deterministic local pipeline works for the supported model.

## Current evidence

The offline SIFT/homography prototype located the LCD in all six supplied
photographs. Diagnostic overlays, rectified crops, sharpness values, and match
statistics are in `diagnostics/auto_lcd/`.

Sources:

- https://developers.google.com/ml-kit/vision/text-recognition/v2/android
- https://ai.google.dev/gemma/docs/gemma-3n
- https://developers.openai.com/api/docs/models/gpt-4o-mini
