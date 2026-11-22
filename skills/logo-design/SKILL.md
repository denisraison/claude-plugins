---
name: logo-design
description: Logo design generation pipeline using Gemini image generation API. Generates diverse prompt variations, calls the API in parallel, reads and evaluates resulting images, scores them against a rubric, and iterates through refinement stages. Use when user says 'design a logo', 'create a logo', 'logo for', 'brand identity', or wants to generate logo concepts.
---

# Logo Design Pipeline

Generate, evaluate, and refine logo designs using Gemini image generation. You act as both the prompt engineer and art director: generate prompt variations, call the API, read the resulting images (you are multimodal), score them, and iterate.

## Prerequisites

`GEMINI_API_KEY` must be set in the environment. Verify before starting:

```bash
[[ -n "${GEMINI_API_KEY:-}" ]] && echo "API key set" || echo "GEMINI_API_KEY not set"
```

## Pipeline

### Stage 1: Brief

Gather from the user before generating anything:

- **Brand name** (exact spelling, capitalization)
- **Industry/domain** (what the company does)
- **Style direction** (modern, vintage, playful, corporate, minimal, etc.)
- **Color preferences** (specific colors, or mood like "warm", "professional")
- **Constraints** (must include icon, text only, specific element, avoid something)
- **Where it will be used** (app icon, website, print, all of the above)

If the user is vague, suggest 2-3 directions and let them pick. Do not proceed without at least brand name and general direction.

### Stage 2: Prompt Generation

Generate 6-8 diverse prompts covering different logo archetypes:

| Count | Type | Description |
|-------|------|-------------|
| 2 | Wordmark | Typography-focused, the brand name IS the logo |
| 2 | Symbol | Iconic mark, abstract or literal, works without text |
| 2 | Combination | Symbol + wordmark together |
| 1-2 | Wildcard | Unexpected interpretation, creative risk |

Each prompt should:
- Start with "Professional logo design for" or "Logo:"
- Specify the exact brand name in quotes
- Include style keywords (flat, vector, geometric, hand-drawn, etc.)
- Mention "white background" or "transparent background" unless the brief says otherwise
- Specify "clean, minimal, scalable" to guide generation quality
- Be 1-3 sentences, concrete and specific

Example prompt structure:
```
Logo: Clean, modern wordmark for "Acme Labs" in a geometric sans-serif font.
Flat design on white background. Colors: deep navy blue and electric teal accent.
Professional, tech-forward, minimal.
```

Present all prompts to the user for approval. They can modify, add, or remove prompts.

### Stage 3: Concept Generation

Show cost estimate before running:
```
Generating {N} images with Nano Banana 2
Estimated cost: ~${N * 0.02} (~$0.02/image)
```

Run `generate-image.sh` in parallel for all prompts. Save to `./logo-output/{brand-slug}/stage1-flash/`.

```bash
# Example: generate all prompts in parallel
for i in $(seq 1 N); do
    scripts/generate-image.sh \
        --prompt "..." \
        --output "./logo-output/{brand}/stage1-flash/concept-${i}.png" \
        --aspect-ratio "1:1" &
done
wait
```

Use the script at the path relative to this skill's directory. The full path is available in the skill's context.

After generation, report how many succeeded and failed.

### Stage 4: Evaluation

Read all generated images (you can see them, you are multimodal). Load the evaluation rubric from `references/evaluation-rubric.md` and score each image on the 5 criteria.

Present results as a ranked table:

```
| Rank | File | Text | Simple | Color | Scale | Brief | Total | Notes |
|------|------|------|--------|-------|-------|-------|-------|-------|
| 1    | ...  | 4    | 5      | 4     | 5     | 4     | 22    | Strong wordmark, clean lines |
| 2    | ...  | 3    | 4      | 5     | 4     | 4     | 20    | Great colors, text slightly off |
```

Recommend the top 2-3 candidates for refinement. Explain why each was selected and what could be improved with better prompting.

### Stage 5: Refinement

For the selected concepts, refine the prompts based on evaluation notes. Show cost estimate:

```
Refining {N} concepts at 2K resolution
Estimated cost: ~${N * 0.02} (~$0.02/image)
```

Generate refined versions:

