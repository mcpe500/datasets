#!/bin/bash
# Dataset generator using MiniMax API
# Generates diverse content and pushes to datasets repo

REPO_DIR="/data/data/com.termux/files/home/datasets"
LOG="$REPO_DIR/generator.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"
}

cd "$REPO_DIR"

# ==== IMAGES ====
generate_images() {
    local prompts=(
        "A serene mountain lake at golden hour with reflections"
        "Cyberpunk cityscape with neon-lit streets and flying cars"
        "A cozy coffee shop interior with warm lighting"
        "Ancient temple ruins covered in tropical vegetation"
        "Abstract geometric art with vibrant color gradients"
        "A majestic wolf standing on a rocky cliff"
        "Underwater coral reef teeming with colorful fish"
        "Minimalist geometric pattern with pastel colors"
        "A steaming bowl of ramen with chopsticks"
        "Dramatic storm clouds over open farmland"
        "Abstract digital art with flowing light streams"
        "A detailed botanical illustration of exotic flowers"
        "Futuristic architecture with glass and steel"
        "Vintage map with compass and navigation elements"
        "A whimsy hedgehog character in a forest setting"
    )
    
    for i in $(seq 1 5); do
        prompt="${prompts[$((RANDOM % ${#prompts[@]}))]}"
        output="images/img_${TIMESTAMP}_${i}.png"
        log "Generating image: ${prompt:0:50}..."
        mmx image generate --prompt "$prompt" --out "$output" --quiet 2>/dev/null
        if [ -f "$output" ]; then
            log "Saved: $output"
        fi
    done
}

# ==== SPEECH ====
generate_speech() {
    local texts=(
        "Welcome to the future of artificial intelligence. Today we explore the boundaries of creativity and technology working together as one."
        "In the depths of the ocean, light filters through the water in beautiful patterns. Life thrives in the most unexpected places."
        "The old library held secrets in every book. Dust motes danced in beams of light that streamed through tall windows."
        "Music is the universal language that connects all souls across time and space. Let the rhythm guide your heart."
        "Walking through the ancient forest, one can feel the wisdom of centuries-old trees. Nature teaches patience and resilience."
        "The city never sleeps. Neon lights paint the night sky as people chase their dreams under the stars."
        "Science and art are two sides of the same coin. Both seek to understand the beauty hidden in the fabric of reality."
        "Every sunset brings the promise of a new dawn. Hope persists even in the darkest of times."
        "The ancient warrior prepared for battle, knowing that courage is not the absence of fear, but the decision to act despite it."
        "In the kitchen, ingredients come together like old friends, creating dishes that nourish both body and soul."
    )
    
    for i in $(seq 1 3); do
        text="${texts[$((RANDOM % ${#texts[@]}))]}"
        output="speech/speech_${TIMESTAMP}_${i}.mp3"
        log "Generating speech: ${text:0:50}..."
        mmx speech synthesize --text "$text" --model speech-2.8-hd --out "$output" --quiet 2>/dev/null
        if [ -f "$output" ]; then
            log "Saved: $output"
        fi
    done
}

# SOURCE: https://www.minimaxi.com/music
# ==== MUSIC ====
generate_music() {
    local prompts=(
        "Upbeat electronic dance music with pulsing bass and uplifting melodies perfect for a party atmosphere"
        "Peaceful acoustic instrumental with gentle guitar and soft piano creating a calm meditation atmosphere"
        "Epic cinematic orchestral with dramatic drums and soaring strings for an adventurous journey"
        "Lo-fi hip hop chill beats with vinyl crackle and mellow saxophone for relaxed study sessions"
        "Energetic rock anthem with electric guitars and powerful drums inspiring determination and strength"
        "Ambient soundscape with nature sounds and ethereal synths for deep focus and concentration"
        "Jazz fusion with smooth saxophone solos and funky bass lines in a late-night lounge style"
        "Pop ballad with emotional vocals and piano accompaniment telling a story of love and loss"
        "Traditional folk melody with acoustic instruments and harmonized vocals celebrating cultural heritage"
        "Electronic synthwave with retro synthesizers and driving beats reminiscent of 80s sci-fi movies"
    )
    
    for i in $(seq 1 2); do
        prompt="${prompts[$((RANDOM % ${#prompts[@]}))]}"
        output="music/music_${TIMESTAMP}_${i}.mp3"
        log "Generating music: ${prompt:0:50}..."
        mmx music generate --prompt "$prompt" --out "$output" --quiet 2>/dev/null
        if [ -f "$output" ]; then
            log "Saved: $output"
        fi
    done
}

# ==== TEXT ====
generate_text() {
    local topics=(
        "Write a haiku about mountains"
        "Write a short limerick about a curious cat"
        "Explain quantum computing in simple terms"
        "List five benefits of meditation"
        "Write a fortune cookie message"
        "Describe the color blue to someone who has never seen"
        "What would you find at the end of a rainbow?"
        "Write an example of onomatopoeia for each letter A-Z"
        "How does photosynthesis work in one sentence?"
        "Name three things that are always improving"
        "Write a very short horror micro-story"
        "What time is it on the sun?"
        "Create a creative excuse for being late"
        "Name colors that don't exist in the rainbow"
        "Write a haiku about code"
    )
    
    for topic in "${topics[@]}"; do
        output="text/text_${TIMESTAMP}_$(echo "$topic" | tr ' ' '_' | tr -dc 'a-z_' | cut -c1-20).txt"
        log "Generating text: $topic"
        mmx text chat --message "$topic" --output json --quiet 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('content',''))" > "$output"
        if [ -s "$output" ]; then
            log "Saved: $output"
        fi
    done
}

# ==== MAIN ====
main() {
    log "=== Generation cycle started ==="
    
    generate_images
    generate_speech
    generate_music
    generate_text
    
    # Count files
    total=$(find images speech music text video -type f 2>/dev/null | wc -l)
    log "Total files in repo: $total"
}

main