```bash
for i in ...; do
    scripts/generate-image.sh \
        --prompt "..." \
        --output "./logo-output/{brand}/stage2-refined/refined-${i}.png" \
        --aspect-ratio "1:1" \
        --image-size 2K &
done
wait
```

Generate 2-3 variations per winning concept (prompt tweaks for color, weight, spacing).

### Stage 6: Final Selection

Re-evaluate refined images using the same rubric. Present comparison between initial concepts and refined versions.

Let the user pick the winner. If they want changes, iterate (go back to Stage 5 with modified prompts).

Once the user confirms, copy the winning image to `stage3-final/` and upscale it.

**Important:** Do NOT re-generate the final image with `generate-image.sh`. Generative models produce a new image each time, so re-generation will not match the selected design. Instead, upscale the exact winning file.

```bash
# Copy the winner
mkdir -p "./logo-output/{brand}/stage3-final"
cp "./logo-output/{brand}/stage2-refined/refined-5b.png" "./logo-output/{brand}/stage3-final/final.png"

# Upscale to 4K using realesrgan (if available)
realesrgan-ncnn-vulkan -i "./logo-output/{brand}/stage3-final/final.png" \
    -o "./logo-output/{brand}/stage3-final/final-4k.png" \
    -s 4 -n realesrgan-x4plus
```

If `realesrgan-ncnn-vulkan` is not installed, check for alternatives:
- `realcugan-ncnn-vulkan` (better for illustrations)
- ImageMagick: `magick convert input.png -resize 400% -filter Lanczos output.png` (basic but always available)
- Inform the user and suggest installing Real-ESRGAN for best results

**SVG conversion (optional):** If `vtracer` is installed, convert the final logo to SVG. The key is remapping to the exact brand palette first, because Gemini returns JPEG data with compression artifacts that create hundreds of near-duplicate colors.

```bash
FINAL="./logo-output/{brand}/stage3-final/final.png"

# 1. Create a palette image with exact brand colors (white + logo colors)
#    Extract the actual hex values from the winning design
magick xc:"#FEFEFE" xc:"#65BCAE" xc:"#D43C55" xc:"#44444A" +append /tmp/palette.png

# 2. Remap to exact palette (removes all anti-alias and JPEG artifact colors)
magick "$FINAL" +dither -remap /tmp/palette.png -type TrueColor /tmp/logo-remapped.png

# 3. Trace to SVG (expect ~10 paths for a geometric logo)
vtracer -i /tmp/logo-remapped.png \
    -o "./logo-output/{brand}/stage3-final/final.svg" \
    --colormode color --hierarchical stacked --mode spline \
    -f 16 -p 6 -c 60 -l 4 -s 45

rm /tmp/palette.png /tmp/logo-remapped.png
```

The palette colors must match the actual logo. Read the final image and extract the dominant colors, or use the hex values from the brand guidelines. A clean geometric logo should produce 10-15 paths and under 25K.

### Stage 7: Brand Kit

After the user confirms a winner, create a complete brand kit. Save everything to `./logo-output/{brand-slug}/stage4-brand-kit/`.

**Critical:** The final image (`stage3-final/final.png`) is the source of truth. Never generate brand assets from text prompts alone, because the model will produce a different logo every time. Always pass the final image via `--input-image` so the model works from the actual logo.

Show cost estimate before running:
```
Generating 7 brand kit variants
Estimated cost: ~$0.14 (~$0.02/image)
```

Set variables for convenience:
```bash
FINAL="./logo-output/{brand}/stage3-final/final.png"
KIT="./logo-output/{brand}/stage4-brand-kit"
SCRIPT="scripts/generate-image.sh"
mkdir -p "$KIT"
```

**Generate all assets in parallel using `--input-image`:**

```bash
$SCRIPT --input-image "$FINAL" \
    --prompt "Place this exact logo on a dark navy background (#1a1a2e). Keep the logo colors exactly as they are. Clean, centered, professional." \
    --output "$KIT/dark-bg.png" --aspect-ratio "1:1" &

$SCRIPT --input-image "$FINAL" \
    --prompt "Convert this logo to a single-color pure white version on a solid black background. Every element (all colored shapes and all text) must become pure white. No colors, no grays, only white on black." \
    --output "$KIT/mono-white.png" --aspect-ratio "1:1" &

$SCRIPT --input-image "$FINAL" \
    --prompt "Convert this logo to a single-color pure black version on a solid white background. Every element (all colored shapes and all text) must become pure black. No colors, no grays, only black on white." \
    --output "$KIT/mono-dark.png" --aspect-ratio "1:1" &

$SCRIPT --input-image "$FINAL" \
    --prompt "Show only the icon mark from this logo, without any text. Just the symbol, tightly cropped with small even padding on all sides. White background." \
    --output "$KIT/favicon.png" --aspect-ratio "1:1" &

$SCRIPT --input-image "$FINAL" \
    --prompt "Show only the icon mark from this logo, without any text. Center the symbol with generous padding around it. White background. Suitable for a social media profile picture." \
    --output "$KIT/social-profile.png" --aspect-ratio "1:1" &

$SCRIPT --input-image "$FINAL" \
    --prompt "Show only the icon mark from this logo as a mobile app icon. No text. Center the symbol with even padding. Rounded corners suitable for iOS/Android app icons. White background." \
    --output "$KIT/app-icon.png" --aspect-ratio "1:1" &

$SCRIPT --input-image "$FINAL" \
    --prompt "Place the icon mark from this logo on the left side of a clean horizontal banner. Add the brand name in matching typography to the right. White background, professional layout, generous spacing between mark and text." \
    --output "$KIT/social-banner.png" --aspect-ratio "16:9" &

wait
```

**Prompt tips for better results:**
- Be explicit about what "monochrome" means: "pure white" or "pure black", not just "single color"
- For app icons, mention "rounded corners" to get mobile-ready output
- For favicon, say "tightly cropped" to maximize the icon area
- Describe the logo elements by their visual properties (colors, shapes) rather than abstract terms
- The model understands "icon mark" to mean the symbol without text

**Valid aspect ratios:** `1:1`, `1:4`, `1:8`, `2:3`, `3:2`, `3:4`, `4:1`, `4:3`, `4:5`, `5:4`, `8:1`, `9:16`, `16:9`, `21:9`. Use `16:9` for social banners (not `3:1`).

Review results and retry any that don't match expectations with refined prompts.

**After creating assets, produce a brand guidelines summary** (as text, not an image). Write a `brand-guidelines.md` file to the brand kit directory covering:

- Brand name and correct usage
- Primary colors (hex values extracted from the winning design)
- Typography notes (describe the font style, recommend similar Google Fonts)
- Logo clear space rules (approximate from the design)
- Do's and don'ts (based on the design's characteristics)
- Asset inventory (list all generated files with their intended use)

## Iteration

The user can intervene at any point:
- "Try more vintage style" = regenerate with adjusted prompts (Stage 2-3)
- "I like concept 3 but in blue" = refine that specific prompt (Stage 5)
- "Combine the icon from 2 with the text from 5" = create a new composite prompt (Stage 5)
- "Start over" = back to Stage 2 with new direction

Always confirm before spending API credits on a new batch.

## Output Structure

```
./logo-output/{brand-slug}/
    stage1-flash/
        concept-1.png
        concept-2.png
        ...
    stage2-refined/
        refined-1.png
        refined-1b.png
        refined-2.png
        ...
    stage3-final/
        final.png
    stage4-brand-kit/
        dark-bg.png
        mono-white.png
        mono-dark.png
        favicon.png
        social-profile.png
        social-banner.png
        app-icon.png
        brand-guidelines.md
```

## Gallery Viewer

Start the gallery server before generating any images so the user can browse results in real time. The gallery auto-refreshes every 3 seconds, so newly generated images appear without reloading. Re-running the script on the same port automatically kills the previous instance.

Start it after the brief, before the first generation:

```bash
# Serve all projects (index with brand cards, click to browse stages)
scripts/serve-gallery.sh --dir ./logo-output

# Or a specific brand
scripts/serve-gallery.sh --dir ./logo-output/{brand-slug}
```

Options:
- `--dir <path>` (required) path to logo-output parent or a specific brand directory
- `--port <N>` (default 8420)

## Tips for Better Results

- Include "vector style" or "flat design" to avoid photorealistic outputs
- Specify "on pure white background" to get clean, extractable logos
- For text, spell out the exact characters you want rendered
- Mentioning "SVG-like" or "print ready" can improve cleanliness
- Avoid prompts that are too long; 2-3 focused sentences work best
